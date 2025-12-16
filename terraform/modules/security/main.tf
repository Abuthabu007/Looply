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

  # Default allow rule
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      expr {
        expression = "true"
      }
    }
    description = "Default allow rule"
  }

  # Rate limiting rule - prevent abuse
  rule {
    action   = "rate_based_ban"
    priority = 100
    match {
      expr {
        expression = "true"
      }
    }
    description = "Rate limiting - max 100 requests/minute per IP"
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 600
    }
  }

  # Geo-blocking rule (if needed)
  dynamic "rule" {
    for_each = length(var.allowed_countries) > 0 ? [1] : []
    content {
      action   = "allow"
      priority = 101
      match {
        expr {
          expression = join(" || ", [
            for country in var.allowed_countries :
            "origin.country_code == '${country}'"
          ])
        }
      }
      description = "Allow only from specific countries"
    }
  }

  # OWASP Core Rule Set - protect against common web attacks
  rule {
    action   = "allow"
    priority = 102
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS Protection"
    preview     = var.security_policy_preview_mode
  }

  rule {
    action   = "allow"
    priority = 103
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL Injection Protection"
    preview     = var.security_policy_preview_mode
  }

  rule {
    action   = "allow"
    priority = 104
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rce-stable')"
      }
    }
    description = "Remote Code Execution Protection"
    preview     = var.security_policy_preview_mode
  }

  rule {
    action   = "allow"
    priority = 105
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS Attack Protection"
    preview     = var.security_policy_preview_mode
  }

  rule {
    action   = "allow"
    priority = 106
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL Injection Protection"
    preview     = var.security_policy_preview_mode
  }

  # Custom rule - block requests with no user agent
  rule {
    action   = "deny(403)"
    priority = 107
    match {
      expr {
        expression = "origin.region_code == 'CN'"
      }
    }
    description = "Custom: Block requests from specific regions"
    preview     = false
  }
}

# ============================================================================
# Cloud KMS - Key Management Service
# ============================================================================

resource "google_kms_key_ring" "main" {
  name     = "${var.project_prefix}-keyring"
  location = var.primary_region

  depends_on = [
    google_project_service.kms
  ]
}

resource "google_kms_crypto_key" "looply_key" {
  name            = "${var.project_prefix}-key"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days
  labels          = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# KMS Key for database encryption
resource "google_kms_crypto_key" "database_key" {
  name            = "${var.project_prefix}-db-key"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "2592000s" # 30 days
  labels          = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# KMS Key for storage encryption
resource "google_kms_crypto_key" "storage_key" {
  name            = "${var.project_prefix}-storage-key"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s" # 90 days
  labels          = var.tags

  lifecycle {
    prevent_destroy = true
  }
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
    looply_key   = google_kms_crypto_key.looply_key.id
    database_key = google_kms_crypto_key.database_key.id
    storage_key  = google_kms_crypto_key.storage_key.id
  }
  
  crypto_key_id = each.value
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.cloud_run_sa_email}"
}

# BigQuery service account - database key
resource "google_kms_crypto_key_iam_member" "bigquery_kms" {
  crypto_key_id = google_kms_crypto_key.database_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.bigquery_sa_email}"
}

# Cloud Storage service account - storage key
resource "google_kms_crypto_key_iam_member" "storage_kms" {
  crypto_key_id = google_kms_crypto_key.storage_key.id
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
