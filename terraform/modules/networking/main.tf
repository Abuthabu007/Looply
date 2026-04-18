# Networking Module - Uses terraform-google-modules/network/google
# Official Google module for VPC, Subnets, Routers, NAT, and Firewall Rules

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Main VPC Network using Official Google Module
# ============================================

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.0"

  project_id      = var.gcp_project_id
  network_name    = "${var.project_prefix}-vpc"
  routing_mode    = "GLOBAL"
  auto_create_subnetworks = false

  subnets = [
    {
      subnet_name           = "${var.project_prefix}-primary-subnet"
      subnet_ip             = var.primary_subnet_cidr
      subnet_region         = var.primary_region
      subnet_private_access = true
      subnet_flow_logs      = var.enable_flow_logs
      description           = "Primary region subnet"
    },
    {
      subnet_name           = "${var.project_prefix}-primary-proxy-subnet"
      subnet_ip             = var.primary_secondary_subnet_cidr
      subnet_region         = var.primary_region
      subnet_private_access = true
      purpose               = "REGIONAL_MANAGED_PROXY"
      role                  = "ACTIVE"
      description           = "Primary region proxy subnet"
    },
    {
      subnet_name           = "${var.project_prefix}-secondary-subnet"
      subnet_ip             = var.secondary_subnet_cidr
      subnet_region         = var.secondary_region
      subnet_private_access = true
      subnet_flow_logs      = var.enable_flow_logs
      description           = "Secondary region subnet"
    },
    {
      subnet_name           = "${var.project_prefix}-secondary-proxy-subnet"
      subnet_ip             = var.secondary_secondary_subnet_cidr
      subnet_region         = var.secondary_region
      subnet_private_access = true
      purpose               = "REGIONAL_MANAGED_PROXY"
      role                  = "ACTIVE"
      description           = "Secondary region proxy subnet"
    },
  ]

  firewall_rules = [
    {
      name  = "${var.project_prefix}-allow-internal"
      description = "Allow internal VPC communication"
      direction = "INGRESS"
      priority  = 1000
      ranges    = [var.primary_subnet_cidr, var.secondary_subnet_cidr]
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
        }
      ]
      target_tags = ["internal"]
    },
    {
      name        = "${var.project_prefix}-allow-https"
      description = "Allow HTTPS traffic from internet"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["443"]
        }
      ]
      target_tags = ["https-server"]
    },
    {
      name        = "${var.project_prefix}-allow-http"
      description = "Allow HTTP traffic from internet for redirects"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80"]
        }
      ]
      target_tags = ["http-server"]
    },
    {
      name        = "${var.project_prefix}-allow-health-checks"
      description = "Allow GCP health checks"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [
        {
          protocol = "tcp"
        }
      ]
      target_tags = ["health-check"]
    }
  ]
}

# ============================================
# Cloud NAT Configuration (Primary Region)
# ============================================

resource "google_compute_router" "primary_router" {
  name    = "${var.project_prefix}-primary-router"
  region  = var.primary_region
  network = module.vpc.network_id
  project = var.gcp_project_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "primary_nat" {
  name                               = "${var.project_prefix}-primary-nat"
  router                             = google_compute_router.primary_router.name
  region                             = google_compute_router.primary_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.gcp_project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ============================================
# Cloud NAT Configuration (Secondary Region)
# ============================================

resource "google_compute_router" "secondary_router" {
  name    = "${var.project_prefix}-secondary-router"
  region  = var.secondary_region
  network = module.vpc.network_id
  project = var.gcp_project_id

  bgp {
    asn = 64515
  }
}

resource "google_compute_router_nat" "secondary_nat" {
  name                               = "${var.project_prefix}-secondary-nat"
  router                             = google_compute_router.secondary_router.name
  region                             = google_compute_router.secondary_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.gcp_project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ============================================
# Private Service Connection for Cloud Services
# ============================================

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_prefix}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_id
  project       = var.gcp_project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
