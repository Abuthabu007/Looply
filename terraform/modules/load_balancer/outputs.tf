# Load Balancer Module - Outputs

output "global_ip_address" {
  value       = google_compute_global_address.lb_ip.address
  description = "Global load balancer IP address for HTTPS"
}

output "load_balancer_url" {
  value       = "https://${google_compute_global_address.lb_ip.address}"
  description = "Load balancer HTTPS URL"
}

output "app_service_id" {
  value       = google_compute_backend_service.app_service.id
  description = "Bundled app service ID"
}

output "app_service_name" {
  value       = google_compute_backend_service.app_service.name
  description = "Bundled app service name (for IAP)"
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

output "app_neg_id" {
  value       = google_compute_region_network_endpoint_group.app_primary.id
  description = "Bundled app serverless NEG ID"
}
