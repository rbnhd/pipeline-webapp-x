variable "project_id" {
  description = "The ID of the GCP project"
}

variable "region" {
  description = "The GCP region"
  default     = "asia-northeast1"
}

variable "credentials_file_path" {
  description = "The path to the service account key file"
}