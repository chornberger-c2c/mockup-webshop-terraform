locals {
  is_regional = var.region_location == "regional"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project
}

resource "google_project_iam_member" "node_sa_storage" {
  project = var.project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_container_cluster" "primary" {
  name                = "grs-cluster"
  location            = "europe-west3"
  project             = var.project
  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-cluster-pods"
    services_secondary_range_name = "gke-cluster-services"
  }

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  initial_node_count = 1
}

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

# resource "google_container_node_pool" "primary_nodes" {
#   name       = "${var.cluster_name}-pool"
#   project    = var.project
#   location   = local.is_regional ? var.region : var.zone
#   cluster    = google_container_cluster.primary.name

#   node_count = var.node_count

#   node_config {
#     machine_type = var.node_machine_type
#     disk_type    = "pd-standard"

#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#       "https://www.googleapis.com/auth/devstorage.read_only",
#     ]
#     service_account = google_service_account.gke_nodes.email
#   }

#   autoscaling {
#     min_node_count = 1
#     max_node_count = 5
#   }

#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }

#   depends_on = [google_service_networking_connection.private_vpc_connection]
# }
