# Compute Module - Unified Cloud Run API Service (Multi-Region)
# Purpose: Single Cloud Run service exposing all functions as REST APIs

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Unified Cloud Run Service - Primary Region
# ============================================
# Single service with all API functions:
# - /api/stream/process (Stream Processing)
# - /api/video/analyze (Video Analytics)
# - /api/users/* (User Management APIs)
# - /api/health (Health Check)

resource "google_cloud_run_service" "api_primary" {
  name     = "${var.project_prefix}-api"
  location = var.primary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "${var.primary_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-api:latest"

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

# Allow public access to unified API
resource "google_cloud_run_service_iam_member" "cloud_run_public_primary" {
  service  = google_cloud_run_service.api_primary.name
  location = var.primary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ============================================
# Unified Cloud Run Service - Secondary Region (EU)
# ============================================

resource "google_cloud_run_service" "api_secondary" {
  name     = "${var.project_prefix}-api-eu"
  location = var.secondary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "${var.secondary_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-api:latest"

        env {
          name  = "PROJECT_ID"
          value = var.gcp_project_id
        }

        env {
          name  = "REGION"
          value = var.secondary_region
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
      labels = merge({ region = var.secondary_region }, {})
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# Allow public access to unified API - Secondary Region
resource "google_cloud_run_service_iam_member" "cloud_run_public_secondary" {
  service  = google_cloud_run_service.api_secondary.name
  location = var.secondary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
