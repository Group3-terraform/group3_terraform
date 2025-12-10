terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }
}

##################################
# Local variable: Dynamic ALB Name
##################################
locals {
  alb_name = "${var.project_name}-${var.environment}-alb"
}

##############################
# Namespace for microservices
##############################
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

###############################################
# ALB Controller Service Account (IRSA enabled)
###############################################
resource "kubernetes_service_account_v1" "alb_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_role_arn
    }
  }
}

###############################################
# Install AWS Load Balancer Controller (Helm)
###############################################
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.alb_sa.metadata[0].name
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
    kubernetes_service_account_v1.alb_sa
  ]
}

#########################
# Services (a, b, c)
#########################
resource "kubernetes_service_v1" "a" {
  metadata {
    name      = "service-a"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "service-a"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service_v1" "b" {
  metadata {
    name      = "service-b"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "service-b"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service_v1" "c" {
  metadata {
    name      = "service-c"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "service-c"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

##############################
# ALB Ingress
##############################
resource "kubernetes_ingress_v1" "apps_ingress" {
  metadata {
    name      = "apps-ingress"
    namespace = "apps"

    annotations = {
      # Ingress Class (required for ALB)
      "kubernetes.io/ingress.class" = "alb"

      # ALB settings
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn

      # ALB name
      "alb.ingress.kubernetes.io/load-balancer-name" = local.alb_name

      # (Optional but recommended)
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/a/health"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.ingress_hostname

      http {
        # SERVICE A (FastAPI) /a → service-a
        path {
          path      = "/a"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.a.metadata[0].name
              port { number = 80 }
            }
          }
        }

        # SERVICE B
        path {
          path      = "/b"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.b.metadata[0].name
              port { number = 80 }
            }
          }
        }

        # SERVICE C
        path {
          path      = "/c"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.c.metadata[0].name
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
