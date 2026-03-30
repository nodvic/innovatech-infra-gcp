resource "google_storage_bucket" "soar_functions" {
  name                        = "innovatech-soar-functions-${var.project_id}-${var.region}-${var.environment}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "email_notification" {
  type        = "zip"
  source_dir  = "${path.module}/functions/email_notification"
  output_path = "${path.module}/tmp/email_notification.zip"
}

data "archive_file" "webhook" {
  type        = "zip"
  source_dir  = "${path.module}/functions/webhook"
  output_path = "${path.module}/tmp/webhook.zip"
}

data "archive_file" "firewall_block" {
  type        = "zip"
  source_dir  = "${path.module}/functions/firewall_block"
  output_path = "${path.module}/tmp/firewall_block.zip"
}

data "archive_file" "db_logging" {
  type        = "zip"
  source_dir  = "${path.module}/functions/db_logging"
  output_path = "${path.module}/tmp/db_logging.zip"
}

resource "google_storage_bucket_object" "email_notification" {
  name   = "email_notification-${data.archive_file.email_notification.output_md5}.zip"
  bucket = google_storage_bucket.soar_functions.name
  source = data.archive_file.email_notification.output_path
}

resource "google_storage_bucket_object" "webhook" {
  name   = "webhook-${data.archive_file.webhook.output_md5}.zip"
  bucket = google_storage_bucket.soar_functions.name
  source = data.archive_file.webhook.output_path
}

resource "google_storage_bucket_object" "firewall_block" {
  name   = "firewall_block-${data.archive_file.firewall_block.output_md5}.zip"
  bucket = google_storage_bucket.soar_functions.name
  source = data.archive_file.firewall_block.output_path
}

resource "google_storage_bucket_object" "db_logging" {
  name   = "db_logging-${data.archive_file.db_logging.output_md5}.zip"
  bucket = google_storage_bucket.soar_functions.name
  source = data.archive_file.db_logging.output_path
}

resource "google_cloudfunctions_function" "email_notification" {
  name                  = "innovatech-soar-email-${var.environment}"
  project               = var.project_id
  region                = var.region
  runtime               = "python310"
  entry_point           = "handle_email"
  source_archive_bucket = google_storage_bucket.soar_functions.name
  source_archive_object = google_storage_bucket_object.email_notification.name
  trigger_http          = true
  available_memory_mb   = 256
  timeout               = 120

  environment_variables = {
    SMTP_SERVER  = var.smtp_server
    SMTP_PORT    = var.smtp_port
    SENDER_EMAIL = var.sender_email
    ALERT_EMAIL  = var.alert_email
  }

  vpc_connector = google_vpc_access_connector.soar_connector.id
}

resource "google_cloudfunctions_function" "webhook" {
  name                  = "innovatech-soar-webhook-${var.environment}"
  project               = var.project_id
  region                = var.region
  runtime               = "python310"
  entry_point           = "handle_webhook"
  source_archive_bucket = google_storage_bucket.soar_functions.name
  source_archive_object = google_storage_bucket_object.webhook.name
  trigger_http          = true
  available_memory_mb   = 256
  timeout               = 120

  environment_variables = {
    WEBHOOK_URL = var.webhook_url
  }

  vpc_connector = google_vpc_access_connector.soar_connector.id
}

resource "google_cloudfunctions_function" "firewall_block" {
  name                  = "innovatech-soar-fw-block-${var.environment}"
  project               = var.project_id
  region                = var.region
  runtime               = "python310"
  entry_point           = "handle_firewall_block"
  source_archive_bucket = google_storage_bucket.soar_functions.name
  source_archive_object = google_storage_bucket_object.firewall_block.name
  trigger_http          = true
  available_memory_mb   = 256
  timeout               = 120

  environment_variables = {
    GCP_PROJECT_ID = var.project_id
    NETWORK_NAME   = var.hub_network_name
  }

  vpc_connector = google_vpc_access_connector.soar_connector.id
}

resource "google_cloudfunctions_function" "db_logging" {
  name                  = "innovatech-soar-db-log-${var.environment}"
  project               = var.project_id
  region                = var.region
  runtime               = "python310"
  entry_point           = "handle_db_logging"
  source_archive_bucket = google_storage_bucket.soar_functions.name
  source_archive_object = google_storage_bucket_object.db_logging.name
  trigger_http          = true
  available_memory_mb   = 256
  timeout               = 120

  environment_variables = {
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

resource "google_cloudfunctions_function_iam_member" "email_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.email_notification.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.invoker_service_account}"
}

resource "google_cloudfunctions_function_iam_member" "webhook_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.webhook.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.invoker_service_account}"
}

resource "google_cloudfunctions_function_iam_member" "firewall_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.firewall_block.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.invoker_service_account}"
}

resource "google_cloudfunctions_function_iam_member" "db_logging_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.db_logging.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.invoker_service_account}"
}
