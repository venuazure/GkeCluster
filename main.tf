#vpc-network
resource "google_compute_network" "vpc-network" {
  name                    = "gke-cluster-vpc"
  auto_create_subnetworks = false
  description             = "vpc network for gke cluster"
}

#vpc-subnetwork
resource "google_compute_subnetwork" "vpc-subnetwork" {
  name                     = "gke-cluster-subnetwork"
  region                   = "asia-south1"
  ip_cidr_range            = "10.0.0.0/28"
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = true
  description              = "vpc subnetwork for gke cluster"
  depends_on               = [google_compute_network.vpc-network]
}

resource "google_container_cluster" "primary" {
  name     = "gke-private-cluster"
  location = "asia-south1-a"
  release_channel {
    channel = "STABLE"
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network             = google_compute_network.vpc-network.name
  subnetwork          = google_compute_subnetwork.vpc-subnetwork.name
  deletion_protection = false # Allows deletion without restrictions

  #change this value for compliance and non compliance
  enable_legacy_abac = false

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Enable Master Authorized Networks with individual cidr_blocks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "203.0.113.0/24" # Replace with your IP range
      display_name = "Office Network"
    }
    cidr_blocks {
      cidr_block   = "198.51.100.0/24" # Additional IP range if needed
      display_name = "Data Center"
    }
  }
  logging_service    = "none"
  monitoring_service = "none"

}

resource "google_container_node_pool" "primary_nodes" {
  name       = "gke-cluster-node-pool"
  location   = "asia-south1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    service_account = ""

    preemptible  = true
    machine_type = "e2-micro"
    disk_size_gb = 10

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}



