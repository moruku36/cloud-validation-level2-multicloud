output "state_bucket_name" {
  value       = google_storage_bucket.terraform_state.name
  description = "Dedicated GCS State bucket. Store the real value as a GitHub Secret."
  sensitive   = true
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "WIF provider resource name. Store the real value as a GitHub Secret."
  sensitive   = true
}

output "github_pr_service_account" {
  value       = google_service_account.github_pr.email
  description = "PR plan service account. Store the real value as a GitHub Secret."
  sensitive   = true
}

output "github_apply_service_account" {
  value       = google_service_account.github_apply.email
  description = "Protected apply service account. Store the real value as a GitHub Secret."
  sensitive   = true
}
