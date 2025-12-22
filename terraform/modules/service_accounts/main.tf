# Service Accounts Module - Defines all service accounts and their IAM roles

# ============================================
# Cloud Run Service Account
# ============================================

resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.project_prefix}-cloudrun-sa"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run services to access GCP resources"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "cloud_run_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_pubsub_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_firestore_user" {
  project = var.gcp_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_service_account_user" {
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