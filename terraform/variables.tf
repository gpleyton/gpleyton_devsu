variable "project_id" {
  description = "ID del proyecto de GCP donde se crea la infraestructura"
  type        = string
}

variable "region" {
  description = "Región de GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de GCP para el cluster zonal (menor costo que uno regional)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Nombre del cluster de GKE"
  type        = string
  default     = "demo-devops-cluster"
}

variable "node_count" {
  description = "Número de nodos del node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Tipo de máquina de los nodos (e2-small para minimizar costo)"
  type        = string
  default     = "e2-small"
}

variable "artifact_repo_id" {
  description = "ID del repositorio de Artifact Registry (Docker)"
  type        = string
  default     = "demo-devops-nodejs"
}
