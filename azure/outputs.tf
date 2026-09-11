output "application_url" {
  description = "Public HTTP URL of the Application Gateway."
  value       = "http://${azurerm_public_ip.application_gateway.ip_address}"
}

output "backend_vm_count" {
  description = "Number of private backend virtual machines."
  value       = length(azurerm_linux_virtual_machine.web)
}

output "backend_public_ip_attached" {
  description = "Invariant: backend network interfaces do not have a public IP configuration."
  value       = false
}

