# This network.tf will create a VPC network and a firewall rule that allows SSH traffic.
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc1"
  auto_create_subnetworks = "false"

  # # The VPC should depend on the required API's, Just in case, if it's not enabled already. 
  depends_on = [
    google_project_service.compute_api,
    google_project_service.container_api,
  ]
}

# resource "google_compute_subnetwork" "subnet" {
#   name          = "${var.project_id}-subnet1"
#   region        = var.region
#   network       = google_compute_network.vpc.name
#   ip_cidr_range = "10.10.0.0/24"
# }

# resource "google_compute_firewall" "default_allow_ssh" {
#   name    = "${var.project_id}-default-allow-ssh1"
#   network = google_compute_network.vpc.self_link
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
#   source_ranges = ["0.0.0.0/0"]
# }