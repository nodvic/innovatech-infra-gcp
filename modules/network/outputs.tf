output "hub_network_id" {
  value = google_compute_network.hub.id
}

output "hub_network_name" {
  value = google_compute_network.hub.name
}

output "hub_network_self_link" {
  value = google_compute_network.hub.self_link
}

output "hub_subnet_id" {
  value = google_compute_subnetwork.hub.id
}

output "hub_subnet_self_link" {
  value = google_compute_subnetwork.hub.self_link
}

output "spoke_network_id" {
  value = google_compute_network.spoke.id
}

output "spoke_network_name" {
  value = google_compute_network.spoke.name
}

output "spoke_network_self_link" {
  value = google_compute_network.spoke.self_link
}

output "private_service_connect_connection" {
  value = google_service_networking_connection.private_service_connect.id
}

output "vdi_subnet_id" {
  value = google_compute_subnetwork.vdi_subnet.id
}

output "gke_subnet_id" {
  value = google_compute_subnetwork.gke_subnet.id
}

output "db_subnet_id" {
  value = google_compute_subnetwork.db_subnet.id
}
