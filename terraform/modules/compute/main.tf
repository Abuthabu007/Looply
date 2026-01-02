# Compute Module - Cloud Run Services (Frontend & Backend - Multi-Region)
# Purpose: Separate Cloud Run services for frontend (UI) and backend (API)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Backend Cloud Run Service - Primary Region
# ============================================
# Backend API service with all functions:
# - /api/stream/process (Stream Processing)
# - /api/video/analyze (Video Analytics)
# - /api/users/* (User Management APIs)
# - /api/health (Health Check)

resource "google_cloud_run_service" "backend_primary" {
  name     = "${var.project_prefix}-backend"
  location = var.primary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/backend:latest"

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
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Allow public access to backend
# NOTE: Commented out due to organization policy restrictions
# Public access is handled via load balancer instead

/* resource "google_cloud_run_service_iam_member" "backend_public_primary" {
  service  = google_cloud_run_service.backend_primary.name
  location = var.primary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
*/

# ============================================
# Frontend Cloud Run Service - Primary Region
# ============================================
# Frontend service (UI/Web App)

resource "google_cloud_run_service" "frontend_primary" {
  name     = "${var.project_prefix}-frontend"
  location = var.primary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looplysingle:latest"

        env {
          name  = "REACT_APP_API_URL"
          value = "https://${var.project_prefix}-backend-${var.primary_region}.run.app"
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

# Allow public access to frontend
# NOTE: Commented out due to organization policy restrictions
# Public access is handled via load balancer instead

/*resource "google_cloud_run_service_iam_member" "frontend_public_primary" {
  service  = google_cloud_run_service.frontend_primary.name
  location = var.primary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
*/

# ============================================
# Backend Cloud Run Service - Secondary Region (EU)
# ============================================

resource "google_cloud_run_service" "backend_secondary" {
  name     = "${var.project_prefix}-backend-eu"
  location = var.secondary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/backend:latest"

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

        env {
          name  = "PUBLIC_PATH"
          value = "/"
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
      labels = { region = var.secondary_region }
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

# Allow public access to backend - Secondary Region
# NOTE: Commented out due to organization policy restrictions
# Public access is handled via load balancer instead

/*resource "google_cloud_run_service_iam_member" "backend_public_secondary" {
  service  = google_cloud_run_service.backend_secondary.name
  location = var.secondary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}*/


# ============================================
# Frontend Cloud Run Service - Secondary Region (EU)
# ============================================

resource "google_cloud_run_service" "frontend_secondary" {
  name     = "${var.project_prefix}-frontend-eu"
  location = var.secondary_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = var.cloud_run_service_account
      timeout_seconds      = var.cloud_run_timeout

      containers {
        image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/frontend:latest"

        env {
          name  = "REACT_APP_API_URL"
          value = "https://${var.project_prefix}-backend-eu-${var.secondary_region}.run.app"
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
      labels = { region = var.secondary_region }
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

# Allow public access to frontend - Secondary Region
/*resource "google_cloud_run_service_iam_member" "frontend_public_secondary" {
  service  = google_cloud_run_service.frontend_secondary.name
  location = var.secondary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}*/
