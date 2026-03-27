variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_network_id" {
  type = string
}

variable "private_service_connect_connection" {
  type = string
}

variable "database_version" {
  type    = string
  default = "MYSQL_8_0"
}

variable "database_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "db_user" {
  type    = string
  default = "innovatech-admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}
