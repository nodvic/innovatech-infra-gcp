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

resource "google_compute_subnetwork" "vdi_subnet" {
  name                     = "innovatech-subnet-vdi-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.spoke.id
  ip_cidr_range            = "10.20.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gke_subnet" {
  name                     = "innovatech-subnet-gke-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.spoke.id
  ip_cidr_range            = "10.20.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = "innovatech-subnet-db-${var.environment}"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.spoke.id
  ip_cidr_range            = "10.20.3.0/24"
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

resource "google_compute_firewall" "allow_ssh_spoke" {
  name    = "allow-ssh-iap-spoke-${var.environment}"
  network = google_compute_network.spoke.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["vdi-instance"]
  priority      = 1000
}
