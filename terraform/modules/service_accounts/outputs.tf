# Service Accounts Module - Outputs

output "cloud_run_service_account_email" {
  value       = google_service_account.cloud_run_sa.email
  description = "Cloud Run service account email"
}

output "pubsub_service_account_email" {
  value       = google_service_account.pubsub_sa.email
  description = "Pub/Sub service account email"
}

output "bigquery_service_account_email" {
  value       = google_service_account.bigquery_sa.email
  description = "BigQuery service account email"
}

output "firestore_service_account_email" {
  value       = google_service_account.firestore_sa.email
  description = "Firestore service account email"
}

output "storage_service_account_email" {
  value       = google_service_account.storage_sa.email
  description = "Cloud Storage service account email"
}

output "cloud_scheduler_service_account_email" {
  value       = google_service_account.cloud_scheduler_sa.email
  description = "Cloud Scheduler service account email"
}

output "artifact_registry_service_account_email" {
  value       = google_service_account.artifact_registry_sa.email
  description = "Artifact Registry service account email"
}
output "iap_service_account_email" {
  value       = google_service_account.iap_sa.email
  description = "IAP (Identity-Aware Proxy) service account email"
}