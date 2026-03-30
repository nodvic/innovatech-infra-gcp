resource "google_monitoring_notification_channel" "email" {
  display_name = "innovatech-alert-channel-email-${var.environment}"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "cpu_high" {
  display_name = "innovatech-alert-cpu-critical-${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "CPU Utilization > 80%"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
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
          title = "VM CPU Utilization"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
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
