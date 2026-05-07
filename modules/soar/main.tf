resource "google_storage_bucket" "soar_functions" {
  name                        = "soar-fn-${var.project_id}-${var.region}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "soar_handler" {
  type        = "zip"
  source_dir  = "${path.module}/functions/soar_handler"
  output_path = "${path.module}/tmp/soar_handler.zip"
}

resource "google_storage_bucket_object" "soar_handler_code" {
  name   = "soar_handler-${data.archive_file.soar_handler.output_md5}.zip"
  bucket = google_storage_bucket.soar_functions.name
  source = data.archive_file.soar_handler.output_path
}

resource "google_cloudfunctions_function" "soar_handler" {
  name                  = "innovatech-soar-handler-${var.environment}"
  project               = var.project_id
  region                = var.region
  runtime               = "python310"
  entry_point           = "handle_soar_event"
  source_archive_bucket = google_storage_bucket.soar_functions.name
  source_archive_object = google_storage_bucket_object.soar_handler_code.name
  trigger_http          = true
  available_memory_mb   = 256
  timeout               = 120
  service_account_email = google_service_account.soar_sa.email

  environment_variables = {
    GCP_PROJECT_ID     = var.project_id
    NETWORK_NAME       = var.hub_network_name
    DB_CONNECTION_NAME = var.db_connection_name
    DB_NAME            = var.db_name
    DB_USER            = var.db_user
    DB_PASSWORD        = var.db_password
  }

  vpc_connector = google_vpc_access_connector.soar_connector.id
}

resource "google_vpc_access_connector" "soar_connector" {
  name          = "innovatech-soar-conn-${var.environment}"
  project       = var.project_id
  region        = var.region
  network       = var.spoke_network_name
  ip_cidr_range = var.connector_cidr
}

resource "google_service_account" "soar_sa" {
  account_id   = "soar-handler-sa-${var.environment}"
  display_name = "SOAR Handler Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "soar_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_project_iam_member" "soar_compute_security_admin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_project_iam_member" "soar_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.soar_sa.email}"
}

resource "google_cloudfunctions_function_iam_member" "handler_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.soar_handler.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers" # Voor testdoeleinden
}
