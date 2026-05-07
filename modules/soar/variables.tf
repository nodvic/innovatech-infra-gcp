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

# BUG-11: Default gecorrigeerd — 10.20.2.0/28 overlapte met gke_subnet (10.20.2.0/24)
variable "connector_cidr" {
  type    = string
  default = "10.20.4.0/28"
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

# BUG-03: Variabele toegevoegd — werd gebruikt in main.tf maar niet gedeclareerd
variable "db_private_ip" {
  type        = string
  description = "Het private IP-adres van de Cloud SQL-instantie voor directe TCP-verbinding"
}

# BUG-06: Variabele voor de beperkte invoker van de Cloud Function
variable "invoker_service_account" {
  type        = string
  description = "Het service account email dat de SOAR function mag aanroepen"
}
