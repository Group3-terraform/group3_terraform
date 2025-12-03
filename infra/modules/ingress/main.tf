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
resource "kubernetes_deployment_v1" "api" {
  for_each = { for s in local.services : s.name => s }

  metadata {
    name      = each.key
    namespace = kubernetes_namespace_v1.apps.metadata[0].name
    labels = {
      app = each.key
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = each.key
      }
    }

    template {
      metadata {
        labels = {
          app = each.key
        }
      }

      spec {
        container {
          name  = each.key
          image = each.value.image

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 20
          }
        }
      }
    }
  }
}

# ClusterIP services
resource "kubernetes_service_v1" "api" {
  for_each = kubernetes_deployment_v1.api

  metadata {
    name      = each.key
    namespace = each.value.metadata[0].namespace
    labels = {
      app = each.key
    }
  }

  spec {
    selector = {
      app = each.key
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}
resource "kubernetes_ingress_v1" "apps_ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = "apps-ingress"
    namespace = kubernetes_namespace_v1.apps.metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = local.full_domain

      http {
        path {
          path = "/a"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_a.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path = "/b"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_b.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path = "/c"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.service_c.metadata[0].name
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

