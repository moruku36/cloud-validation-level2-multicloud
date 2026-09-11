resource "azurerm_public_ip" "application_gateway" {
  name                = "pip-${local.name_prefix}-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

resource "azurerm_application_gateway" "web" {
  name                = "agw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  zones               = ["1", "2", "3"]
  http2_enabled       = false
  tags                = local.common_tags

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = var.application_gateway_min_capacity
    max_capacity = var.application_gateway_max_capacity
  }

  gateway_ip_configuration {
    name      = local.application_gateway.gateway_ip_name
    subnet_id = azurerm_subnet.application_gateway.id
  }

  frontend_port {
    name = local.application_gateway.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.application_gateway.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.application_gateway.id
  }

  backend_address_pool {
    name = local.application_gateway.backend_pool_name
  }

  probe {
    name                = local.application_gateway.health_probe_name
    protocol            = "Http"
    host                = "127.0.0.1"
    path                = "/"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 3
    minimum_servers     = 0

    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                  = local.application_gateway.http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = local.application_gateway.health_probe_name
  }

  http_listener {
    name                           = local.application_gateway.http_listener_name
    frontend_ip_configuration_name = local.application_gateway.frontend_ip_name
    frontend_port_name             = local.application_gateway.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.application_gateway.routing_rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.application_gateway.http_listener_name
    backend_address_pool_name  = local.application_gateway.backend_pool_name
    backend_http_settings_name = local.application_gateway.http_settings_name
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.application_gateway,
  ]
}
