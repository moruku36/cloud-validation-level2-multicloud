locals {
  resource_name  = "${var.name_prefix}-${var.environment}"
  role_id_prefix = replace(local.resource_name, "-", "_")

  repository    = "${var.github_owner}/${var.github_repository}"
  pr_subject    = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:pull_request"
  apply_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:environment:${var.github_environment}"

  common_labels = merge({
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "ai-infrastructure-validation"
  }, var.labels)
}
