resource "google_project_iam_custom_role" "terraform_pr" {
  role_id     = "${local.role_id_prefix}_terraform_pr"
  title       = "AI validation Terraform PR reader"
  description = "Read-only permissions needed to refresh and plan the managed validation resources."
  stage       = "GA"

  permissions = [
    "compute.backendServices.get",
    "compute.backendServices.list",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.globalAddresses.get",
    "compute.globalAddresses.list",
    "compute.globalForwardingRules.get",
    "compute.globalForwardingRules.list",
    "compute.healthChecks.get",
    "compute.healthChecks.list",
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instances.get",
    "compute.instances.list",
    "compute.networks.get",
    "compute.networks.list",
    "compute.routers.get",
    "compute.routers.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.targetHttpProxies.get",
    "compute.targetHttpProxies.list",
    "compute.urlMaps.get",
    "compute.urlMaps.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.list",
    "logging.logMetrics.get",
    "logging.logMetrics.list",
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.list",
    "monitoring.uptimeCheckConfigs.get",
    "monitoring.uptimeCheckConfigs.list",
    "resourcemanager.projects.get",
    "serviceusage.services.get",
  ]
}

resource "google_project_iam_custom_role" "terraform_apply" {
  role_id     = "${local.role_id_prefix}_terraform_apply"
  title       = "AI validation Terraform apply manager"
  description = "CRUD permissions limited to the resource families managed by the validation root module."
  stage       = "GA"

  permissions = distinct(concat(tolist(google_project_iam_custom_role.terraform_pr.permissions), [
    "compute.backendServices.create",
    "compute.backendServices.delete",
    "compute.backendServices.update",
    "compute.backendServices.use",
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.update",
    "compute.globalAddresses.create",
    "compute.globalAddresses.delete",
    "compute.globalAddresses.use",
    "compute.globalForwardingRules.create",
    "compute.globalForwardingRules.delete",
    "compute.globalForwardingRules.update",
    "compute.healthChecks.create",
    "compute.healthChecks.delete",
    "compute.healthChecks.update",
    "compute.healthChecks.use",
    "compute.instanceGroupManagers.create",
    "compute.instanceGroupManagers.delete",
    "compute.instanceGroupManagers.update",
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.delete",
    "compute.instanceTemplates.useReadOnly",
    "compute.networks.create",
    "compute.networks.delete",
    "compute.routers.create",
    "compute.routers.delete",
    "compute.routers.update",
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.targetHttpProxies.create",
    "compute.targetHttpProxies.delete",
    "compute.targetHttpProxies.update",
    "compute.targetHttpProxies.use",
    "compute.urlMaps.create",
    "compute.urlMaps.delete",
    "compute.urlMaps.update",
    "compute.urlMaps.use",
    "logging.logMetrics.create",
    "logging.logMetrics.delete",
    "logging.logMetrics.update",
    "monitoring.alertPolicies.create",
    "monitoring.alertPolicies.delete",
    "monitoring.alertPolicies.update",
    "monitoring.uptimeCheckConfigs.create",
    "monitoring.uptimeCheckConfigs.delete",
    "monitoring.uptimeCheckConfigs.update",
    "serviceusage.services.use",
  ]))
}

resource "google_project_iam_member" "github_pr" {
  project = var.project_id
  role    = google_project_iam_custom_role.terraform_pr.id
  member  = "serviceAccount:${google_service_account.github_pr.email}"
}

resource "google_project_iam_member" "github_apply" {
  project = var.project_id
  role    = google_project_iam_custom_role.terraform_apply.id
  member  = "serviceAccount:${google_service_account.github_apply.email}"
}
