# Service Accounts Module - Variables

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
