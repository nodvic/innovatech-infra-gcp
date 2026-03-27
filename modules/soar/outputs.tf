output "email_function_url" {
  value = google_cloudfunctions_function.email_notification.https_trigger_url
}

output "webhook_function_url" {
  value = google_cloudfunctions_function.webhook.https_trigger_url
}

output "firewall_block_function_url" {
  value = google_cloudfunctions_function.firewall_block.https_trigger_url
}

output "db_logging_function_url" {
  value = google_cloudfunctions_function.db_logging.https_trigger_url
}

output "vpc_connector_id" {
  value = google_vpc_access_connector.soar_connector.id
}
