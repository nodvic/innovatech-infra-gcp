resource "google_container_cluster" "primary" {
  name                     = "innovatech-gke-${var.environment}"
  project                  = var.project_id
  location                 = var.zone
  network                  = var.spoke_network_id
  subnetwork               = var.gke_subnet_id
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "spot_nodes" {
  name       = "spot-node-pool"
  project    = var.project_id
  cluster    = google_container_cluster.primary.name
  location   = var.zone
  node_count = 1

  node_config {
    spot         = true
    machine_type = "e2-medium"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
