output "iap_client_id" {
  value       = google_iap_client.project_client.client_id
  description = "The OAuth 2.0 client ID for IAP"
  sensitive   = false
}

output "iap_brand_name" {
  value       = google_iap_brand.project_brand.name
  description = "The IAP brand name"
}

output "admin_iap_binding_role" {
  value       = google_iap_web_backend_service_iam_binding.admin_iap_binding.role
  description = "IAM role assigned to admin backend service"
}

output "user_mgmt_iap_binding_role" {
  value       = google_iap_web_backend_service_iam_binding.user_mgmt_iap_binding.role
  description = "IAM role assigned to user management backend service"
}

output "analytics_iap_binding_role" {
  value       = google_iap_web_backend_service_iam_binding.analytics_iap_binding.role
  description = "IAM role assigned to analytics backend service"
}

output "iap_logs_sink_name" {
  value       = google_logging_project_sink.iap_logs.name
  description = "Cloud Logging sink name for IAP logs"
}

output "iap_logs_destination" {
  value       = google_logging_project_sink.iap_logs.destination
  description = "Destination bucket for IAP logs"
}

output "iap_monitoring_alert_policy_name" {
  value       = try(google_monitoring_alert_policy.iap_failed_auth.display_name, null)
  description = "Name of the IAP authentication monitoring alert policy"
}

output "iap_oauth_setup_info" {
  value = {
    client_id           = google_iap_client.project_client.client_id
    project_id          = var.gcp_project_id
    scopes              = ["openid", "email", "profile"]
    supported_grant_types = ["authorization_code"]
    redirect_uris       = ["https://iap.googleapis.com/google_cloud_iap/web/oauth2/callback"]
  }
  description = "OAuth 2.0 setup information for IAP"
  sensitive   = false
}

output "iap_setup_documentation" {
  value = {
    setup_guide = "https://cloud.google.com/iap/docs/enabling-iap"
    security    = "IAP provides authentication and authorization via OAuth 2.0"
    features = [
      "User identity verification",
      "Fine-grained access control",
      "Audit logging",
      "Multi-factor authentication (MFA) ready"
    ]
  }
  description = "IAP setup documentation and features"
}
