# Compute Module - Cloud Run Services
# Optimized for Cloud Run with standardized structure

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Environment Variables Configuration
# ============================================

locals {
  common_environment_variables = [
    {
      name  = "PROJECT_ID"
      value = var.gcp_project_id
    },
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "FIRESTORE_DB"
      value = var.firestore_database_id
    },
    {
      name  = "FIRESTORE_PROJECT"
      value = var.gcp_project_id
    },
    {
      name  = "PUBSUB_PROJECT"
      value = var.gcp_project_id
    },
    {
      name  = "VIDEOS_BUCKET"
      value = var.videos_bucket_name
    },
    {
      name  = "TRANSCODED_BUCKET"
      value = var.transcoded_bucket_name
    },
    {
      name  = "TRANSCODER_TEMPLATE_HLS"
      value = var.transcoder_hls_template
    },
    {
      name  = "VIDEO_UPLOAD_TOPIC"
      value = var.video_upload_topic
    },
    {
      name  = "TRANSCODING_COMPLETE_TOPIC"
      value = var.transcoding_complete_topic
    },
    {
      name  = "PUBLIC_PATH"
      value = "/"
    },
    {
      name  = "REACT_APP_ENVIRONMENT"
      value = var.environment
    }
  ]

  primary_environment_variables = concat(local.common_environment_variables, [
    {
      name  = "REGION"
      value = var.primary_region
    }
  ])

  secondary_environment_variables = concat(local.common_environment_variables, [
    {
      name  = "REGION"
      value = var.secondary_region
    }
  ])
}

# ============================================
# Cloud Run Service - Primary Region
# ============================================

resource "google_cloud_run_v2_service" "app_primary" {
  name        = "${var.project_prefix}-app"
  location    = var.primary_region
  project     = var.gcp_project_id
  launch_stage = "GA"
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.cloud_run_service_account

    containers {
      image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-bundled:latest"

      dynamic "env" {
        for_each = local.primary_environment_variables
        content {
          name  = env.value.name
          value = env.value.value
        }
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

      startup_probe {
        initial_delay_seconds = 10
        period_seconds        = 3
        timeout_seconds       = 1
        failure_threshold     = 3

        http_get {
          path = "/api/health"
          port = 8080
        }
      }

      liveness_probe {
        period_seconds    = 10
        timeout_seconds   = 1
        failure_threshold = 3

        http_get {
          path = "/api/health"
          port = 8080
        }
      }
    }

    timeout_seconds = var.cloud_run_timeout

    max_instance_request_concurrency = var.cloud_run_max_concurrency
    service_binding {
      name = "load-balancer"
    }

    scaling {
      min_instance_count = 1
      max_instance_count = var.cloud_run_max_instances
    }
  }

  labels = merge(
    var.tags,
    {
      region      = var.primary_region
      environment = var.environment
    }
  )

  depends_on = []
}

# ============================================
# Cloud Run Service - Secondary Region
# ============================================

resource "google_cloud_run_v2_service" "app_secondary" {
  count       = var.enable_secondary_region ? 1 : 0
  name        = "${var.project_prefix}-app-secondary"
  location    = var.secondary_region
  project     = var.gcp_project_id
  launch_stage = "GA"
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = var.cloud_run_service_account

    containers {
      image = "us-central1-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo}/looply-bundled:latest"

      dynamic "env" {
        for_each = local.secondary_environment_variables
        content {
          name  = env.value.name
          value = env.value.value
        }
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

      startup_probe {
        initial_delay_seconds = 10
        period_seconds        = 3
        timeout_seconds       = 1
        failure_threshold     = 3

        http_get {
          path = "/api/health"
          port = 8080
        }
      }

      liveness_probe {
        period_seconds    = 10
        timeout_seconds   = 1
        failure_threshold = 3

        http_get {
          path = "/api/health"
          port = 8080
        }
      }
    }

    timeout_seconds = var.cloud_run_timeout

    max_instance_request_concurrency = var.cloud_run_max_concurrency
    service_binding {
      name = "load-balancer"
    }

    scaling {
      min_instance_count = 1
      max_instance_count = var.cloud_run_max_instances
    }
  }

  labels = merge(
    var.tags,
    {
      region      = var.secondary_region
      environment = var.environment
    }
  )

  depends_on = []
}
