output "notification_channel_id" {
  value = google_monitoring_notification_channel.email.id
}

output "ssh_brute_force_alert_policy_id" {
  value = google_monitoring_alert_policy.ssh_brute_force.id
}

output "sql_cpu_alert_policy_id" {
  value = google_monitoring_alert_policy.sql_cpu_high.id
}

output "soar_alert_policy_id" {
  value = google_monitoring_alert_policy.soar_function_errors.id
}

output "dashboard_id" {
  value = google_monitoring_dashboard.main.id
}
