terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.2.0"
    }
  }
}

provider "azurerm" {
  features {}

  # Provider registration is an explicit bootstrap operation. This prevents
  # Terraform from silently changing subscription-wide provider state.
  resource_provider_registrations = "none"
}

