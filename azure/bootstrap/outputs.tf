output "state_resource_group_name" {
  description = "Resource Group containing Remote State resources."
  value       = azurerm_resource_group.state.name
}

output "state_storage_account_name" {
  description = "Storage Account used by the root azurerm backend."
  value       = azurerm_storage_account.state.name
  sensitive   = true
}

output "state_container_name" {
  description = "Blob container used by the root azurerm backend."
  value       = azurerm_storage_container.state.name
}

output "state_key" {
  description = "Blob key used by the root azurerm backend."
  value       = var.state_key
}

output "github_pr_client_id" {
  description = "Client ID for the read-only Pull Request identity."
  value       = azurerm_user_assigned_identity.github_pr.client_id
  sensitive   = true
}

output "github_apply_client_id" {
  description = "Client ID for the production apply identity."
  value       = azurerm_user_assigned_identity.github_apply.client_id
  sensitive   = true
}

output "tenant_id" {
  description = "Tenant ID used by GitHub OIDC."
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}

output "subscription_id" {
  description = "Subscription ID used by GitHub OIDC."
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = true
}

