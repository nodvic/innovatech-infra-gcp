output "soar_handler_function_url" {
  value = google_cloudfunctions_function.soar_handler.https_trigger_url
}

output "vpc_connector_id" {
  value = google_vpc_access_connector.soar_connector.id
}
