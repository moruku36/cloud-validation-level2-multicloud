resource "google_compute_network" "main" {
  name                    = "${local.resource_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "backend" {
  name                     = "${local.resource_name}-backend"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_router" "main" {
  name    = "${local.resource_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "${local.resource_name}-nat"
  region                             = var.region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.backend.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "load_balancer_to_backend" {
  name      = "${local.resource_name}-allow-lb-http"
  network   = google_compute_network.main.name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]
  target_tags = [local.backend_network_tag]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "backend_web_egress" {
  name      = "${local.resource_name}-allow-web-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"
  priority  = 1000

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.backend_network_tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "backend_deny_other_egress" {
  name      = "${local.resource_name}-deny-other-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"
  priority  = 65534

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.backend_network_tag]

  deny {
    protocol = "all"
  }
}

resource "google_service_account" "vm_runtime" {
  account_id   = "${var.name_prefix}-${var.environment}-vm"
  display_name = "AI infrastructure validation VM runtime"
  description  = "Runtime identity with no project roles for the private Nginx VMs."
}

resource "google_service_account_iam_member" "github_apply_can_attach_vm_identity" {
  count = var.apply_service_account_email == null ? 0 : 1

  service_account_id = google_service_account.vm_runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.apply_service_account_email}"
}

resource "google_compute_health_check" "load_balancer" {
  name                = "${local.resource_name}-lb-hc"
  check_interval_sec  = 5
  timeout_sec         = 3
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/"
  }

  log_config {
    enable = true
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "${local.resource_name}-autoheal-hc"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_instance_template" "web" {
  name_prefix  = "${local.resource_name}-web-"
  machine_type = var.machine_type
  tags         = [local.backend_network_tag]
  labels       = local.common_labels

  can_ip_forward = false

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-amd64"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.backend.id
  }

  metadata = {
    block-project-ssh-keys = "true"
    enable-oslogin         = "true"
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    environment = var.environment
  })

  service_account {
    email  = google_service_account.vm_runtime.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name               = "${local.resource_name}-mig"
  base_instance_name = "${local.resource_name}-web"
  region             = var.region
  target_size        = var.target_size

  distribution_policy_zones = var.zones

  version {
    name              = "primary"
    instance_template = google_compute_instance_template.web.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 180
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    replacement_method             = "SUBSTITUTE"
    max_surge_fixed                = 2
    max_unavailable_fixed          = 0
  }
}

resource "google_compute_global_address" "web" {
  name = "${local.resource_name}-ip"
}

resource "google_compute_backend_service" "web" {
  name                  = "${local.resource_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.load_balancer.id]
  enable_cdn            = false

  backend {
    group           = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "web" {
  name            = "${local.resource_name}-url-map"
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_target_http_proxy" "web" {
  name    = "${local.resource_name}-http-proxy"
  url_map = google_compute_url_map.web.id
}

resource "google_compute_global_forwarding_rule" "web" {
  name                  = "${local.resource_name}-http"
  ip_address            = google_compute_global_address.web.id
  ip_protocol           = "TCP"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.web.id
}
