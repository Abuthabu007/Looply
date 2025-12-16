# Compute Module - Outputs

output "cloud_run_primary_service_url" {
  value       = google_cloud_run_service.api_primary.status[0].url
  description = "Primary region unified Cloud Run API service URL"
}

output "cloud_run_secondary_service_url" {
  value       = google_cloud_run_service.api_secondary.status[0].url
  description = "Secondary region (EU) unified Cloud Run API service URL"
}

output "cloud_run_primary_service_name" {
  value       = google_cloud_run_service.api_primary.name
  description = "Primary region Cloud Run service name"
}

output "cloud_run_secondary_service_name" {
  value       = google_cloud_run_service.api_secondary.name
  description = "Secondary region Cloud Run service name"
}

output "cloud_run_api_endpoints" {
  value = {
    primary_url  = google_cloud_run_service.api_primary.status[0].url
    secondary_url = google_cloud_run_service.api_secondary.status[0].url
    health_check = "${google_cloud_run_service.api_primary.status[0].url}/api/health"
    stream_api   = "${google_cloud_run_service.api_primary.status[0].url}/api/stream/process"
    video_api    = "${google_cloud_run_service.api_primary.status[0].url}/api/video/analyze"
    users_api    = "${google_cloud_run_service.api_primary.status[0].url}/api/users"
  }
  description = "Unified API endpoints for all functions"
}

output "cloud_run_primary_revision" {
  value       = try(google_cloud_run_service.api_primary.status[0].traffic[0].revision_name, "pending")
  description = "Primary region latest revision"
}

output "cloud_run_secondary_revision" {
  value       = try(google_cloud_run_service.api_secondary.status[0].traffic[0].revision_name, "pending")
  description = "Secondary region latest revision"
}