# The API's that needs to be enabled 
# NOTE that: ["serviceusage.googleapis.com", "cloudresourcemanager.googleapis.com"] API must be either enabled through GCP console or gcloud CLI. 
# It cant be enabled by TF, and we cant enable any other API if ["serviceusage.googleapis.com", "cloudresourcemanager.googleapis.com"] is not enabled

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
  disable_on_destroy = false
}
