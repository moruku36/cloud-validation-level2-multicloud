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

  resource_provider_registrations = "none"
}

data "azurerm_client_config" "current" {}

