# Compute Module - Outputs

output "app_url" {
  value       = google_cloud_run_v2_service.app_primary.uri
  description = "Bundled Cloud Run app service URL (frontend + backend)"
}

output "app_name" {
  value       = google_cloud_run_v2_service.app_primary.name
  description = "Bundled Cloud Run app service name"
}

output "app_primary_url" {
  value       = google_cloud_run_v2_service.app_primary.uri
  description = "Primary region Cloud Run app service URL"
}

output "app_secondary_url" {
  value       = var.enable_secondary_region ? google_cloud_run_v2_service.app_secondary[0].uri : null
  description = "Secondary region Cloud Run app service URL"
}

output "app_endpoints" {
  value = {
    base_url      = google_cloud_run_v2_service.app_primary.uri
    health_check  = "${google_cloud_run_v2_service.app_primary.uri}/api/health"
    stream_api    = "${google_cloud_run_v2_service.app_primary.uri}/api/stream/process"
    video_api     = "${google_cloud_run_v2_service.app_primary.uri}/api/video/analyze"
    users_api     = "${google_cloud_run_v2_service.app_primary.uri}/api/users"
    frontend_ui   = "${google_cloud_run_v2_service.app_primary.uri}/"
  }
  description = "Bundled app endpoints for all functions"
}

output "app_service_account" {
  value       = google_cloud_run_v2_service.app_primary.template[0].service_account
  description = "Cloud Run service account"
}

output "app_labels" {
  value       = google_cloud_run_v2_service.app_primary.labels
  description = "Labels applied to Cloud Run service"
}