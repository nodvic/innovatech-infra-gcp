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

variable "peer_gateway_ip_0" {
  type = string
}

variable "peer_gateway_ip_1" {
  type = string
}

variable "vpn_shared_secret" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type        = string
  description = "Het e-mailadres voor security alerts"
}
