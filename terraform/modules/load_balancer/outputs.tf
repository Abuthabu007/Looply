# Load Balancer Module - Outputs

output "global_ip_address" {
  value       = google_compute_global_address.lb_ip.address
  description = "Global load balancer IP address"
}

output "load_balancer_https_url" {
  value       = "https://${google_compute_global_address.lb_ip.address}"
  description = "Load balancer HTTPS URL"
}

output "load_balancer_http_url" {
  value       = "http://${google_compute_global_address.lb_ip.address}"
  description = "Load balancer HTTP URL (redirects to HTTPS)"
}

output "backend_service_id" {
  value       = google_compute_backend_service.app_service.id
  description = "Backend service ID"
}

output "backend_service_name" {
  value       = google_compute_backend_service.app_service.name
  description = "Backend service name"
}

output "url_map_id" {
  value       = google_compute_url_map.default.id
  description = "URL map ID"
}

output "https_proxy_id" {
  value       = google_compute_target_https_proxy.default.id
  description = "HTTPS target proxy ID"
}

output "ssl_certificate_id" {
  value       = google_compute_managed_ssl_certificate.default.id
  description = "Managed SSL certificate ID"
}

output "ssl_certificate_status" {
  value       = try(google_compute_managed_ssl_certificate.default.managed[0].domain_status, {})
  description = "SSL certificate domain status"
}

output "app_primary_neg_id" {
  value       = google_compute_region_network_endpoint_group.app_primary.id
  description = "Primary region serverless NEG ID"
}

output "app_secondary_neg_id" {
  value       = var.enable_secondary_region ? google_compute_region_network_endpoint_group.app_secondary[0].id : null
  description = "Secondary region serverless NEG ID"
}
