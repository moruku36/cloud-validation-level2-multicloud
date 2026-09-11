variable "location" {
  description = "Azure region used by the validation environment."
  type        = string
  default     = "japaneast"

  validation {
    condition     = contains(["japaneast", "japanwest"], var.location)
    error_message = "location must be japaneast or japanwest."
  }
}

variable "project_name" {
  description = "Project identifier used in names and tags."
  type        = string
  default     = "azure-ai-terraform-validation"
}

variable "environment" {
  description = "Environment identifier used in names and tags."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space assigned to the validation virtual network."
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

variable "application_gateway_subnet_cidr" {
  description = "Dedicated subnet prefix for Application Gateway."
  type        = string
  default     = "10.30.0.0/24"
}

variable "backend_subnet_cidr" {
  description = "Private subnet prefix for backend virtual machines."
  type        = string
  default     = "10.30.10.0/24"
}

variable "vm_size" {
  description = "Azure VM size for each Nginx backend."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Local administrator name. SSH is not exposed to the Internet."
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key used for emergency access through an approved private path. Never provide a private key."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp(256|384|521)) ", trimspace(var.admin_ssh_public_key)))
    error_message = "admin_ssh_public_key must be an OpenSSH public key."
  }
}

variable "vm_zones" {
  description = "Backend VM names and availability zones."
  type        = map(string)
  default = {
    web1 = "1"
    web2 = "2"
  }

  validation {
    condition     = length(var.vm_zones) == 2 && alltrue([for zone in values(var.vm_zones) : contains(["1", "2", "3"], zone)])
    error_message = "Exactly two VMs must be assigned to Azure availability zones 1, 2, or 3."
  }
}

variable "application_gateway_min_capacity" {
  description = "Minimum autoscale capacity for Application Gateway Standard_v2."
  type        = number
  default     = 0
}

variable "application_gateway_max_capacity" {
  description = "Maximum autoscale capacity for Application Gateway Standard_v2."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags merged with the standard project tags."
  type        = map(string)
  default = {
    Purpose = "AI infrastructure validation"
  }
}

variable "monitoring_log_retention_days" {
  description = "Days to retain Application Gateway diagnostic logs in Azure Storage."
  type        = number
  default     = 30
}

variable "vm_cpu_threshold_percent" {
  description = "Average VM CPU percentage that triggers an alert."
  type        = number
  default     = 80
}

variable "http_5xx_threshold" {
  description = "Maximum tolerated Application Gateway HTTP 5xx responses per five-minute window."
  type        = number
  default     = 5
}
