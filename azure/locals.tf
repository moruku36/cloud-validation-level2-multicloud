locals {
  name_prefix = "aitev-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Validation  = "AI-Infrastructure"
  })

  application_gateway = {
    backend_pool_name  = "${local.name_prefix}-backend-pool"
    frontend_ip_name   = "${local.name_prefix}-frontend-ip"
    frontend_port_name = "${local.name_prefix}-frontend-http"
    gateway_ip_name    = "${local.name_prefix}-gateway-ip"
    http_listener_name = "${local.name_prefix}-http-listener"
    http_settings_name = "${local.name_prefix}-http-settings"
    health_probe_name  = "${local.name_prefix}-health-probe"
    routing_rule_name  = "${local.name_prefix}-routing-rule"
  }
}

