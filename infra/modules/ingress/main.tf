terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}



# Namespace for our apps
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}

locals {
  full_domain = "${var.subdomain}.${var.domain}"
  services = [
    { name = "service-a"
        image = var.service_a_image 
    },
    { name = "service-b"
        image = var.service_b_image 
    },
    { name = "service-c"
        image = var.service_c_image 
    },
  ]
}

# Deployments for each service
resource "kubernetes_ingress_v1" "apps_ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = "apps-ingress"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name

    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "${var.subdomain}.${var.domain}"

      http {
        path {
          path      = "/a"
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
          path      = "/b"
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
          path      = "/c"
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
