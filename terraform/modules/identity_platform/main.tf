# Identity Platform Module - Configure Google Cloud Identity Platform with OAuth providers

# Enable Identity Platform API for the project
resource "google_project_service" "identity_platform_api" {
  project = var.gcp_project_id
  service = "identitytoolkit.googleapis.com"

  disable_on_destroy = false
}

# Identity Platform Config - Temporarily disabled (requires quota project)

resource "google_identity_platform_config" "default" {
  project = var.gcp_project_id

  autodelete_anonymous_users = false

  depends_on = [google_project_service.identity_platform_api]
}

# Google as Identity Provider - OAuth 2.0 Configuration
resource "google_identity_platform_oauth_idp_config" "google" {
  name          = "google.com"
  display_name  = "Google"
  client_id     = var.google_oauth_client_id
  client_secret = var.google_oauth_client_secret
  issuer        = "https://accounts.google.com"
  enabled       = true
  project       = var.gcp_project_id

  depends_on = [google_identity_platform_config.default]
}

# Enable Google Sign-In by default
resource "google_identity_platform_default_supported_idp_config" "google" {
  enabled        = true
  idp_id         = "google.com"
  project        = var.gcp_project_id
  client_id      = var.google_oauth_client_id
  client_secret  = var.google_oauth_client_secret

  depends_on = [google_identity_platform_oauth_idp_config.google]
}

