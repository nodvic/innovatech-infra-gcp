resource "google_dns_managed_zone" "private_zone" {
  name        = "innovatech-dns-zone-${var.environment}"
  project     = var.project_id
  dns_name    = var.dns_domain
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.hub_network_id
    }
    networks {
      network_url = var.spoke_network_id
    }
  }
}

resource "google_dns_record_set" "database_record" {
  name         = "db.${var.dns_domain}"
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.database_private_ip]
}
