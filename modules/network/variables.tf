variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "hub_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

