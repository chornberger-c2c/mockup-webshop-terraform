variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "mockup-webshop"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "eu-central1"
}

variable "zone" {
  description = "GCP zone (used for node pool location if desired)"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "gke-network"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_ip_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "gke-cluster"
}

variable "region_location" {
  description = "Use region or zonal cluster. Valid values: 'regional' or 'zonal'"
  type        = string
  default     = "regional"
}

variable "node_count" {
  description = "Initial node count for the node pool"
  type        = number
  default     = 3
}

variable "node_machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "project_services" {
  description = "APIs to enable for the project"
  type        = list(string)
  default     = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com",
    "containerregistry.googleapis.com"
  ]
}
