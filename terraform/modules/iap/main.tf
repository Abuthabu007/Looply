# Identity-Aware Proxy (IAP) Module
# Provides authentication and authorization at the load balancer level
# Works with a single bundled Cloud Run service (frontend + backend)

# NOTE: IAP Brand and OAuth Client require an organization-level setup.
# Since your project is organization-managed, these must be created through:
# 1. GCP Console > Security > Identity-Aware Proxy > OAuth consent screen
# 2. Google Cloud APIs & Services > Credentials > Create OAuth 2.0 Client
#
# This module manages the IAP resource bindings for your bundled app service.
# The brand and client are managed externally and configured in your IAP settings.

# ============================================
# OAuth 2.0 Client Secret in Secret Manager
# ============================================

resource "google_secret_manager_secret" "oauth_client_secret" {
  secret_id = "${var.project_prefix}-iap-oauth-secret"
  project   = var.gcp_project_id

  labels = {
    component = "iap"
    managed   = "terraform"
  }

  replication {
    auto {}
  }
}

# Grant the load balancer service account access to the secret
resource "google_secret_manager_secret_iam_member" "oauth_secret_accessor" {
  secret_id = google_secret_manager_secret.oauth_client_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.load_balancer_service_account_email}"
}

# ============================================
# IAP Settings - Bundled App Service Bindings
# ============================================

# IAP Settings for Bundled App Service
resource "google_iap_web_backend_service_iam_binding" "app_iap_binding" {
  web_backend_service = var.app_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = concat(
    var.admin_authorized_users,
    var.api_authorized_users,
    var.public_authorized_users
  )
}

# ============================================
# Log Sink for IAP Access Logs
# ============================================

resource "google_logging_project_sink" "iap_logs" {
  name        = "${var.project_prefix}-iap-logs"
  destination = "storage.googleapis.com/${var.logs_bucket_name}"
  project     = var.gcp_project_id

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

# ============================================
# IAM Policy Admin Role for Service Account
# ============================================

resource "google_project_iam_member" "iap_policy_admin" {
  project = var.gcp_project_id
  role    = "roles/iap.admin"
  member  = "serviceAccount:${var.service_account_email}"
}

# ============================================
# Cloud KMS Encryption for OAuth Client Secret
# ============================================

resource "google_kms_crypto_key_iam_member" "iap_secret_encryption" {
  crypto_key_id = var.kms_crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.iap_service_account_email}"
}
