# Load Balancer Module - Global Load Balancer with Cloud CDN and IAP

# ============================================
# Global Static IP Address
# ============================================

resource "google_compute_global_address" "lb_ip" {
  name    = "${var.project_prefix}-global-lb-ip"
  project = var.gcp_project_id

  labels = var.tags
}

# ============================================
# Serverless NEG for Bundled App - Primary Region
# ============================================

resource "google_compute_region_network_endpoint_group" "app_primary" {
  name                  = "${var.project_prefix}-neg-app-primary"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-app"
  }
}

# ============================================
# Health Check
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
}

# ============================================
# Backend Service for Bundled App - with CDN and IAP
# ============================================

resource "google_compute_backend_service" "app_service" {
  name                  = "${var.project_prefix}-app-service"
  project               = var.gcp_project_id
  protocol              = "HTTPS"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group          = google_compute_region_network_endpoint_group.app_primary.id
    balancing_mode = "UTILIZATION"
  }

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

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ============================================
# SSL/TLS Certificate
# ============================================

resource "google_compute_ssl_certificate" "default" {
  name            = "${var.project_prefix}-ssl-cert"
  private_key     = var.ssl_private_key
  certificate     = var.ssl_certificate
  project         = var.gcp_project_id
  
  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# URL Map - Routes all traffic to bundled app
# ============================================

resource "google_compute_url_map" "default" {
  name            = "${var.project_prefix}-url-map"
  project         = var.gcp_project_id
  default_service = google_compute_backend_service.app_service.id

  host_rule {
    hosts        = ["looply.co.in", "*.looply.co.in", "*"]
    path_matcher = "main-matcher"
  }

  path_matcher {
    name            = "main-matcher"
    default_service = google_compute_backend_service.app_service.id
  }
}

# ============================================
# HTTPS Proxy
# ============================================

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.project_prefix}-https-proxy"
  project          = var.gcp_project_id
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_ssl_certificate.default.id]
}

# ============================================
# Global Forwarding Rule - HTTPS (Port 443)
# ============================================

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

# ============================================
# Firewall Rule for Load Balancer Health Checks
# ============================================

resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "${var.project_prefix}-allow-lb-health-check"
  network = var.vpc_network_name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
    "209.85.152.0/22",
    "209.85.204.0/22"
  ]

  target_tags = ["load-balancer"]
}
