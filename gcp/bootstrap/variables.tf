variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
  sensitive   = true
}

variable "state_bucket_name" {
  description = "Globally unique name for the dedicated Terraform State bucket."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region used for the State bucket."
  type        = string
  default     = "asia-northeast1"
}

variable "name_prefix" {
  description = "Prefix for bootstrap identities and IAM roles."
  type        = string
  default     = "ai-infra-validation"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "github_owner" {
  description = "Trusted GitHub repository owner."
  type        = string
  default     = "moruku36"
}

variable "github_owner_id" {
  description = "Stable numeric GitHub owner ID used in the repository OIDC subject."
  type        = string
  default     = "12478466"
}

variable "github_repository" {
  description = "Trusted GitHub repository name."
  type        = string
  default     = "gcp-ai-terraform-validation"
}

variable "github_repository_id" {
  description = "Stable numeric GitHub repository ID used in the repository OIDC subject."
  type        = string
  default     = "1359609296"
}

variable "github_environment" {
  description = "Protected GitHub Environment used by apply."
  type        = string
  default     = "terraform-production"
}

variable "labels" {
  description = "Additional labels for bootstrap resources."
  type        = map(string)
  default     = {}
}
