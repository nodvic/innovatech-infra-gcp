resource "google_compute_firewall" "allow_internal" {
  name    = "innovatech-fw-allow-internal-${var.environment}"
  project = var.project_id
  network = var.hub_network_name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_cidr_ranges
  priority      = 1000
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "innovatech-fw-allow-ssh-iap-${var.environment}"
  project = var.project_id
  network = var.hub_network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  priority      = 1000
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "innovatech-fw-allow-healthcheck-${var.environment}"
  project = var.project_id
  network = var.hub_network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  priority      = 1000
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "innovatech-fw-deny-all-ingress-${var.environment}"
  project = var.project_id
  network = var.hub_network_name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

resource "google_compute_firewall" "spoke_allow_internal" {
  name    = "innovatech-fw-spoke-allow-internal-${var.environment}"
  project = var.project_id
  network = var.spoke_network_name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_cidr_ranges
  priority      = 1000
}

resource "google_compute_firewall" "spoke_deny_all_ingress" {
  name    = "innovatech-fw-spoke-deny-all-${var.environment}"
  project = var.project_id
  network = var.spoke_network_name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}
