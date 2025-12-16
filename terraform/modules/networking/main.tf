# Networking Module - VPC, Subnets, Routers, NAT, and Firewall Rules

# ============================================
# VPC Network
# ============================================

resource "google_compute_network" "main_vpc" {
  name                    = "${var.project_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  project                 = var.gcp_project_id

  
}

# ============================================
# Primary Region Subnets
# ============================================

resource "google_compute_subnetwork" "primary_subnet" {
  name          = "${var.project_prefix}-primary-subnet"
  ip_cidr_range = var.primary_subnet_cidr
  region        = var.primary_region
  network       = google_compute_network.main_vpc.id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "primary_proxy_subnet" {
  name          = "${var.project_prefix}-primary-proxy-subnet"
  ip_cidr_range = var.primary_secondary_subnet_cidr
  region        = var.primary_region
  network       = google_compute_network.main_vpc.id
  project       = var.gcp_project_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# ============================================
# Secondary Region Subnets
# ============================================

resource "google_compute_subnetwork" "secondary_subnet" {
  name          = "${var.project_prefix}-secondary-subnet"
  ip_cidr_range = var.secondary_subnet_cidr
  region        = var.secondary_region
  network       = google_compute_network.main_vpc.id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "secondary_proxy_subnet" {
  name          = "${var.project_prefix}-secondary-proxy-subnet"
  ip_cidr_range = var.secondary_secondary_subnet_cidr
  region        = var.secondary_region
  network       = google_compute_network.main_vpc.id
  project       = var.gcp_project_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

# ============================================
# Firewall Rules
# ============================================

# Allow internal VPC communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_prefix}-allow-internal"
  network = google_compute_network.main_vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.primary_subnet_cidr,
    var.secondary_subnet_cidr
  ]

  target_tags = ["internal"]
}

# Allow HTTPS traffic from internet
resource "google_compute_firewall" "allow_https" {
  name    = "${var.project_prefix}-allow-https"
  network = google_compute_network.main_vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Allow HTTP traffic from internet (for redirects)
resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_prefix}-allow-http"
  network = google_compute_network.main_vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Allow GCP health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_prefix}-allow-health-checks"
  network = google_compute_network.main_vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["health-check"]
}

# ============================================
# Cloud NAT Configuration (Primary Region)
# ============================================

resource "google_compute_router" "primary_router" {
  name    = "${var.project_prefix}-primary-router"
  region  = var.primary_region
  network = google_compute_network.main_vpc.id
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
  network = google_compute_network.main_vpc.id
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
  network       = google_compute_network.main_vpc.id
  project       = var.gcp_project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
