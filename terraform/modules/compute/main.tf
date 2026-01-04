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
# Cloud Run Service - Primary Region
# ============================================
# Handles:
# - Frontend UI served at /
# - Backend API endpoints at /api/*
# - Health check at /api/health
# - Video processing via Eventarc integration
# - Firestore client-side access

resource "google_cloud_run_service" "app_primary" {
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
          name  = "FIRESTORE_PROJECT"
          value = var.gcp_project_id
        }

        env {
          name  = "PUBSUB_PROJECT"
          value = var.gcp_project_id
        }

        env {
          name  = "VIDEOS_BUCKET"
          value = var.videos_bucket_name
        }

        env {
          name  = "TRANSCODED_BUCKET"
          value = var.transcoded_bucket_name
        }

        env {
          name  = "TRANSCODER_TEMPLATE_HLS"
          value = var.transcoder_hls_template
        }

        env {
          name  = "VIDEO_UPLOAD_TOPIC"
          value = var.video_upload_topic
        }

        env {
          name  = "TRANSCODING_COMPLETE_TOPIC"
          value = var.transcoding_complete_topic
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
        "run.googleapis.com/cloudsql-instances" = ""
      }
      labels = { 
        region = var.primary_region
        env    = "production"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    # Wait for API enablement and networking to be ready
  ]
}

# ============================================
# Cloud Run Service - Secondary Region
# ============================================

resource "google_cloud_run_service" "app_secondary" {
  count    = var.enable_secondary_region ? 1 : 0
  name     = "${var.project_prefix}-app-secondary"
  location = var.secondary_region
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
          name  = "FIRESTORE_PROJECT"
          value = var.gcp_project_id
        }

        env {
          name  = "PUBSUB_PROJECT"
          value = var.gcp_project_id
        }

        env {
          name  = "VIDEOS_BUCKET"
          value = var.videos_bucket_name
        }

        env {
          name  = "TRANSCODED_BUCKET"
          value = var.transcoded_bucket_name
        }

        env {
          name  = "TRANSCODER_TEMPLATE_HLS"
          value = var.transcoder_hls_template
        }

        env {
          name  = "VIDEO_UPLOAD_TOPIC"
          value = var.video_upload_topic
        }

        env {
          name  = "TRANSCODING_COMPLETE_TOPIC"
          value = var.transcoding_complete_topic
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
      labels = { 
        region = var.secondary_region
        env    = "production"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
# Public access is handled via load balancer with IAP instead

/* resource "google_cloud_run_service_iam_member" "app_public_primary" {
  service  = google_cloud_run_service.app.name
  location = var.primary_region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
*/
