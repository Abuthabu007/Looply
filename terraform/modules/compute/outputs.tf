# Compute Module - Outputs

output "app_url" {
  value       = google_cloud_run_service.app.status[0].url
  description = "Bundled Cloud Run app service URL (frontend + backend)"
}

output "app_name" {
  value       = google_cloud_run_service.app.name
  description = "Bundled Cloud Run app service name"
}

output "app_endpoints" {
  value = {
    base_url      = google_cloud_run_service.app.status[0].url
    health_check  = "${google_cloud_run_service.app.status[0].url}/api/health"
    stream_api    = "${google_cloud_run_service.app.status[0].url}/api/stream/process"
    video_api     = "${google_cloud_run_service.app.status[0].url}/api/video/analyze"
    users_api     = "${google_cloud_run_service.app.status[0].url}/api/users"
    frontend_ui   = "${google_cloud_run_service.app.status[0].url}/"
  }
  description = "Bundled app endpoints for all functions"
}

output "app_revision" {
  value       = try(google_cloud_run_service.app.status[0].traffic[0].revision_name, "pending")
  description = "Bundled app latest revision"
}