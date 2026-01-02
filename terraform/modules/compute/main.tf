# Compute Module - Cloud Run Service (Bundled Frontend & Backend)
# Purpose: Single Cloud Run service with bundled frontend and backend in one container

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Bundled Cloud Run Service - Primary Region
# ============================================
# Single Cloud Run service with bundled frontend and backend
# The Docker image should contain:
# - Backend API endpoints at /api/*
# - Frontend UI served at /
# - Health check at /api/health

resource "google_cloud_run_service" "app" {
  name     = "${var.project_prefix}-app"
  location = var.primary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-bundled:latest"

        env {
          name  = "PROJECT_ID"
          value = var.gcp_project_id
        }

        env {
          name  = "REGION"
          value = var.primary_region
        }

        env {
          name  = "ENVIRONMENT"
          value = "production"
        }

        env {
          name  = "FIRESTORE_DB"
          value = var.firestore_database_id
        }

        env {
          name  = "PUBSUB_PROJECT"
          value = var.gcp_project_id
        }

        env {
          name  = "PUBLIC_PATH"
          value = "/"
        }

        env {
          name  = "REACT_APP_ENVIRONMENT"
          value = "production"
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }

        ports {
          container_port = 8080
          name           = "http1"
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = var.cloud_run_max_instances
        "autoscaling.knative.dev/minScale" = 1
      }
      labels = { region = var.primary_region }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Allow public access to app (handled via load balancer with IAP)
# NOTE: Commented out due to organization policy restrictions
# Public access is handled via load balancer with IAP instead

/* resource "google_cloud_run_service_iam_member" "app_public_primary" {
  service  = google_cloud_run_service.app.name
  location = var.primary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
*/
