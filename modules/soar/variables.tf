variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_network_name" {
  type = string
}

variable "hub_network_name" {
  type = string
}

variable "connector_cidr" {
  type    = string
  default = "10.20.2.0/28"
}

variable "smtp_server" {
  type    = string
  default = "smtp.gmail.com"
}

variable "smtp_port" {
  type    = string
  default = "587"
}

variable "sender_email" {
  type    = string
  default = "alerts@innovatech.io"
}

variable "alert_email" {
  type    = string
  default = "security@innovatech.io"
}

variable "webhook_url" {
  type    = string
  default = "https://hooks.slack.com/services/PLACEHOLDER"
}

variable "db_connection_name" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type    = string
  default = "innovatech-admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "invoker_service_account" {
  type = string
}
