output "iap_client_id" {
  value       = "See GCP Console > APIs & Services > Credentials for your OAuth 2.0 Client ID"
  description = "The OAuth 2.0 client ID for IAP (managed externally)"
  sensitive   = false
}

output "iap_brand_name" {
  value       = "See GCP Console > Security > Identity-Aware Proxy for your IAP Brand"
  description = "The IAP brand name (managed at organization level)"
}

output "oauth_secret_name" {
  value       = google_secret_manager_secret.oauth_client_secret.id
  description = "Secret Manager secret name containing OAuth 2.0 client secret for IAP"
}

output "iap_logs_sink_name" {
  value       = google_logging_project_sink.iap_logs.name
  description = "Cloud Logging sink name for IAP logs"
}

output "iap_logs_destination" {
  value       = google_logging_project_sink.iap_logs.destination
  description = "Destination bucket for IAP logs"
}

output "iap_oauth_setup_info" {
  value = {
    oauth_client_id = "Obtain from GCP Console > APIs & Services > Credentials"
    oauth_brand     = "Managed at organization level in GCP Console"
    project_id      = var.gcp_project_id
    scopes          = ["openid", "email", "profile"]
    redirect_uris   = ["https://iap.googleapis.com/google_cloud_iap/web/oauth2/callback"]
    setup_location  = "GCP Console > Security > Identity-Aware Proxy"
  }
  description = "OAuth 2.0 setup information for IAP (managed externally)"
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
