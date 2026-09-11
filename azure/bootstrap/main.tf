locals {
  name_prefix          = "aitev"
  storage_account_name = "staitev${var.storage_account_suffix}"

  common_tags = merge(var.tags, {
    Project    = "azure-ai-terraform-validation"
    ManagedBy  = "Terraform"
    Component  = "bootstrap"
    Validation = "AI-Infrastructure"
  })

  github_subject_repository = coalesce(var.github_subject_repository, var.github_repository)
}

data "azurerm_resource_group" "workload" {
  name = var.workload_resource_group_name
}

resource "azurerm_resource_group" "state" {
  name     = var.state_resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "state" {
  name                          = local.storage_account_name
  resource_group_name           = azurerm_resource_group.state.name
  location                      = azurerm_resource_group.state.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  public_network_access_enabled = true

  allow_nested_items_to_be_public  = false
  shared_access_key_enabled        = false
  default_to_oauth_authentication  = true
  local_user_enabled               = false
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days                     = var.soft_delete_retention_days
      permanent_delete_enabled = false
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "state" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "github_pr" {
  name                = "id-${local.name_prefix}-github-pr"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = local.common_tags
}

resource "azurerm_user_assigned_identity" "github_apply" {
  name                = "id-${local.name_prefix}-github-apply"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "github_pr" {
  name                      = "fic-${local.name_prefix}-github-pr"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_pr.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${local.github_subject_repository}:pull_request"
}

resource "azurerm_federated_identity_credential" "github_apply" {
  name                      = "fic-${local.name_prefix}-github-apply"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_apply.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${local.github_subject_repository}:environment:terraform-production"
}

resource "azurerm_role_assignment" "github_pr_workload_reader" {
  scope                = data.azurerm_resource_group.workload.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github_pr.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_apply_workload_contributor" {
  scope                = data.azurerm_resource_group.workload.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github_apply.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_pr_state_reader" {
  scope                = azurerm_storage_container.state.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.github_pr.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_apply_state_contributor" {
  scope                = azurerm_storage_container.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_apply.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "local_state_migration" {
  scope                = azurerm_storage_container.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"

  description = "Temporary local-user data-plane access for State migration and final cleanup."
}
