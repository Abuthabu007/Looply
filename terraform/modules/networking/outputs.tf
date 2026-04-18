# Networking Module - Outputs

output "vpc_network_id" {
  value       = module.vpc.network_id
  description = "VPC Network ID"
}

output "vpc_network_name" {
  value       = module.vpc.network_name
  description = "VPC Network name"
}

output "vpc_self_link" {
  value       = module.vpc.network_self_link
  description = "VPC Network self link"
}

output "primary_subnet_id" {
  value       = module.vpc.subnets_ids[0]
  description = "Primary region subnet ID"
}

output "primary_subnet_self_link" {
  value       = module.vpc.subnets_self_links[0]
  description = "Primary region subnet self link"
}

output "secondary_subnet_id" {
  value       = module.vpc.subnets_ids[2]
  description = "Secondary region subnet ID"
}

output "secondary_subnet_self_link" {
  value       = module.vpc.subnets_self_links[2]
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

output "subnets" {
  value       = module.vpc.subnets
  description = "All subnets created"
}

output "firewall_rules" {
  value       = module.vpc.firewall_rules
  description = "All firewall rules created"
}
