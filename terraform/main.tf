############################################
# Required APIs
############################################
resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",        # GKE
    "artifactregistry.googleapis.com", # Artifact Registry
    "compute.googleapis.com",          # networking/instances for GKE
  ])
  service            = each.value
  disable_on_destroy = false
}

############################################
# Artifact Registry (Docker repository)
############################################
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.artifact_repo_id
  description   = "Docker images for the demo-devops-nodejs app"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}

############################################
# GKE cluster (zonal to minimize cost)
############################################
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Remove the default node pool to manage a custom one
  remove_default_node_pool = true
  initial_node_count       = 1

  # Basic security recommendations
  release_channel {
    channel = "REGULAR"
  }

  deletion_protection = false

  depends_on = [google_project_service.services]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 30
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      app = "demo-devops-nodejs"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
