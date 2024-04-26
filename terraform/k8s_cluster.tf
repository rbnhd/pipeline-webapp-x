# This file will contain the configuration for the Kubernetes cluster and node pool.
variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}

resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection = false
  
  node_config {
    disk_size_gb = 10
    # Use preemptible for lowest cost (if testing)
    preemptible  = true
    machine_type = "e2-micro"
    tags         = ["gke-node", "${var.project_id}-gke", "default-node-gke"]
  }


  # private_cluster_config {
  #   enable_private_endpoint = true
  #   enable_private_nodes   = true 
  #   master_ipv4_cidr_block = "10.13.0.0/28"

  #   master_global_access_config {
  #     enabled = true
  #   }
  # }

  # # Uncomment if using private GKE cluster. (not possible in testing case where GitHub runner IP needs to access k8s master API)
  # ip_allocation_policy {
  #   cluster_ipv4_cidr_block  = "10.11.0.0/21"
  #   services_ipv4_cidr_block = "10.12.0.0/21"
  # }

  # # Uncomment if using private GKE cluster. (not possible in testing case where GitHub runner IP needs to access k8s master API)
  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "10.0.0.0/8"   # When using self hosted GitHub runner, set the CIDR to your self-hosted runner IP range. In this case where using free runners, need to allow all IP so that GitHub can access k8s master network API
  #     display_name = "net1"
  #   }
  # }

}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.region
  cluster    = google_container_cluster.primary.name

  version = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
      env = var.project_id
    }
    disk_size_gb = 10
    # Use preemptible for lowest cost (if testing)
    preemptible  = true
    machine_type = "e2-micro"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
