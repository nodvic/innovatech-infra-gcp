output "soar_service_account_email" {
  value = google_service_account.soar_sa.email
}

output "soar_service_account_id" {
  value = google_service_account.soar_sa.id
}
