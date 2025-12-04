#########################################
# Namespace
#########################################
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

#########################################
# ServiceAccount for ALB Controller
#########################################
resource "kubernetes_service_account_v1" "alb_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_role_arn
    }
  }
}

#########################################
# Install AWS Load Balancer Controller
#########################################
resource "helm_release" "alb" {
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

  depends_on = [kubernetes_service_account_v1.alb_sa]
}

#########################################
# Services A/B/C
#########################################

resource "kubernetes_service_v1" "service_a" {
  metadata {
    name      = "service-a"
    namespace = "apps"
  }
  spec {
    selector = { app = "service-a" }
    port { port = 80 target_port = 80 }
  }
}

resource "kubernetes_service_v1" "service_b" {
  metadata {
    name      = "service-b"
    namespace = "apps"
  }
  spec {
    selector = { app = "service-b" }
    port { port = 80 target_port = 80 }
  }
}

resource "kubernetes_service_v1" "service_c" {
  metadata {
    name      = "service-c"
    namespace = "apps"
  }
  spec {
    selector = { app = "service-c" }
    port { port = 80 target_port = 80 }
  }
}

#########################################
# Ingress
#########################################
resource "kubernetes_ingress_v1" "apps_ingress" {
  metadata {
    name      = "apps-ingress"
    namespace = "apps"

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
          backend { service { name = "service-a" port { number = 80 } } }
        }

        path {
          path      = "/b"
          path_type = "Prefix"
          backend { service { name = "service-b" port { number = 80 } } }
        }

        path {
          path      = "/c"
          path_type = "Prefix"
          backend { service { name = "service-c" port { number = 80 } } }
        }
      }
    }
  }

  depends_on = [helm_release.alb]
}
