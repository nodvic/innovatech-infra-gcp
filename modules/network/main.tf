resource "google_compute_network" "hub" {
  name                    = "innovatech-vpc-hub-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "hub" {
  name                     = "innovatech-subnet-hub-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.hub.id
  ip_cidr_range            = var.hub_subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_network" "spoke" {
  name                    = "innovatech-vpc-spoke-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "spoke" {
  name                     = "innovatech-subnet-spoke-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.spoke.id
  ip_cidr_range            = var.spoke_subnet_cidr
  private_ip_google_access = true
}

resource "google_compute_network_peering" "hub_to_spoke" {
  name                 = "innovatech-peering-hub-to-spoke-${var.environment}"
  network              = google_compute_network.hub.self_link
  peer_network         = google_compute_network.spoke.self_link
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "spoke_to_hub" {
  name                 = "innovatech-peering-spoke-to-hub-${var.environment}"
  network              = google_compute_network.spoke.self_link
  peer_network         = google_compute_network.hub.self_link
  export_custom_routes = true
  import_custom_routes = true
  depends_on           = [google_compute_network_peering.hub_to_spoke]
}

resource "google_compute_global_address" "private_service_connect" {
  name          = "innovatech-psc-address-${var.environment}"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.spoke.id
}

resource "google_service_networking_connection" "private_service_connect" {
  network                 = google_compute_network.spoke.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_connect.name]
  depends_on              = [google_compute_network_peering.spoke_to_hub]
}
