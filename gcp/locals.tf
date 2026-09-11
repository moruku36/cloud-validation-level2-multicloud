locals {
  resource_name = "${var.name_prefix}-${var.environment}"

  common_labels = merge({
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "ai-infrastructure-validation"
  }, var.labels)

  backend_network_tag = "${local.resource_name}-backend"
}
