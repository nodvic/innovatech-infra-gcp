variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "dns_domain" {
  type    = string
  default = "innovatech.internal."
}

variable "hub_network_id" {
  type = string
}

variable "spoke_network_id" {
  type = string
}

variable "database_private_ip" {
  type    = string
  default = "10.2.0.2"
}
