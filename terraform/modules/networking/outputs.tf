# Networking Module - Outputs

output "vpc_network_id" {
  value       = google_compute_network.main_vpc.id
  description = "VPC Network ID"
}

output "vpc_network_name" {
  value       = google_compute_network.main_vpc.name
  description = "VPC Network name"
}

output "primary_subnet_id" {
  value       = google_compute_subnetwork.primary_subnet.id
  description = "Primary region subnet ID"
}

output "primary_subnet_self_link" {
  value       = google_compute_subnetwork.primary_subnet.self_link
  description = "Primary region subnet self link"
}

output "secondary_subnet_id" {
  value       = google_compute_subnetwork.secondary_subnet.id
  description = "Secondary region subnet ID"
}

output "secondary_subnet_self_link" {
  value       = google_compute_subnetwork.secondary_subnet.self_link
  description = "Secondary region subnet self link"
}

output "primary_router_id" {
  value       = google_compute_router.primary_router.id
  description = "Primary region router ID"
}

output "secondary_router_id" {
  value       = google_compute_router.secondary_router.id
  description = "Secondary region router ID"
}

output "vpc_self_link" {
  value       = google_compute_network.main_vpc.self_link
  description = "VPC Network self link"
}
