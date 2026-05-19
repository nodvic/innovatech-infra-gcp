output "db_private_ip" {
  value     = module.database.private_ip_address
  sensitive = true
}

output "db_instance_name" {
  value = module.database.instance_name
}

output "gke_cluster_name" {
  value = "innovatech-gke-prod"
}
