# Identity-Aware Proxy (IAP) Module
# Provides authentication and authorization at the load balancer level

# OAuth 2.0 Client for IAP
resource "google_iap_client" "project_client" {
  display_name = "${var.project_prefix}-iap-client"
  brand         = google_iap_brand.project_brand.name
}

# IAP Brand (OAuth Consent Screen)
resource "google_iap_brand" "project_brand" {
  # support_email     = var.support_email
  application_title = var.application_title
  project           = var.gcp_project_id
}

# IAP Settings for Backend Service (Admin Panel)
resource "google_iap_web_backend_service_iam_binding" "admin_iap_binding" {
  web_backend_service = var.admin_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = var.admin_authorized_users

  depends_on = [google_iap_client.project_client]
}

# IAP Settings for Backend Service (User Management API)
resource "google_iap_web_backend_service_iam_binding" "user_mgmt_iap_binding" {
  web_backend_service = var.user_management_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = var.user_management_authorized_users

  depends_on = [google_iap_client.project_client]
}

# IAP Settings for Backend Service (Analytics Dashboard)
resource "google_iap_web_backend_service_iam_binding" "analytics_iap_binding" {
  web_backend_service = var.analytics_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  members             = var.analytics_authorized_users

  depends_on = [google_iap_client.project_client]
}

# Note: IAP is enabled at the load balancer backend service level
# OAuth 2.0 client is created above for authentication

# IAP Policies for Public Client Access (if needed)
resource "google_iap_web_iam_binding" "public_access" {
  count   = var.enable_public_iap_access ? 1 : 0
  role    = "roles/iap.httpsResourceAccessor"
  members = var.public_authorized_users

  depends_on = [google_iap_client.project_client]
}

# Custom IAM Policy for IAP Admin Role
resource "google_project_iam_member" "iap_policy_admin" {
  project = var.gcp_project_id
  role    = "roles/iap.admin"
  member  = "serviceAccount:${var.service_account_email}"

  depends_on = [google_iap_client.project_client]
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

# Cloud Monitoring for IAP
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

# Audit logging for IAP
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

# Cloud KMS encryption for OAuth client secret
resource "google_kms_crypto_key_iam_member" "iap_secret_encryption" {
  crypto_key_id = var.kms_crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.iap_service_account_email}"
}
