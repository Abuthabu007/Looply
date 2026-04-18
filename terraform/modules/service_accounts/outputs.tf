# Service Accounts Module - Outputs

output "service_accounts" {
  value = {
    for name, sa in google_service_account.service_accounts :
    name => {
      email = sa.email
      name  = sa.display_name
    }
  }
  description = "All created service accounts with their emails"
}

output "cloud_run_service_account_email" {
  value       = google_service_account.service_accounts["cloud_run"].email
  description = "Cloud Run service account email"
}

output "pubsub_service_account_email" {
  value       = google_service_account.service_accounts["pubsub"].email
  description = "Pub/Sub service account email"
}

output "bigquery_service_account_email" {
  value       = google_service_account.service_accounts["bigquery"].email
  description = "BigQuery service account email"
}

output "firestore_service_account_email" {
  value       = google_service_account.service_accounts["firestore"].email
  description = "Firestore service account email"
}

output "storage_service_account_email" {
  value       = google_service_account.service_accounts["storage"].email
  description = "Cloud Storage service account email"
}

output "scheduler_service_account_email" {
  value       = google_service_account.service_accounts["scheduler"].email
  description = "Cloud Scheduler service account email"
}

output "artifact_registry_service_account_email" {
  value       = google_service_account.service_accounts["artifact_registry"].email
  description = "Artifact Registry service account email"
}

output "iap_service_account_email" {
  value       = google_service_account.service_accounts["iap"].email
  description = "IAP (Identity-Aware Proxy) service account email"
}

output "load_balancer_service_account_email" {
  value       = google_service_account.service_accounts["load_balancer"].email
  description = "Load Balancer service account email"
}

output "eventarc_service_account_email" {
  value       = google_service_account.service_accounts["eventarc"].email
  description = "Eventarc service account email"
}

output "transcoder_service_account_email" {
  value       = google_service_account.service_accounts["transcoder"].email
  description = "Cloud Transcoder service account email"
}

output "transcoder_service_account_email" {
  value       = google_service_account.transcoder_sa.email
  description = "Cloud Transcoder service account email"
}
