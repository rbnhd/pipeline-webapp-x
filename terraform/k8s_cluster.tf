# This file will contain the configuration for the Kubernetes cluster and node pool.
variable "cluster_name" {
  default     = "test-gke"
  description = "Name of the GKE cluster"
}

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
  location       = var.region
  version_prefix = "1.28."
}

resource "google_container_cluster" "primary" {
  name        = var.cluster_name
  location    = var.region
  network     = google_compute_network.vpc.name
  subnetwork  = google_compute_subnetwork.subnet.name
  description = "Primary GKE cluster"

  # We can't create a cluster with no node pool defined, but we want to only use separately managed node pools. So we create the smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Set `deletion_protection` to `true` will ensure that one cannot accidentally delete this instance by use of Terraform.
  deletion_protection = false

  node_config {
    disk_size_gb = 10   # Minimum size allowed
    preemptible  = true # Use preemptible for lowest cost (if testing)
    machine_type = "e2-micro"
    tags         = ["gke-node", "${var.cluster_name}", "default-node-gke"]
  }


  # # NOTE: Uncomment the below blocks, if using private GKE cluster. (not possible in this case, where GitHub runner IP needs to access k8s master API)....
  # # .....Ideally, your runner would be hosted in same VPC(or VPC peering) as the GKE cluster, and you would use private cluster. 
  /*
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.13.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
  }

  # enable_autopilot = true  # enable_autopilot can't be used at the same time as remove_default_node_pool

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8" # When using self hosted GitHub runner, set the CIDR to your self-hosted runner IP range. In this case where using free runners, need to allow all IP so that GitHub can access k8s master network API
      display_name = "net1"
    }
  }
  */

}


# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = google_container_cluster.primary.name
  location = var.region
  cluster  = google_container_cluster.primary.name


  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
      env = var.project_id
    }
    disk_size_gb = 10 # Minimum size allowed
    disk_type    = "pd-standard"
    spot         = true # Use spot for lowest cost (if testing)
    machine_type = "e2-micro"
    tags         = ["gke-node", "${var.cluster_name}"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 3
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}
