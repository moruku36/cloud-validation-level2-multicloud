variable "project_id" {
  description = "Google Cloud project ID. Keep the real value out of public documentation."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Google Cloud region for the workload."
  type        = string
  default     = "asia-northeast1"
}

variable "zones" {
  description = "Two zones used by the regional managed instance group."
  type        = list(string)
  default     = ["asia-northeast1-a", "asia-northeast1-c"]

  validation {
    condition     = length(var.zones) == 2 && alltrue([for zone in var.zones : startswith(zone, "${var.region}-")])
    error_message = "zones must contain exactly two zones in the selected region."
  }
}

variable "name_prefix" {
  description = "Prefix applied consistently to validation resources."
  type        = string
  default     = "ai-infra-validation"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
}

variable "subnet_cidr" {
  description = "CIDR for the regional private backend subnet."
  type        = string
  default     = "10.40.0.0/24"
}

variable "machine_type" {
  description = "Low-cost machine type for the two Nginx instances."
  type        = string
  default     = "e2-micro"
}

variable "target_size" {
  description = "Fixed number of instances in the regional MIG."
  type        = number
  default     = 2

  validation {
    condition     = var.target_size == 2
    error_message = "This validation requires exactly two backend VMs."
  }
}

variable "apply_service_account_email" {
  description = "Optional GitHub apply service account allowed to attach the zero-role VM runtime service account."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "labels" {
  description = "Additional labels merged with the standard labels."
  type        = map(string)
  default     = {}
}

variable "monitoring_cpu_threshold" {
  description = "CPU utilization ratio that opens the backend VM alert after five minutes."
  type        = number
  default     = 0.8

  validation {
    condition     = var.monitoring_cpu_threshold > 0 && var.monitoring_cpu_threshold <= 1
    error_message = "monitoring_cpu_threshold must be greater than 0 and at most 1."
  }
}

variable "monitoring_http_5xx_threshold" {
  description = "Number of HTTP 5xx responses in five minutes that opens the load balancer alert."
  type        = number
  default     = 5

  validation {
    condition     = var.monitoring_http_5xx_threshold >= 1
    error_message = "monitoring_http_5xx_threshold must be at least 1."
  }
}
