# This file will contain the configuration for the Kubernetes cluster and node pool.
resource "google_container_cluster" "primary" {
  name     = "example-cluster"
  location = var.region


  initial_node_count = 3

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    preemptible  = true
    machine_type = "e2-medium"
  }

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.subnetwork.self_link
}