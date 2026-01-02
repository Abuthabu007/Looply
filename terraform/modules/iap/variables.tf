variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "project_prefix" {
  type        = string
  description = "Project name prefix for IAP resources"
}

variable "support_email" {
  type        = string
  description = "Support email for OAuth consent screen"
  default     = "admin@looply.co.in"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.support_email))
    error_message = "Must be a valid email address."
  }
}

variable "application_title" {
  type        = string
  description = "Title of the application for OAuth consent screen"
  default     = "Looply - Video Streaming Platform"
}

variable "app_backend_service_name" {
  type        = string
  description = "Name of the bundled app backend service to protect with IAP"
}

variable "admin_authorized_users" {
  type        = list(string)
  description = "List of admin users authorized to access the application (e.g., user:admin@company.com, group:admins@company.com)"
  default     = []
}

variable "api_authorized_users" {
  type        = list(string)
  description = "List of users authorized to access the API"
  default     = []
}

variable "public_authorized_users" {
  type        = list(string)
  description = "List of users authorized for public IAP access (if enabled)"
  default     = []
}

variable "enable_public_iap_access" {
  type        = bool
  description = "Enable IAP access for public users"
  default     = false
}

variable "enable_iap_alerts" {
  type        = bool
  description = "Enable Cloud Monitoring alerts for IAP"
  default     = true
}

variable "failed_auth_threshold" {
  type        = number
  description = "Threshold for failed authentication alerts"
  default     = 50
}

variable "logs_bucket_name" {
  type        = string
  description = "Cloud Storage bucket name for IAP logs"
}

variable "notification_channel_ids" {
  type        = list(string)
  description = "List of Cloud Monitoring notification channel IDs for alerts"
  default     = []
}

variable "service_account_email" {
  type        = string
  description = "Service account email for IAP policy admin"
}

variable "iap_service_account_email" {
  type        = string
  description = "Service account email for IAP KMS encryption"
}

variable "load_balancer_service_account_email" {
  type        = string
  description = "Service account email for load balancer to access OAuth secret"
}

variable "kms_crypto_key_id" {
  type        = string
  description = "KMS crypto key ID for secret encryption"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to IAP resources"
  default = {
    component = "iap"
    managed   = "terraform"
  }
}
