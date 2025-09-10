resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  description             = "VPC for GKE cluster"
}

resource "google_project_service" "services" {
  for_each = toset(var.project_services)
  service  = each.key
  disable_on_destroy = false
  project = var.project
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "gke-cluster-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-cluster-services"
    ip_cidr_range = "10.2.0.0/20"
  }
}
