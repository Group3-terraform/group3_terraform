###############################
# Namespace
###############################
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

###############################
# ALB Controller IRSA IAM Role
###############################

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
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-${var.environment}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_policy_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::570430250751:policy/AWSLoadBalancerControllerIAMPolicy"
}

###############################
# ALB ServiceAccount
###############################

resource "kubernetes_service_account_v1" "alb_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

###############################
# Install AWS Load Balancer Controller
###############################

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.alb_sa.metadata[0].name
    }
  ]

  depends_on = [
    kubernetes_service_account_v1.alb_sa
  ]
}


###############################
# Ingress Resource
###############################

resource "kubernetes_ingress_v1" "apps_ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = "apps-ingress"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name

    annotations = {
      "kubernetes.io/ingress.class"              = "alb"
      "alb.ingress.kubernetes.io/scheme"         = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"    = "ip"
      "alb.ingress.kubernetes.io/listen-ports"   = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "api.dev.theareak.click"

      http {
        path {
          path     = "/a"
          path_type = "Prefix"

          backend {
            service {
              name = "service-a"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path     = "/b"
          path_type = "Prefix"

          backend {
            service {
              name = "service-b"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path     = "/c"
          path_type = "Prefix"

          backend {
            service {
              name = "service-c"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
