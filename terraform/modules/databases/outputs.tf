# Databases Module - Outputs

output "firestore_database_id" {
  value       = google_firestore_database.main.name
  description = "Firestore database ID"
}

output "bigquery_dataset_id" {
  value       = google_bigquery_dataset.analytics.dataset_id
  description = "BigQuery dataset ID"
}

output "bigquery_dataset_project" {
  value       = google_bigquery_dataset.analytics.project
  description = "BigQuery dataset project"
}

output "stream_events_table_id" {
  value       = google_bigquery_table.stream_events.table_id
  description = "Stream events table ID"
}

output "user_analytics_table_id" {
  value       = google_bigquery_table.user_analytics.table_id
  description = "User analytics table ID"
}

output "stream_quality_table_id" {
  value       = google_bigquery_table.stream_quality.table_id
  description = "Stream quality table ID"
}
