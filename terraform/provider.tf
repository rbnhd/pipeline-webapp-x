# configuration for the GCP provider.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version  = ">=5.0.0"
    }
  }
  required_version = ">=1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  # credentials = file(var.credentials_file_path)
}


# The variables that will be used across TF
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region where resources should be created"
  type        = string
  default     = "asia-northeast1"
}

