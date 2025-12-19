# Load Balancer Module - Outputs

output "global_ip_address" {
  value       = google_compute_global_address.lb_ip.address
  description = "Global load balancer IP address"
}

output "load_balancer_url" {
  value       = "https://${google_compute_global_address.lb_ip.address}"
  description = "Load balancer HTTPS URL"
}

output "backend_api_service_id" {
  value       = google_compute_backend_service.backend_api.id
  description = "Backend API service ID"
}

output "frontend_web_service_id" {
  value       = google_compute_backend_service.frontend_web.id
  description = "Frontend web service ID"
}

output "url_map_id" {
  value       = google_compute_url_map.default.id
  description = "URL map ID"
}

output "https_proxy_id" {
  value       = google_compute_target_https_proxy.default.id
  description = "HTTPS proxy ID"
}

output "ssl_certificate_id" {
  value       = google_compute_ssl_certificate.default.id
  description = "SSL certificate ID"
}

output "backend_primary_neg_id" {
  value       = google_compute_region_network_endpoint_group.backend_primary.id
  description = "Primary region backend serverless NEG ID"
}

output "backend_secondary_neg_id" {
  value       = google_compute_region_network_endpoint_group.backend_secondary.id
  description = "Secondary region backend serverless NEG ID"
}

output "frontend_primary_neg_id" {
  value       = google_compute_region_network_endpoint_group.frontend_primary.id
  description = "Primary region frontend serverless NEG ID"
}

output "frontend_secondary_neg_id" {
  value       = google_compute_region_network_endpoint_group.frontend_secondary.id
  description = "Secondary region frontend serverless NEG ID"
}
