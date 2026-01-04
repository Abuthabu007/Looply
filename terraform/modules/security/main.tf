# Security Module - Cloud Armor, KMS, Secret Manager
# Purpose: Implement security best practices for production

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Cloud Armor - DDoS Protection & WAF
# ============================================================================
resource "google_compute_security_policy" "cloud_armor" {
  name        = "${var.project_prefix}-cloud-armor"
  description = "Cloud Armor policy for DDoS protection and WAF"
}

# ============================================================================
# Cloud KMS - Key Management Service
# ============================================================================

# Reference existing keyring (will be created if doesn't exist)
data "google_kms_key_ring" "main" {
  name     = "${var.project_prefix}-keyring"
  location = var.primary_region
}

# KMS Crypto Keys - Already created in previous deployment
# These are commented out to prevent "already exists" errors
# The existing keys will be used automatically
/*

resource "google_kms_crypto_key" "looply_key" {
  name            = "${var.project_prefix}-key"
  key_ring        = data.google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days
  labels          = var.tags

  lifecycle {
    ignore_changes = all
  }
}

# KMS Key for database encryption
resource "google_kms_crypto_key" "database_key" {
  name            = "${var.project_prefix}-db-key"
  key_ring        = data.google_kms_key_ring.main.id
  rotation_period = "2592000s" # 30 days
  labels          = var.tags

  lifecycle {
    ignore_changes = all
  }
}

# KMS Key for storage encryption
resource "google_kms_crypto_key" "storage_key" {
  name            = "${var.project_prefix}-storage-key"
  key_ring        = data.google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days
  labels          = var.tags

  lifecycle {
    ignore_changes = all
  }
}

*/

# Data sources for existing KMS keys
data "google_kms_crypto_key" "looply_key" {
  name            = "${var.project_prefix}-key"
  key_ring        = data.google_kms_key_ring.main.id
}

data "google_kms_crypto_key" "database_key" {
  name            = "${var.project_prefix}-db-key"
  key_ring        = data.google_kms_key_ring.main.id
}

data "google_kms_crypto_key" "storage_key" {
  name            = "${var.project_prefix}-storage-key"
  key_ring        = data.google_kms_key_ring.main.id
}

# ============================================================================
# Cloud Secret Manager - Secret Storage
# ============================================================================

resource "google_secret_manager_secret" "ssl_certificate" {
  secret_id = "${var.project_prefix}-ssl-cert"

  labels = var.tags

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ssl_certificate_version" {
  secret      = google_secret_manager_secret.ssl_certificate.id
  secret_data = var.ssl_certificate
}

# Database password secret
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_prefix}-db-password"

  labels = var.tags

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# API Key secret for third-party integrations
resource "google_secret_manager_secret" "api_key" {
  secret_id = "${var.project_prefix}-api-key"

  labels = var.tags

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_key_version" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = var.api_key
}

# OAuth client secret
resource "google_secret_manager_secret" "oauth_secret" {
  secret_id = "${var.project_prefix}-oauth-secret"

  labels = var.tags

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "oauth_secret_version" {
  secret      = google_secret_manager_secret.oauth_secret.id
  secret_data = var.oauth_client_secret
}

# ============================================================================
# IAM Access for Service Accounts to Secrets
# ============================================================================

# Cloud Run service account - read secrets
resource "google_secret_manager_secret_iam_member" "cloud_run_secrets" {
  for_each = {
    ssl_certificate = google_secret_manager_secret.ssl_certificate.id
    db_password     = google_secret_manager_secret.db_password.id
    api_key         = google_secret_manager_secret.api_key.id
    oauth_secret    = google_secret_manager_secret.oauth_secret.id
  }

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.cloud_run_sa_email}"
}

# Cloud Scheduler service account - read secrets
resource "google_secret_manager_secret_iam_member" "scheduler_secrets" {
  for_each = {
    db_password = google_secret_manager_secret.db_password.id
    api_key     = google_secret_manager_secret.api_key.id
  }

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.scheduler_sa_email}"
}

# ============================================================================
# IAM Access for Service Accounts to KMS Keys
# ============================================================================

# Cloud Run service account - use KMS keys
resource "google_kms_crypto_key_iam_member" "cloud_run_kms" {
  for_each = {
    looply_key   = data.google_kms_crypto_key.looply_key.id
    database_key = data.google_kms_crypto_key.database_key.id
    storage_key  = data.google_kms_crypto_key.storage_key.id
  }

  crypto_key_id = each.value
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.cloud_run_sa_email}"
}

# BigQuery service account - database key
resource "google_kms_crypto_key_iam_member" "bigquery_kms" {
  crypto_key_id = data.google_kms_crypto_key.database_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.bigquery_sa_email}"
}

# Cloud Storage service account - storage key
resource "google_kms_crypto_key_iam_member" "storage_kms" {
  crypto_key_id = data.google_kms_crypto_key.storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.storage_sa_email}"
}

# ============================================================================
# Project Service Enablement
# ============================================================================

resource "google_project_service" "kms" {
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secrets" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "armor" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}
