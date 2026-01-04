# Eventarc Module - Cloud Storage to Cloud Run Trigger
# Purpose: Trigger Cloud Run service when videos are uploaded to Cloud Storage

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Eventarc Trigger for Cloud Storage
# ============================================
# NOTE: Temporarily disabled until Cloud Run image is deployed and Eventarc matching criteria is verified
# Triggers Cloud Run service when videos are uploaded
# 
# To enable after Cloud Run deployment:
# 1. Deploy your Docker image to Artifact Registry
# 2. Run: tofu apply to deploy Cloud Run services
# 3. Uncomment the resource blocks below
# 4. Run: tofu apply again to enable Eventarc triggers

/*
resource "google_eventarc_trigger" "video_upload_trigger" {
  name            = "${var.project_prefix}-video-upload-trigger"
  location        = var.primary_region
  project         = var.gcp_project_id
  service_account = var.eventarc_service_account_email
  
  event_data_content_type = "application/json"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.videos_bucket_name
  }

  destination {
    cloud_run_service {
      service = var.cloud_run_service_name
      region  = var.primary_region
    }
  }
}

resource "google_eventarc_trigger" "video_upload_trigger_secondary" {
  count           = var.enable_secondary_region ? 1 : 0
  name            = "${var.project_prefix}-video-upload-trigger-secondary"
  location        = var.secondary_region
  project         = var.gcp_project_id
  service_account = var.eventarc_service_account_email
  
  event_data_content_type = "application/json"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.videos_bucket_name
  }

  destination {
    cloud_run_service {
      service = var.cloud_run_service_name_secondary
      region  = var.secondary_region
    }
  }
}
*/

