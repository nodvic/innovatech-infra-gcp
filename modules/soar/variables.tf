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

variable "zone" {
  type        = string
  description = "De Google Cloud zone waarin de resources draaien"
}
