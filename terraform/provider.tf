# configuration for the GCP provider.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=5.0.0"
    }
  }
  required_version = ">=1.0"
}


# Although it's possible to create the backend storage location at runtime itself, it's a good idea to create the bucket...
# ... where state file will be stored beforehand and set the bucket name here
# If you want to automate this process also, refer: https://cloud.google.com/docs/terraform/resource-management/store-state#create_the_bucket
terraform {
  backend "gcs" {
    # the bucket name is provided dynamically during terraform init as param -backend-config=${}
    prefix = "terraform/state"
  }

}

provider "google" {
  project = var.project_id
  region  = var.region
  # # Uncomment this varible in case you are using local execution with service account JSON key
  # credentials = var.credentials_file_path
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


# Uncomment this varible in case you are using local execution with service account JSON key
/*
variable "credentials_file_path" {
  description = "The path to the service account key file"
  type        = string
}
*/
