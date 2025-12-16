terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure the backend for remote state management
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "looply/terraform"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.primary_region
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.primary_region
}
