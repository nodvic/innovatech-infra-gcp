variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type        = string
  description = "Het e-mailadres voor security alerts"
}
