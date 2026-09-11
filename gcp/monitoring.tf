resource "google_monitoring_uptime_check_config" "web" {
  display_name       = "${local.resource_name}-http-uptime"
  timeout            = "10s"
  period             = "60s"
  checker_type       = "STATIC_IP_CHECKERS"
  log_check_failures = true
  user_labels        = local.common_labels

  http_check {
    path           = "/"
    port           = 80
    request_method = "GET"
    use_ssl        = false
    validate_ssl   = false

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_global_address.web.address
    }
  }

  content_matchers {
    content = "GCP AI Infrastructure Validation"
    matcher = "CONTAINS_STRING"
  }
}

resource "google_logging_metric" "unhealthy_backend" {
  name        = "${local.resource_name}-unhealthy-backend"
  description = "Counts load balancer health-check transitions to an unhealthy state."
  filter = join("\n", [
    "log_id(\"compute.googleapis.com/healthchecks\")",
    "resource.type=\"gce_instance_group\"",
    "resource.labels.instance_group_name=\"${google_compute_region_instance_group_manager.web.name}\"",
    "jsonPayload.healthCheckProbeResult.detailedHealthState=~\"UNHEALTHY|TIMEOUT\"",
  ])

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "web_unavailable" {
  display_name = "${local.resource_name}: web unavailable"
  combiner     = "OR"
  enabled      = true
  user_labels  = local.common_labels

  conditions {
    display_name = "Uptime check fails from at least two locations"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.\"check_id\"=\"${google_monitoring_uptime_check_config.web.uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "120s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "The public HTTP endpoint failed from multiple Google uptime-check locations. Check load balancer health, backend health, and recent changes."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "backend_capacity" {
  display_name = "${local.resource_name}: backend capacity below target"
  combiner     = "OR"
  enabled      = true
  user_labels  = local.common_labels

  conditions {
    display_name = "Regional MIG has fewer than ${var.target_size} instances"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance_group/size\" AND resource.type=\"instance_group\" AND resource.label.\"instance_group_name\"=\"${google_compute_region_instance_group_manager.web.name}\""
      comparison      = "COMPARISON_LT"
      threshold_value = var.target_size
      duration        = "120s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "The regional managed instance group is below its configured target size. Check VM lifecycle events and autohealing activity."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "backend_health" {
  display_name = "${local.resource_name}: backend health-check failure"
  combiner     = "OR"
  enabled      = true
  user_labels  = local.common_labels

  conditions {
    display_name = "Load balancer backend became unhealthy"

    condition_threshold {
      filter                  = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.unhealthy_backend.name}\" AND resource.type=\"global\""
      comparison              = "COMPARISON_GT"
      threshold_value         = 0
      duration                = "60s"
      evaluation_missing_data = "EVALUATION_MISSING_DATA_INACTIVE"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "A load balancer health-check transition reported an UNHEALTHY or TIMEOUT backend. Inspect compute.googleapis.com/healthchecks logs."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${local.resource_name}: VM CPU high"
  combiner     = "OR"
  enabled      = true
  user_labels  = local.common_labels

  conditions {
    display_name = "Backend VM CPU exceeds ${var.monitoring_cpu_threshold * 100}%"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND metric.label.\"instance_name\"=starts_with(\"${local.resource_name}-web\")"
      comparison      = "COMPARISON_GT"
      threshold_value = var.monitoring_cpu_threshold
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "A backend VM sustained high CPU utilization. Review instance metrics and load balancer access logs before resizing."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "http_5xx" {
  display_name = "${local.resource_name}: HTTP 5xx increase"
  combiner     = "OR"
  enabled      = true
  user_labels  = local.common_labels

  conditions {
    display_name = "At least ${var.monitoring_http_5xx_threshold} HTTP 5xx responses in five minutes"

    condition_threshold {
      filter          = "metric.type=\"loadbalancing.googleapis.com/https/request_count\" AND resource.type=\"https_lb_rule\" AND resource.label.\"url_map_name\"=\"${google_compute_url_map.web.name}\" AND metric.label.\"response_code_class\"=\"500\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.monitoring_http_5xx_threshold - 1
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    content   = "The external Application Load Balancer returned multiple HTTP 5xx responses. Inspect backend health and load balancer request logs."
    mime_type = "text/markdown"
  }
}
