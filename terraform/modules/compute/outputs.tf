# Compute Module - Outputs

output "backend_primary_url" {
  value       = google_cloud_run_service.backend_primary.status[0].url
  description = "Primary region backend Cloud Run service URL"
}

output "backend_secondary_url" {
  value       = google_cloud_run_service.backend_secondary.status[0].url
  description = "Secondary region (EU) backend Cloud Run service URL"
}

output "frontend_primary_url" {
  value       = google_cloud_run_service.frontend_primary.status[0].url
  description = "Primary region frontend Cloud Run service URL"
}

output "frontend_secondary_url" {
  value       = google_cloud_run_service.frontend_secondary.status[0].url
  description = "Secondary region (EU) frontend Cloud Run service URL"
}

output "backend_primary_name" {
  value       = google_cloud_run_service.backend_primary.name
  description = "Primary region backend Cloud Run service name"
}

output "backend_secondary_name" {
  value       = google_cloud_run_service.backend_secondary.name
  description = "Secondary region backend Cloud Run service name"
}

output "frontend_primary_name" {
  value       = google_cloud_run_service.frontend_primary.name
  description = "Primary region frontend Cloud Run service name"
}

output "frontend_secondary_name" {
  value       = google_cloud_run_service.frontend_secondary.name
  description = "Secondary region frontend Cloud Run service name"
}

output "backend_api_endpoints" {
  value = {
    primary_url   = google_cloud_run_service.backend_primary.status[0].url
    secondary_url = google_cloud_run_service.backend_secondary.status[0].url
    health_check  = "${google_cloud_run_service.backend_primary.status[0].url}/api/health"
    stream_api    = "${google_cloud_run_service.backend_primary.status[0].url}/api/stream/process"
    video_api     = "${google_cloud_run_service.backend_primary.status[0].url}/api/video/analyze"
    users_api     = "${google_cloud_run_service.backend_primary.status[0].url}/api/users"
  }
  description = "Backend API endpoints for all functions"
}

output "frontend_endpoints" {
  value = {
    primary_url   = google_cloud_run_service.frontend_primary.status[0].url
    secondary_url = google_cloud_run_service.frontend_secondary.status[0].url
  }
  description = "Frontend web application endpoints"
}

output "backend_primary_revision" {
  value       = try(google_cloud_run_service.backend_primary.status[0].traffic[0].revision_name, "pending")
  description = "Primary region backend latest revision"
}

output "backend_secondary_revision" {
  value       = try(google_cloud_run_service.backend_secondary.status[0].traffic[0].revision_name, "pending")
  description = "Secondary region backend latest revision"
}

output "frontend_primary_revision" {
  value       = try(google_cloud_run_service.frontend_primary.status[0].traffic[0].revision_name, "pending")
  description = "Primary region frontend latest revision"
}

output "frontend_secondary_revision" {
  value       = try(google_cloud_run_service.frontend_secondary.status[0].traffic[0].revision_name, "pending")
  description = "Secondary region frontend latest revision"
}