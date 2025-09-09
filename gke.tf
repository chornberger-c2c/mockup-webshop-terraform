locals {
  is_regional = var.region_location == "regional"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project
}

# Grant basic roles to the service account (adjust as necessary)
resource "google_project_iam_member" "node_sa_storage" {
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Main GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  project  = var.project
  location = local.is_regional ? var.region : var.zone

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable autopilot? if you want autopilot set autopilot = { enabled = true } instead of node pools
  # Enable Pod Security Policy / Workload Identity or other features here
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.cluster_name}-pods"
    services_secondary_range_name = "${var.cluster_name}-services"
  }

  # basic cluster features
  network_policy {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # master_authorized_networks_config {
  #   cidr_blocks = []
  # }

  # optionally enable private cluster - commented out, enable if needed
  # private_cluster_config {
  #   enable_private_nodes = true
  #   master_ipv4_cidr_block = "172.16.0.0/28"
  # }

  # Enable Workload Identity (recommended)
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }
}

# Create secondary ranges for VPC-native cluster (required for ip_allocation_policy)
resource "google_compute_global_address" "pods" {
  name          = "${var.cluster_name}-pods"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_compute_global_address" "services" {
  name          = "${var.cluster_name}-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                  = google
  network                   = google_compute_network.vpc.id
  reserved_peering_ranges   = [google_compute_global_address.pods.name, google_compute_global_address.services.name]
  service                   = "services/${google_project_service.services["servicenetworking.googleapis.com"].service}"
  depends_on                = [google_project_service.services]
}

# Node pool (separate resource for fine-grained control)
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-pool"
  project    = var.project
  location   = local.is_regional ? var.region : var.zone
  cluster    = google_container_cluster.primary.name

  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
    service_account = google_service_account.gke_nodes.email
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
