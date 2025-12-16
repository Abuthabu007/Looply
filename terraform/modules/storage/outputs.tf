# Storage Module - Outputs

output "videos_bucket_name" {
  value       = google_storage_bucket.videos.name
  description = "Videos bucket name"
}

output "videos_bucket_url" {
  value       = "gs://${google_storage_bucket.videos.name}"
  description = "Videos bucket URL"
}

output "analytics_bucket_name" {
  value       = google_storage_bucket.analytics.name
  description = "Analytics bucket name"
}

output "analytics_bucket_url" {
  value       = "gs://${google_storage_bucket.analytics.name}"
  description = "Analytics bucket URL"
}

output "logs_bucket_name" {
  value       = google_storage_bucket.logs.name
  description = "Logs bucket name"
}

output "logs_bucket_url" {
  value       = "gs://${google_storage_bucket.logs.name}"
  description = "Logs bucket URL"
}

output "backup_bucket_name" {
  value       = google_storage_bucket.backup.name
  description = "Backup bucket name"
}

output "backup_bucket_url" {
  value       = "gs://${google_storage_bucket.backup.name}"
  description = "Backup bucket URL"
}
