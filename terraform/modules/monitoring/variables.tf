variable "project_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "alert_email_primary" {
  description = "Primary email for alerts"
  type        = string
}

variable "alert_email_secondary" {
  description = "Secondary email for alerts (optional)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts (optional)"
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
  description = "Storage growth threshold in bytes per second (to alert on)"
  type        = number
  default     = 1000000 # 1MB/sec
}

variable "api_endpoint" {
  description = "API endpoint to monitor (for uptime checks)"
  type        = string
  default     = "api.example.com"
}

variable "storage_bucket_logs" {
  description = "Cloud Storage bucket for logs"
  type        = string
}

variable "log_filter" {
  description = "Logging filter for sink"
  type        = string
  default     = "severity >= WARNING"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}
