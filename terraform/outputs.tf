output "cluster_name" {
  description = "Nombre del cluster de GKE"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint del API server del cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Ubicación (zona) del cluster"
  value       = google_container_cluster.primary.location
}

output "artifact_registry_repository" {
  description = "Ruta del repositorio Docker en Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "kubectl_connect_command" {
  description = "Comando para configurar kubectl contra el cluster creado"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}
