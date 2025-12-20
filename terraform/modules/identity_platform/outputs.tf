# Identity Platform Module Outputs

output "identity_platform_project" {
  description = "The GCP project ID for Identity Platform"
  value       = google_identity_platform_config.default.project
}

output "google_oauth_idp_name" {
  description = "The resource name of the Google OAuth Identity Provider"
  value       = google_identity_platform_oauth_idp_config.google.name
}

output "google_idp_enabled" {
  description = "Whether Google is enabled as an Identity Provider"
  value       = google_identity_platform_oauth_idp_config.google.enabled
}

output "identity_platform_config_resource" {
  description = "The Identity Platform configuration resource name"
  value       = google_identity_platform_config.default.name
}
