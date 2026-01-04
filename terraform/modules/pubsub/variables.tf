# Pub/Sub Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "pubsub_message_retention_duration" {
  description = "Message retention duration (in seconds)"
  type        = string
  default     = "604800s"
}

variable "cloud_run_primary_service_url" {
  description = "Primary region Cloud Run service URL"
  type        = string
}

variable "cloud_run_secondary_service_url" {
  description = "Secondary region Cloud Run service URL"
  type        = string
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  type        = string
}

variable "pubsub_service_account_email" {
  description = "Pub/Sub service account email"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
variable "video_upload_topic_name" {
  description = "Name suffix for video upload events topic"
  type        = string
  default     = "video-upload-events"
}

variable "transcoding_complete_topic_name" {
  description = "Name suffix for transcoding complete events topic"
  type        = string
  default     = "transcoding-complete"
}

variable "ack_deadline_seconds" {
  description = "Acknowledge deadline in seconds for subscriptions"
  type        = number
  default     = 60
}

variable "enable_secondary_region" {
  description = "Enable secondary region subscriptions"
  type        = bool
  default     = true
}