resource "azurerm_monitor_action_group" "operations" {
  name                = "ag-${local.name_prefix}-operations"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "aitevops"
  tags                = local.common_tags
}

resource "azurerm_storage_account" "monitoring" {
  name                            = "st${replace(local.name_prefix, "-", "")}mon"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true
  tags                            = local.common_tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_management_policy" "monitoring" {
  storage_account_id = azurerm_storage_account.monitoring.id

  rule {
    name    = "delete-monitoring-logs-after-retention"
    enabled = true

    filters {
      prefix_match = ["insights-logs-"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.monitoring_log_retention_days
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name               = "diag-${local.name_prefix}-appgw"
  target_resource_id = azurerm_application_gateway.web.id
  storage_account_id = azurerm_storage_account.monitoring.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }
}

resource "azurerm_monitor_metric_alert" "web_unavailable" {
  name                = "alert-${local.name_prefix}-web-unavailable"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.web.id]
  description         = "No healthy backend remains behind Application Gateway."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "HealthyHostCount"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}

resource "azurerm_monitor_metric_alert" "backend_unhealthy" {
  name                = "alert-${local.name_prefix}-backend-unhealthy"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.web.id]
  description         = "One or more Application Gateway backends are unhealthy."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}

resource "azurerm_monitor_metric_alert" "http_5xx" {
  name                = "alert-${local.name_prefix}-http-5xx"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.web.id]
  description         = "Application Gateway returned more than the tolerated number of HTTP 5xx responses."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "ResponseStatus"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.http_5xx_threshold

    dimension {
      name     = "HttpStatusGroup"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}

resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  for_each = azurerm_linux_virtual_machine.web

  name                = "alert-${local.name_prefix}-${each.key}-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [each.value.id]
  description         = "Backend VM CPU usage remained above the configured threshold."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.vm_cpu_threshold_percent
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}

resource "azurerm_monitor_metric_alert" "vm_unavailable" {
  for_each = azurerm_linux_virtual_machine.web

  name                = "alert-${local.name_prefix}-${each.key}-unavailable"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [each.value.id]
  description         = "Backend VM availability dropped below healthy."
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}

resource "azurerm_monitor_activity_log_alert" "vm_deallocated" {
  name                = "alert-${local.name_prefix}-vm-deallocated"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  scopes              = [azurerm_resource_group.main.id]
  description         = "A backend VM was explicitly deallocated."
  tags                = local.common_tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Compute/virtualMachines/deallocate/action"
    resource_type  = "Microsoft.Compute/virtualMachines"
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations.id
  }
}
