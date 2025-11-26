variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
  sensitive = true
}

variable "service_account_name" {
  type = string
}

variable "ENV_PREFIX" {
    type = string

    validation {
      condition = contains(["dev", "stage", "prod"], var.ENV_PREFIX)
      error_message = "provide an environment"
    }
}