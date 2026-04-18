# Load Balancer Module - Global Load Balancer with Cloud CDN and IAP
# Uses terraform-google-modules standards for load balancer architecture

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================
# Global Static IP Address
# ============================================

resource "google_compute_global_address" "lb_ip" {
  name    = "${var.project_prefix}-global-lb-ip"
  project = var.gcp_project_id

  labels = var.tags
}

# ============================================
# Serverless NEGs for Cloud Run Services
# ============================================

# Primary Region
resource "google_compute_region_network_endpoint_group" "app_primary" {
  name                  = "${var.project_prefix}-neg-app-primary"
  network_endpoint_type = "SERVERLESS"
  region                = var.primary_region
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-app"
  }
}

# Secondary Region
resource "google_compute_region_network_endpoint_group" "app_secondary" {
  count                 = var.enable_secondary_region ? 1 : 0
  name                  = "${var.project_prefix}-neg-app-secondary"
  network_endpoint_type = "SERVERLESS"
  region                = var.secondary_region
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-app-secondary"
  }
}

# ============================================
# Health Check Configuration
# ============================================

resource "google_compute_health_check" "default" {
  name    = "${var.project_prefix}-health-check"
  project = var.gcp_project_id

  http_health_check {
    port         = 80
    request_path = "/api/health"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  labels = var.tags
}

# ============================================
# Backend Service with CDN and IAP
# ============================================

resource "google_compute_backend_service" "app_service" {
  name                  = "${var.project_prefix}-app-service"
  project               = var.gcp_project_id
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"
  custom_request_headers {
    headers = ["X-Client-Region:{client_region}"]
  }

  # Primary region backend
  backend {
    group          = google_compute_region_network_endpoint_group.app_primary.id
    balancing_mode = "UTILIZATION"
    max_utilization = 0.8
  }

  # Secondary region backend (optional)
  dynamic "backend" {
    for_each = var.enable_secondary_region ? [1] : []
    content {
      group          = google_compute_region_network_endpoint_group.app_secondary[0].id
      balancing_mode = "UTILIZATION"
      max_utilization = 0.8
    }
  }

  # Cloud CDN Configuration
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
    
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }

  # Enable IAP if configured
  dynamic "iap" {
    for_each = var.enable_iap && var.google_oauth_client_id != "" ? [1] : []
    content {
      oauth2_client_id     = var.google_oauth_client_id
      oauth2_client_secret = var.google_oauth_client_secret
    }
  }

  # Logging Configuration
  log_config {
    enable      = true
    sample_rate = 1.0
  }

  labels = var.tags
}

# ============================================
# SSL Certificate Management
# ============================================

# Google-Managed SSL Certificate (Recommended for production)
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.project_prefix}-ssl-cert"
  project = var.gcp_project_id

  managed {
    domains = concat(
      var.certificate_domains,
      ["looply.co.in"]
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# HTTPS Proxy and Forwarding Rules
# ============================================

resource "google_compute_url_map" "default" {
  name            = "${var.project_prefix}-url-map"
  project         = var.gcp_project_id
  default_service = google_compute_backend_service.app_service.id

  host_rule {
    hosts        = concat(["looply.co.in", "*.looply.co.in"], var.certificate_domains)
    path_matcher = "main-matcher"
  }

  path_matcher {
    name            = "main-matcher"
    default_service = google_compute_backend_service.app_service.id
  }
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.project_prefix}-https-proxy"
  project          = var.gcp_project_id
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]

  labels = var.tags
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.project_prefix}-https-forwarding-rule"
  project               = var.gcp_project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.lb_ip.address
  labels                = var.tags
}

# ============================================
# HTTP to HTTPS Redirect
# ============================================

resource "google_compute_url_map" "http_redirect_map" {
  name    = "${var.project_prefix}-http-redirect-map"
  project = var.gcp_project_id

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    https_redirect         = true
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect_proxy" {
  name    = "${var.project_prefix}-http-redirect-proxy"
  project = var.gcp_project_id
  url_map = google_compute_url_map.http_redirect_map.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.project_prefix}-http-forwarding-rule"
  project               = var.gcp_project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
  labels                = var.tags
}
