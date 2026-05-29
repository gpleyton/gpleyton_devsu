output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Cluster API server endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Cluster location (zone)"
  value       = google_container_cluster.primary.location
}

output "ingress_static_ip" {
  description = "Static external IP reserved for the ingress LoadBalancer"
  value       = google_compute_address.ingress.address
}

output "artifact_registry_repository" {
  description = "Docker repository path in Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "kubectl_connect_command" {
  description = "Command to configure kubectl against the created cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}
