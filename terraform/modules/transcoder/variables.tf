variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
}

variable "input_bucket" {
  description = "Cloud Storage bucket for input videos"
  type        = string
}

variable "output_bucket" {
  description = "Cloud Storage bucket for transcoded videos"
  type        = string
}

variable "tags" {
  description = "Labels for resources"
  type        = map(string)
  default     = {}
}
