output "cloudwatch_namespace" {
  value = "${var.project_name}-${var.environment}"
}
