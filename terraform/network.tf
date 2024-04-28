# This network.tf will create a VPC network and a firewall rule that allows SSH traffic.
resource "google_compute_network" "vpc" {
  name                     = "${var.project_id}-vpc"
  auto_create_subnetworks  = "false"
  enable_ula_internal_ipv6 = true
  description              = "VPC for GKE cluster"

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

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_nodeports" {
  name        = "${var.project_id}-allow-gke-nodeports"
  network     = google_compute_network.vpc.self_link
  description = "Allow traffic to GKE NodePorts"

  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["31000-31001"] # The port ranges used by k8s-service
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node", "${var.cluster_name}"] # Only allow ingress to gke node created

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
