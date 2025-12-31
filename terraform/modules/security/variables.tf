variable "project_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "ssl_certificate" {
  description = "SSL certificate for HTTPS"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "changeme123!@#"
}

variable "api_key" {
  description = "API key for third-party integrations"
  type        = string
  sensitive   = true
  default     = "api-key-placeholder"
}

variable "oauth_client_secret" {
  description = "OAuth client secret"
  type        = string
  sensitive   = true
  default     = "oauth-secret-placeholder"
}

variable "cloud_run_sa_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "scheduler_sa_email" {
  description = "Cloud Scheduler service account email"
  type        = string
}

variable "bigquery_sa_email" {
  description = "BigQuery service account email"
  type        = string
}

variable "storage_sa_email" {
  description = "Cloud Storage service account email"
  type        = string
}

variable "allowed_countries" {
  description = "List of country codes to allow (empty = all allowed)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for country in var.allowed_countries : length(country) == 2])
    error_message = "Country codes must be 2-character ISO 3166-1 alpha-2 codes (e.g., 'US', 'GB', 'DE')."
  }
}

variable "security_policy_preview_mode" {
  description = "Enable preview mode for security policies (doesn't block, only logs)"
  type        = bool
  default     = true

  validation {
    condition     = var.security_policy_preview_mode == true || var.security_policy_preview_mode == false
    error_message = "Must be true or false."
  }
}
