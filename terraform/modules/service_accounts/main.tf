# Service Accounts Module
# Manages all service accounts and their IAM role assignments
# Following Google Cloud best practices with modular design

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Service Accounts Configuration
# ============================================

locals {
  service_accounts = {
    cloud_run = {
      account_id   = "${var.project_prefix}-cloudrun-sa"
      display_name = "Cloud Run Service Account"
      description  = "Service account for Cloud Run services"
      roles = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/pubsub.publisher",
        "roles/pubsub.subscriber",
        "roles/datastore.user",
        "roles/storage.objectAdmin",
        "roles/iam.serviceAccountTokenCreator",
        "roles/artifactregistry.reader"
      ]
    }
    pubsub = {
      account_id   = "${var.project_prefix}-pubsub-sa"
      display_name = "Pub/Sub Service Account"
      description  = "Service account for Pub/Sub message processing"
      roles = [
        "roles/pubsub.editor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }
    bigquery = {
      account_id   = "${var.project_prefix}-bigquery-sa"
      display_name = "BigQuery Service Account"
      description  = "Service account for BigQuery operations"
      roles = [
        "roles/bigquery.admin",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }
    firestore = {
      account_id   = "${var.project_prefix}-firestore-sa"
      display_name = "Firestore Service Account"
      description  = "Service account for Firestore operations"
      roles = [
        "roles/datastore.user",
        "roles/logging.logWriter"
      ]
    }
    storage = {
      account_id   = "${var.project_prefix}-storage-sa"
      display_name = "Cloud Storage Service Account"
      description  = "Service account for Cloud Storage operations"
      roles = [
        "roles/storage.objectAdmin",
        "roles/logging.logWriter"
      ]
    }
    scheduler = {
      account_id   = "${var.project_prefix}-scheduler-sa"
      display_name = "Cloud Scheduler Service Account"
      description  = "Service account for Cloud Scheduler jobs"
      roles = [
        "roles/run.invoker",
        "roles/logging.logWriter"
      ]
    }
    artifact_registry = {
      account_id   = "${var.project_prefix}-artifact-registry-sa"
      display_name = "Artifact Registry Service Account"
      description  = "Service account for Artifact Registry management"
      roles = [
        "roles/artifactregistry.admin",
        "roles/logging.logWriter"
      ]
    }
    iap = {
      account_id   = "${var.project_prefix}-iap-sa"
      display_name = "IAP Service Account"
      description  = "Service account for Identity-Aware Proxy (IAP) operations"
      roles = [
        "roles/iap.admin",
        "roles/iap.httpsResourceAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/cloudkms.cryptoKeyEncrypterDecrypter"
      ]
    }
    load_balancer = {
      account_id   = "${var.project_prefix}-loadbalancer-sa"
      display_name = "Load Balancer Service Account"
      description  = "Service account for load balancer operations and IAP"
      roles = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/secretmanager.secretAccessor"
      ]
    }
    eventarc = {
      account_id   = "${var.project_prefix}-eventarc-sa"
      display_name = "Eventarc Service Account"
      description  = "Service account for Eventarc to invoke Cloud Run services"
      roles = [
        "roles/run.invoker",
        "roles/pubsub.publisher",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
    }
    transcoder = {
      account_id   = "${var.project_prefix}-transcoder-sa"
      display_name = "Cloud Transcoder Service Account"
      description  = "Service account for Cloud Transcoder operations"
      roles = [
        "roles/transcoder.admin",
        "roles/storage.objectAdmin",
        "roles/logging.logWriter"
      ]
    }
  }
}

# ============================================
# Create Service Accounts
# ============================================

resource "google_service_account" "service_accounts" {
  for_each = local.service_accounts

  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.gcp_project_id
}

# ============================================
# Assign IAM Roles to Service Accounts
# ============================================

resource "google_project_iam_member" "service_account_roles" {
  for_each = merge([
    for sa_name, sa_config in local.service_accounts : {
      for role in sa_config.roles :
      "${sa_name}-${role}" => {
        sa_email = google_service_account.service_accounts[sa_name].email
        role     = role
      }
    }
  ]...)

  project = var.gcp_project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.sa_email}"
}
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Custom role binding for signBlob permission on the service account itself
resource "google_service_account_iam_member" "cloud_run_sign_blob" {
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# ============================================
# Pub/Sub Service Account
# ============================================

resource "google_service_account" "pubsub_sa" {
  account_id   = "${var.project_prefix}-pubsub-sa"
  display_name = "Pub/Sub Service Account"
  description  = "Service account for Pub/Sub message processing"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "pubsub_editor" {
  project = var.gcp_project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.pubsub_sa.email}"
}

resource "google_project_iam_member" "pubsub_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.pubsub_sa.email}"
}

# ============================================
# BigQuery Service Account
# ============================================

resource "google_service_account" "bigquery_sa" {
  account_id   = "${var.project_prefix}-bigquery-sa"
  display_name = "BigQuery Service Account"
  description  = "Service account for BigQuery data operations"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "bigquery_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.bigquery_sa.email}"
}

resource "google_project_iam_member" "bigquery_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bigquery_sa.email}"
}

