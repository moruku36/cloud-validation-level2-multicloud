resource "google_storage_bucket" "terraform_state" {
  name                        = var.state_bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
  labels                      = local.common_labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age        = 14
      with_state = "ARCHIVED"
    }

    action {
      type = "Delete"
    }
  }
}

resource "google_service_account" "github_pr" {
  account_id   = "${var.name_prefix}-${var.environment}-pr"
  display_name = "GitHub Terraform PR plan"
  description  = "Read-only Terraform plan identity federated from one GitHub repository."
}

resource "google_service_account" "github_apply" {
  account_id   = "${var.name_prefix}-${var.environment}-apply"
  display_name = "GitHub Terraform protected apply"
  description  = "Terraform apply identity federated from the protected GitHub Environment."
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "${var.name_prefix}-${var.environment}-github"
  display_name              = "GitHub Actions Terraform"
  description               = "Keyless GitHub OIDC federation for the validation repository."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub repository OIDC"
  description                        = "Accepts tokens only from the designated GitHub repository owner and repository."

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
    "attribute.event_name"       = "assertion.event_name"
  }

  attribute_condition = "assertion.repository_owner == '${var.github_owner}' && assertion.repository == '${local.repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_pr_federation" {
  service_account_id = google_service_account.github_pr.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/${local.pr_subject}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_service_account_iam_member" "github_apply_federation" {
  service_account_id = google_service_account.github_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/${local.apply_subject}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "github_pr_state" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.github_pr.email}"
}

resource "google_storage_bucket_iam_member" "github_apply_state" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_apply.email}"
}
