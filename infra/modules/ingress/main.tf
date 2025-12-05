#########################################
# Namespace: apps
#########################################
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

#########################################
# ALB Controller IAM Policy (download official JSON)
#########################################
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.project_name}-${var.environment}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_policy.response_body
}

#########################################
# IRSA Assume Role Policy
#########################################
data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

#########################################
# ALB IAM Role
#########################################
resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-${var.environment}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_policy_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

#########################################
# Kubernetes Service Account for ALB
#########################################
resource "kubernetes_service_account_v1" "alb_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

#########################################
# Install ALB Controller via Helm
#########################################
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.alb_sa.metadata[0].name
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    kubernetes_service_account_v1.alb_sa,
    aws_iam_role_policy_attachment.alb_policy_attach
  ]
}

#########################################
# Placeholder Services (service-a,b,c)
#########################################
resource "kubernetes_service_v1" "service_a" {
  metadata {
    name      = "service-a"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = "service-a"
    }
  }

  spec {
    selector = { app = "service-a" }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service_v1" "service_b" {
  metadata {
    name      = "service-b"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = "service-b"
    }
  }

  spec {
    selector = { app = "service-b" }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service_v1" "service_c" {
  metadata {
    name      = "service-c"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = "service-c"
    }
  }

  spec {
    selector = { app = "service-c" }

    port {
      port        = 80
      target_port = 80
    }
  }
}

#########################################
# Ingress Resource (HTTPS via ALB)
#########################################
resource "kubernetes_ingress_v1" "apps_ingress" {
  metadata {
    name      = "apps-ingress"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name

    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.ingress_hostname

      http {
        path {
          path      = "/a"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_a.metadata[0].name
              port { number = 80 }
            }
          }
        }

        path {
          path      = "/b"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_b.metadata[0].name
              port { number = 80 }
            }
          }
        }

        path {
          path      = "/c"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_c.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.alb_controller
  ]
}

#########################################
# Route53 Alias -> ALB Ingress
#########################################
data "aws_elb_hosted_zone_id" "main" {
  region = var.aws_region
}

resource "aws_route53_record" "apps_ingress_dns" {
  zone_id = var.route53_zone_id
  name    = var.ingress_hostname
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.apps_ingress.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = false
  }

  depends_on = [
    kubernetes_ingress_v1.apps_ingress
  ]
}
