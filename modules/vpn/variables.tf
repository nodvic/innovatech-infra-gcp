variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "hub_network_id" {
  type = string
}

variable "hub_router_asn" {
  type    = number
  default = 64514
}

variable "peer_asn" {
  type    = number
  default = 64515
}

variable "peer_gateway_ip_0" {
  type    = string
  default = "8.8.8.8"
}

variable "peer_gateway_ip_1" {
  type    = string
  default = "8.8.4.4"
}

variable "vpn_shared_secret" {
  type      = string
  sensitive = true
  default   = "innovatech-vpn-secret-change-me"
}

variable "router_interface_0_ip" {
  type    = string
  default = "169.254.0.1/30"
}

variable "router_interface_1_ip" {
  type    = string
  default = "169.254.0.5/30"
}

variable "bgp_peer_ip_0" {
  type    = string
  default = "169.254.0.2"
}

variable "bgp_peer_ip_1" {
  type    = string
  default = "169.254.0.6"
}