# ============================================
# Firestore Service Account
# ============================================

resource "google_service_account" "firestore_sa" {
  account_id   = "${var.project_prefix}-firestore-sa"
  display_name = "Firestore Service Account"
  description  = "Service account for Firestore operations"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "firestore_user" {
  project = var.gcp_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.firestore_sa.email}"
}

resource "google_project_iam_member" "firestore_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.firestore_sa.email}"
}

# ============================================
# Cloud Storage Service Account
# ============================================

resource "google_service_account" "storage_sa" {
  account_id   = "${var.project_prefix}-storage-sa"
  display_name = "Cloud Storage Service Account"
  description  = "Service account for Cloud Storage operations"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.storage_sa.email}"
}

resource "google_project_iam_member" "storage_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.storage_sa.email}"
}

# ============================================
# Cloud Scheduler Service Account
# ============================================

resource "google_service_account" "cloud_scheduler_sa" {
  account_id   = "${var.project_prefix}-scheduler-sa"
  display_name = "Cloud Scheduler Service Account"
  description  = "Service account for Cloud Scheduler jobs"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "cloud_scheduler_run_invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_scheduler_sa.email}"
}

# ============================================
# Artifact Registry Service Account
# ============================================

resource "google_service_account" "artifact_registry_sa" {
  account_id   = "${var.project_prefix}-artifact-registry-sa"
  display_name = "Artifact Registry Service Account"
  description  = "Service account for managing container images"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "artifact_registry_admin" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.artifact_registry_sa.email}"
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
# ============================================
# IAP Service Account
# ============================================

resource "google_service_account" "iap_sa" {
  account_id   = "${var.project_prefix}-iap-sa"
  display_name = "IAP Service Account"
  description  = "Service account for Identity-Aware Proxy (IAP) operations"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "iap_admin" {
  project = var.gcp_project_id
  role    = "roles/iap.admin"
  member  = "serviceAccount:${google_service_account.iap_sa.email}"
}

resource "google_project_iam_member" "iap_https_resource_accessor" {
  project = var.gcp_project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "serviceAccount:${google_service_account.iap_sa.email}"
}

resource "google_project_iam_member" "iap_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.iap_sa.email}"
}

resource "google_project_iam_member" "iap_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.iap_sa.email}"
}

resource "google_project_iam_member" "iap_kms_user" {
  project = var.gcp_project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_service_account.iap_sa.email}"
}

# ============================================
# Load Balancer Service Account
# ============================================

resource "google_service_account" "load_balancer_sa" {
  account_id   = "${var.project_prefix}-loadbalancer-sa"
  display_name = "Load Balancer Service Account"
  description  = "Service account for load balancer operations and IAP secret access"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "load_balancer_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.load_balancer_sa.email}"
}

resource "google_project_iam_member" "load_balancer_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.load_balancer_sa.email}"
}

resource "google_project_iam_member" "load_balancer_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.load_balancer_sa.email}"
}

# ============================================
# Eventarc Service Account
# ============================================

resource "google_service_account" "eventarc_sa" {
  account_id   = "${var.project_prefix}-eventarc-sa"
  display_name = "Eventarc Service Account"
  description  = "Service account for Eventarc to invoke Cloud Run services"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "eventarc_run_invoker" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

resource "google_project_iam_member" "eventarc_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

resource "google_project_iam_member" "eventarc_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

resource "google_project_iam_member" "eventarc_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# ============================================
# Cloud Transcoder Service Account
# ============================================

resource "google_service_account" "transcoder_sa" {
  account_id   = "${var.project_prefix}-transcoder-sa"
  display_name = "Cloud Transcoder Service Account"
  description  = "Service account for Cloud Video Transcoder operations"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "transcoder_editor" {
  project = var.gcp_project_id
  role    = "roles/transcoder.admin"
  member  = "serviceAccount:${google_service_account.transcoder_sa.email}"
}

resource "google_project_iam_member" "transcoder_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.transcoder_sa.email}"
}

resource "google_project_iam_member" "transcoder_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.transcoder_sa.email}"
}

resource "google_project_iam_member" "transcoder_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.transcoder_sa.email}"
}

# Also add transcoder permissions to Cloud Run SA so it can invoke transcoder jobs
resource "google_project_iam_member" "cloud_run_transcoder_admin" {
  project = var.gcp_project_id
  role    = "roles/transcoder.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}