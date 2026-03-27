output "dns_zone_name" {
  value = google_dns_managed_zone.private_zone.name
}

output "dns_zone_id" {
  value = google_dns_managed_zone.private_zone.id
}

output "database_dns_record" {
  value = google_dns_record_set.database_record.name
}
