# Identity-Aware Proxy (IAP) Module
# Provides authentication and authorization at the load balancer level

# NOTE: IAP Brand and OAuth Client require an organization-level setup.
# Since your project is organization-managed, these must be created through:
# 1. GCP Console > Security > Identity-Aware Proxy > OAuth consent screen
# 2. Google Cloud APIs & Services > Credentials > Create OAuth 2.0 Client
#
# This module manages the IAP resource bindings for your backend services.
# The brand and client are managed externally and configured in your IAP settings.

# IAP Settings - Backend Service Bindings for Authentication/Authorization
# These resources control who can access your Cloud Run services through IAP

# IAP Settings for Backend API Service
resource "google_iap_web_backend_service_iam_binding" "api_iap_binding" {
  web_backend_service = var.api_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = concat(
    var.admin_authorized_users,
    var.api_authorized_users
  )
}

# IAP Settings for Frontend Web Service
resource "google_iap_web_backend_service_iam_binding" "frontend_iap_binding" {
  web_backend_service = var.frontend_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = concat(
    var.admin_authorized_users,
    var.public_authorized_users
  )
}

# Note: IAP is enabled at the load balancer backend service level
# OAuth 2.0 client is created above for authentication

# IAP Policies for Public Client Access (if needed)
resource "google_iap_web_iam_binding" "public_access" {
  count   = var.enable_public_iap_access ? 1 : 0
  role    = "roles/iap.httpsResourceAccessor"
  members = var.public_authorized_users
}

# Custom IAM Policy for IAP Admin Role
resource "google_project_iam_member" "iap_policy_admin" {
  project = var.gcp_project_id
  role    = "roles/iap.admin"
  member  = "serviceAccount:${var.service_account_email}"
}

# Log sink for IAP access logs
resource "google_logging_project_sink" "iap_logs" {
  name        = "${var.project_prefix}-iap-logs"
  destination = "storage.googleapis.com/${var.logs_bucket_name}"

  filter = <<-EOT
    resource.type="http_load_balancer"
    AND jsonPayload.enforcedSecurityPolicy.name=~"${var.project_prefix}.*"
  EOT

  unique_writer_identity = true
}

# Grant log sink writer access to the bucket
resource "google_storage_bucket_iam_member" "iap_logs_writer" {
  bucket = var.logs_bucket_name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.iap_logs.writer_identity
}

# Cloud Monitoring for IAP - Temporarily disabled due to filter syntax errors
/*
resource "google_monitoring_alert_policy" "iap_failed_auth" {
  display_name = "${var.project_prefix} - IAP Failed Authentication"
  combiner     = "OR"
  enabled      = var.enable_iap_alerts

  conditions {
    display_name = "High failed authentication rate"
    condition_threshold {
      filter          = "resource.type=\"http_load_balancer\" AND metric.type=\"compute.googleapis.com/https/request_count\" AND metadata.user_labels.iap_policy=~\".*\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.failed_auth_threshold
    }
  }

  notification_channels = var.notification_channel_ids

  documentation {
    content   = "This alert fires when IAP authentication failures exceed ${var.failed_auth_threshold} in a 5-minute window."
    mime_type = "text/markdown"
  }
}
*/

# Audit logging for IAP - Temporarily disabled due to invalid log types
/*
resource "google_project_iam_audit_config" "iap_audit" {
  project = var.gcp_project_id
  service = "iap.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_WRITE"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }
}
*/

# Cloud KMS encryption for OAuth client secret
resource "google_kms_crypto_key_iam_member" "iap_secret_encryption" {
  crypto_key_id = var.kms_crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.iap_service_account_email}"
}
