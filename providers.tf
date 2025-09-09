provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "current" {}
