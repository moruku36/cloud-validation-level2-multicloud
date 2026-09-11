variable "location" {
  description = "Azure region for bootstrap resources."
  type        = string
  default     = "japaneast"
}

variable "workload_resource_group_name" {
  description = "Existing workload Resource Group managed by the root stack."
  type        = string
  default     = "rg-aitev-dev"
}

variable "state_resource_group_name" {
  description = "Resource Group dedicated to Terraform State and CI identities."
  type        = string
  default     = "rg-aitev-tfstate"
}

variable "storage_account_suffix" {
  description = "Lowercase alphanumeric suffix used to make the State Storage Account globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{8}$", var.storage_account_suffix))
    error_message = "storage_account_suffix must contain exactly eight lowercase letters or digits."
  }
}

variable "state_container_name" {
  description = "Private Blob container used by the azurerm backend."
  type        = string
  default     = "tfstate"
}

variable "state_key" {
  description = "Blob key used for the root Terraform State."
  type        = string
  default     = "terraform/azure-validation.tfstate"
}

variable "github_repository" {
  description = "GitHub repository in owner/repository form."
  type        = string
  default     = "moruku36/azure-ai-terraform-validation"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/repository format."
  }
}

variable "github_subject_repository" {
  description = "Repository component used in GitHub OIDC subjects. Set only when the organization customizes sub to include stable owner/repository IDs."
  type        = string
  default     = null

  validation {
    condition     = var.github_subject_repository == null || can(regex("^[A-Za-z0-9_.@-]+/[A-Za-z0-9_.@-]+$", var.github_subject_repository))
    error_message = "github_subject_repository must be null or an owner/repository subject component."
  }
}

variable "soft_delete_retention_days" {
  description = "Retention for deleted State blobs and containers."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags merged with bootstrap tags."
  type        = map(string)
  default     = {}
}
