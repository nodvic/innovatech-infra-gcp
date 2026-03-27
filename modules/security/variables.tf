variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "hub_network_name" {
  type = string
}

variable "spoke_network_name" {
  type = string
}

variable "internal_cidr_ranges" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}
