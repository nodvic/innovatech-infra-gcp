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

output "spoke_subnet_id" {
  value = google_compute_subnetwork.spoke.id
}

output "spoke_subnet_self_link" {
  value = google_compute_subnetwork.spoke.self_link
}

output "private_service_connect_connection" {
  value = google_service_networking_connection.private_service_connect.id
}
