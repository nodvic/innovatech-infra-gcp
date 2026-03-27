resource "google_service_account" "soar_sa" {
  account_id   = "innovatech-soar-sa-${var.environment}"
  display_name = "innovatech-soar-sa-${var.environment}"
  project      = var.project_id
}

resource "google_project_iam_member" "soar_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_project_iam_member" "soar_compute_security_admin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_project_iam_member" "soar_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_project_iam_member" "soar_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

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
