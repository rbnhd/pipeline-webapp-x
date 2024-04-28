# This network.tf will create a VPC network and a firewall rule that allows SSH traffic.
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
  description             = "VPC for GKE cluster"

  # # The VPC should depend on the required API's, Just in case, if it's not enabled already. 
  depends_on = [google_project_service.compute_api, google_project_service.container_api]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/16"
  description   = "Subnet for GKE cluster"

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.1.0/24"
  }
}

resource "google_compute_firewall" "allow_nodeports" {
  name    = "${var.project_id}-allow-gke-nodeports"
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = ["31000-31001"]
  }
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow traffic to GKE NodePorts"
}