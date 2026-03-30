resource "google_sql_database_instance" "main" {
  name                = "innovatech-sql-instance-${var.environment}"
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = false

  depends_on = [var.private_service_connect_connection]

  settings {
    tier              = var.database_tier
    availability_type = "ZONAL"

    disk_size       = var.disk_size
    disk_type       = "PD_HDD"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.spoke_network_id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }
  }
}

resource "google_sql_database" "main" {
  name     = "innovatech-db-${var.environment}"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  name     = var.db_user
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = var.db_password
}
