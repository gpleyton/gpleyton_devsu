variable "project_id" {
  description = "GCP project ID where the infrastructure is created"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the zonal cluster (cheaper than a regional one)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "demo-devops-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Node machine type (e2-small to minimize cost)"
  type        = string
  default     = "e2-small"
}

variable "artifact_repo_id" {
  description = "Artifact Registry (Docker) repository ID"
  type        = string
  default     = "demo-devops-nodejs"
}
