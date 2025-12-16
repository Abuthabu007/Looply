# APIs Module Outputs

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.required_apis : api.service]
}

output "total_apis_enabled" {
  description = "Total number of APIs enabled"
  value       = length(google_project_service.required_apis)
}
