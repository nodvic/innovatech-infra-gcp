resource "google_monitoring_notification_channel" "email" {
  display_name = "innovatech-alert-channel-email-${var.environment}"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_logging_metric" "ssh_failed_logins" {
  name    = "innovatech-metric-ssh-failed-${var.environment}"
  project = var.project_id
  filter  = "resource.type=\"gce_instance\" AND log_name=\"projects/${var.project_id}/logs/auth\" AND textPayload:\"Failed password\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_notification_channel" "soar_webhook" {
  display_name = "innovatech-alert-channel-webhook-${var.environment}"
  project      = var.project_id
  type         = "webhook_tokenauth"

  labels = {
    url = var.soar_webhook_function_url
  }
}

resource "google_monitoring_alert_policy" "ssh_brute_force" {
  display_name = "innovatech-alert-soar-ssh-${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "SSH Brute Force Detected"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.ssh_failed_logins.name}\" AND resource.type=\"gce_instance\""
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.soar_webhook.id
  ]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "sql_cpu_high" {
  display_name = "innovatech-alert-sql-cpu-critical-${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU > 80%"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "sql_memory_high" {
  display_name = "innovatech-alert-sql-memory-critical-${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL Memory > 80%"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "soar_function_errors" {
  display_name = "innovatech-alert-soar-critical-${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Function Error Rate"

    condition_threshold {
      filter          = "resource.type = \"cloud_function\" AND metric.type = \"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status != \"ok\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}


resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "innovatech-dashboard-${var.environment}"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "SSH Failed Logins"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type = \"logging.googleapis.com/user/innovatech-metric-ssh-failed-${var.environment}\" AND resource.type = \"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title = "Cloud SQL CPU"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
                }
              }
            }]
          }
        },
        {
          title = "Cloud SQL Memory"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\""
                }
              }
            }]
          }
        },
        {
          title = "VPN Tunnel Status"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"vpn_gateway\" AND metric.type = \"compute.googleapis.com/vpn/tunnel_established\""
                }
              }
            }]
          }
        }
      ]
    }
  })

  project = var.project_id
}
