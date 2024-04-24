# This file will contain all the variables that will be used across TF
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The GCP region"
  default     = "asia-northeast1"
  type        = string
}

variable "credentials_file_path" {
  description = "The path to the service account key file"
  type        = string
}
