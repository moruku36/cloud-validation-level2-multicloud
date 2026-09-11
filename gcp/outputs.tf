output "application_url" {
  description = "Public HTTP endpoint of the global external Application Load Balancer."
  value       = "http://${google_compute_global_address.web.address}"
}

output "load_balancer_ip" {
  description = "Global external IP address. Do not copy the real value into public documentation."
  value       = google_compute_global_address.web.address
  sensitive   = true
}

output "regional_instance_group" {
  description = "Regional managed instance group name."
  value       = google_compute_region_instance_group_manager.web.name
}
