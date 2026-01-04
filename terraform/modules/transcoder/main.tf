# Transcoder Module - Cloud Video Transcoder API Integration
# Purpose: Enable transcoding API and manage template references

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Enable Transcoder API
# ============================================

resource "google_project_service" "transcoder_api" {
  service            = "transcoder.googleapis.com"
  project            = var.gcp_project_id
  disable_on_destroy = false
}

# ============================================
# Template ID References
# ============================================
# Job templates should be created manually via gcloud CLI
# This module provides the template IDs for use in Cloud Run applications
#
# To create the templates, use these gcloud commands:
#
# HLS Adaptive Bitrate Template:
# gcloud transcoder templates create hls_adaptive \
#   --location=us-central1 \
#   --input-bucket-name=looply-videos-looply-482917 \
#   --output-bucket-name=looply-transcoded-looply-482917
#
# MP4 Single Quality Template:
# gcloud transcoder templates create mp4_single \
#   --location=us-central1 \
#   --input-bucket-name=looply-videos-looply-482917 \
#   --output-bucket-name=looply-transcoded-looply-482917

locals {
  hls_template_id = "projects/${var.gcp_project_id}/locations/${var.primary_region}/jobTemplates/hls_adaptive"
  mp4_template_id = "projects/${var.gcp_project_id}/locations/${var.primary_region}/jobTemplates/mp4_single"
}
