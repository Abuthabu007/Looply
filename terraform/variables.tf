# Main variables for Looply Infrastructure

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
  default     = "looply"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary GCP region for multi-region setup"
  type        = string
  default     = "europe-west1"
}

variable "primary_subnet_cidr" {
  description = "CIDR block for primary region subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "primary_secondary_subnet_cidr" {
  description = "Secondary CIDR for primary region (for proxy)"
  type        = string
  default     = "10.0.16.0/24"
}

variable "secondary_subnet_cidr" {
  description = "CIDR block for secondary region subnet"
  type        = string
  default     = "10.1.0.0/20"
}

variable "secondary_secondary_subnet_cidr" {
  description = "Secondary CIDR for secondary region (for proxy)"
  type        = string
  default     = "10.1.16.0/24"
}

variable "enable_pitr" {
  description = "Enable point-in-time recovery for Firestore"
  type        = bool
  default     = true
}

variable "firestore_region" {
  description = "Firestore database region"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_repo" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "looply-docker-repo"
}

variable "ssl_certificate" {
  description = "SSL certificate for load balancer"
  type        = string
  sensitive   = true
}

variable "ssl_private_key" {
  description = "SSL private key for load balancer"
  type        = string
  sensitive   = true
}

variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run services"
  type        = string
  default     = "2"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run services"
  type        = string
  default     = "512Mi"
}

variable "cloud_run_timeout" {
  description = "Timeout in seconds for Cloud Run services"
  type        = number
  default     = 3600
}

variable "cloud_run_max_instances" {
  description = "Maximum instances for Cloud Run services"
  type        = number
  default     = 100
}

variable "log_bucket_retention_days" {
  description = "Retention days for logs in Cloud Storage"
  type        = number
  default     = 90
}

variable "video_bucket_versioning_enabled" {
  description = "Enable versioning for videos bucket"
  type        = bool
  default     = true
}

variable "bigquery_dataset_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

variable "pubsub_message_retention_duration" {
  description = "Message retention duration for Pub/Sub (in seconds)"
  type        = string
  default     = "604800s" # 7 days
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    project    = "looply"
    managed_by = "terraform"
    created_at = "2025-12-16"
  }
}
# ============================================================================
# Security Module Variables
# ============================================================================

variable "db_password" {
  description = "Database password for Firestore access"
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
  description = "OAuth client secret for authentication"
  type        = string
  sensitive   = true
  default     = "oauth-secret-placeholder"
}

variable "allowed_countries" {
  description = "List of country codes to allow (empty = all allowed). Use 2-letter ISO codes (US, GB, DE, etc.)"
  type        = list(string)
  default     = []
}

variable "security_policy_preview_mode" {
  description = "Enable preview mode for security policies (doesn't block, only logs)"
  type        = bool
  default     = true
}

# ============================================================================
# Monitoring Module Variables
# ============================================================================

variable "alert_email_primary" {
  description = "Primary email address for receiving alerts"
  type        = string
  default     = "alerts@example.com"
}

variable "alert_email_secondary" {
  description = "Secondary email address for receiving alerts (optional)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for critical alerts (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel_name" {
  description = "Slack channel name for alerts"
  type        = string
  default     = "#alerts"
}

variable "storage_growth_threshold" {
  description = "Storage growth threshold in bytes per second to trigger alert"
  type        = number
  default     = 1000000 # 1MB/sec
}

variable "api_endpoint" {
  description = "API endpoint to monitor for uptime checks"
  type        = string
  default     = "api.example.com"
}

variable "log_filter" {
  description = "Filter for logs sent to Cloud Storage"
  type        = string
  default     = "severity >= WARNING"
}

# IAP (Identity-Aware Proxy) Variables
variable "iap_support_email" {
  description = "Support email for IAP OAuth consent screen"
  type        = string
  default     = "ahamedbeema1989@gmail.com"
}

variable "iap_application_title" {
  description = "Application title for IAP OAuth consent screen"
  type        = string
  default     = "Looply - Video Streaming Platform"
}

variable "iap_admin_backend_service" {
  description = "Backend service name for admin panel IAP"
  type        = string
  default     = "admin-backend"
}

variable "iap_user_mgmt_backend_service" {
  description = "Backend service name for user management API IAP"
  type        = string
  default     = "user-management-backend"
}

variable "iap_analytics_backend_service" {
  description = "Backend service name for analytics dashboard IAP"
  type        = string
  default     = "analytics-backend"
}

variable "iap_admin_authorized_users" {
  description = "List of admin users authorized to access admin panel (e.g., [\"user:admin@company.com\", \"group:admins@company.com\"])"
  type        = list(string)
  default     = []
}

variable "iap_user_mgmt_authorized_users" {
  description = "List of users authorized to access user management API"
  type        = list(string)
  default     = []
}

variable "iap_analytics_authorized_users" {
  description = "List of users authorized to access analytics dashboard"
  type        = list(string)
  default     = []
}

variable "iap_public_authorized_users" {
  description = "List of users authorized for public IAP access"
  type        = list(string)
  default     = []
}

variable "iap_enable_public_access" {
  description = "Enable IAP access for public users"
  type        = bool
  default     = false
}

variable "iap_enable_alerts" {
  description = "Enable Cloud Monitoring alerts for IAP authentication failures"
  type        = bool
  default     = true
}

variable "iap_failed_auth_threshold" {
  description = "Threshold for failed authentication alerts (number of failures)"
  type        = number
  default     = 50
}
# ============================================================================
# Identity Platform Variables
# ============================================================================

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID for Identity Platform"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_oauth_client_secret" {
  description = "Google OAuth 2.0 Client Secret for Identity Platform"
  type        = string
  sensitive   = true
  default     = ""
}

variable "allowed_redirect_uris" {
  description = "List of allowed redirect URIs for OAuth configuration"
  type        = list(string)
  default = [
    "http://localhost:3000",
    "http://localhost:5000"
  ]
}