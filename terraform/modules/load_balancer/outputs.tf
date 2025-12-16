# Load Balancer Module - Outputs

output "global_ip_address" {
  value       = google_compute_global_address.lb_ip.address
  description = "Global load balancer IP address"
}

output "load_balancer_url" {
  value       = "https://${google_compute_global_address.lb_ip.address}"
  description = "Load balancer HTTPS URL"
}

output "backend_service_id" {
  value       = google_compute_backend_service.default.id
  description = "Backend service ID"
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

output "primary_neg_id" {
  value       = google_compute_region_network_endpoint_group.cloud_run_primary.id
  description = "Primary region serverless NEG ID"
}

output "secondary_neg_id" {
  value       = google_compute_region_network_endpoint_group.cloud_run_secondary.id
  description = "Secondary region serverless NEG ID"
}
