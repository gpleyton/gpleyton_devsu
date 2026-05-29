terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend remoto recomendado para producción (estado en GCS).
  # Se deja comentado para no requerir un bucket previo al evaluar.
  # backend "gcs" {
  #   bucket = "REEMPLAZAR-tf-state-bucket"
  #   prefix = "demo-devops-nodejs"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
