output "db_private_ip" {
  value     = module.database.private_ip_address
  sensitive = true
}

output "db_instance_name" {
  value = module.database.instance_name
}

output "gke_endpoint" {
  value     = module.gke.endpoint
  sensitive = true
}

output "gke_ca_cert" {
  value     = module.gke.ca_certificate
  sensitive = true
}
