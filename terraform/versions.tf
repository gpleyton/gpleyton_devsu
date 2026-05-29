terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Recommended remote backend for production (state in GCS).
  # Left commented to avoid requiring a pre-existing bucket for review.
  # backend "gcs" {
  #   bucket = "REPLACE-tf-state-bucket"
  #   prefix = "demo-devops-nodejs"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
