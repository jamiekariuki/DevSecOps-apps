variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "repo_url" {
  type = string
}

variable "target_revision" {
  type = string
}

variable "ENV_PREFIX" {
    type = string

    validation {
      condition = contains(["dev", "stage", "prod"], var.ENV_PREFIX)
      error_message = "provide an environment"
    }
}
