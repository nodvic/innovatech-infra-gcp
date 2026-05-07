resource "google_compute_instance" "vdi_pool" {
  count        = 5
  name         = "innovatech-vdi-0${count.index + 1}-${var.environment}"
  machine_type = "e2-medium"
  zone         = var.zone
  project      = var.project_id

  scheduling {
    provisioning_model = "SPOT"
    preemptible        = true
    automatic_restart  = false
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = var.spoke_network_id
    subnetwork = var.vdi_subnet_id
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}
