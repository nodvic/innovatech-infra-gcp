variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  type    = string
  default = "security@innovatech.io"
}

variable "soar_webhook_function_url" {
  type = string
}
