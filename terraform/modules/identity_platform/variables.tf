# Identity Platform Module Variables

variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
  nullable    = false
}

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID for Identity Platform"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "google_oauth_client_secret" {
  description = "Google OAuth 2.0 Client Secret for Identity Platform"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "allowed_redirect_uris" {
  description = "List of allowed redirect URIs for OAuth configuration"
  type        = list(string)
  default = [
    "http://localhost:3000",
    "http://localhost:5000"
  ]
}
