# Load Balancer Module - Global Load Balancer with Cloud CDN

# ============================================
# Global Static IP Address
# ============================================

resource "google_compute_global_address" "lb_ip" {
  name    = "${var.project_prefix}-global-lb-ip"
  project = var.gcp_project_id

  labels = var.tags
}

# Serverless NEG for Backend - Primary Region
resource "google_compute_region_network_endpoint_group" "backend_primary" {
  name                  = "${var.project_prefix}-neg-backend-primary"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-backend"
  }
}

# Serverless NEG for Frontend - Primary Region
resource "google_compute_region_network_endpoint_group" "frontend_primary" {
  name                  = "${var.project_prefix}-neg-frontend-primary"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-frontend"
  }
}

# ============================================
# Serverless NEG for Backend - Secondary Region
# ============================================

resource "google_compute_region_network_endpoint_group" "backend_secondary" {
  name                  = "${var.project_prefix}-neg-backend-secondary"
  network_endpoint_type = "SERVERLESS"
  region                = "europe-west1"
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-backend-eu"
  }
}

# Serverless NEG for Frontend - Secondary Region
resource "google_compute_region_network_endpoint_group" "frontend_secondary" {
  name                  = "${var.project_prefix}-neg-frontend-secondary"
  network_endpoint_type = "SERVERLESS"
  region                = "europe-west1"
  project               = var.gcp_project_id

  cloud_run {
    service = "${var.project_prefix}-frontend-eu"
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
# Backend Service for API - with CDN
# ============================================

resource "google_compute_backend_service" "backend_api" {
  name            = "${var.project_prefix}-backend-api-service"
  project         = var.gcp_project_id
  protocol        = "HTTP"
  timeout_sec     = 30
  load_balancing_scheme = "EXTERNAL"

  # Serverless NEGs (Cloud Run) don't support health checks
  # health_checks = [google_compute_health_check.default.id]

  backend {
    group           = google_compute_region_network_endpoint_group.backend_primary.id
    balancing_mode  = "UTILIZATION"
  }

  backend {
    group           = google_compute_region_network_endpoint_group.backend_secondary.id
    balancing_mode  = "UTILIZATION"
  }

  cdn_policy {
    cache_mode                = "CACHE_ALL_STATIC"
    client_ttl                = 3600
    default_ttl               = 3600
    max_ttl                   = 86400
    negative_caching          = true
    serve_while_stale         = 86400
    cache_key_policy {
      include_host           = true
      include_protocol       = true
      include_query_string   = true
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ============================================
# Backend Service for Frontend - with CDN
# ============================================

resource "google_compute_backend_service" "frontend_web" {
  name            = "${var.project_prefix}-frontend-web-service"
  project         = var.gcp_project_id
  protocol        = "HTTP"
  timeout_sec     = 30
  load_balancing_scheme = "EXTERNAL"

  # Serverless NEGs (Cloud Run) don't support health checks
  # health_checks = [google_compute_health_check.default.id]

  backend {
    group           = google_compute_region_network_endpoint_group.frontend_primary.id
    balancing_mode  = "UTILIZATION"
  }

  backend {
    group           = google_compute_region_network_endpoint_group.frontend_secondary.id
    balancing_mode  = "UTILIZATION"
  }

  cdn_policy {
    cache_mode                = "CACHE_ALL_STATIC"
    client_ttl                = 3600
    default_ttl               = 3600
    max_ttl                   = 86400
    negative_caching          = true
    serve_while_stale         = 86400
    cache_key_policy {
      include_host           = true
      include_protocol       = true
      include_query_string   = true
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}


# ============================================
# URL Map - Routes frontend and backend
# ============================================

resource "google_compute_url_map" "default" {
  name            = "${var.project_prefix}-url-map"
  default_service = google_compute_backend_service.frontend_web.id
  project         = var.gcp_project_id

  path_matcher {
    name            = "backend-api"
    default_service = google_compute_backend_service.backend_api.id

    path_rule {
      paths   = ["/api/*", "/health"]
      service = google_compute_backend_service.backend_api.id
    }
  }

  path_matcher {
    name            = "frontend-web"
    default_service = google_compute_backend_service.frontend_web.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.frontend_web.id
    }
  }

  host_rule {
    hosts        = ["api.*", "backend.*"]
    path_matcher = "backend-api"
  }

  host_rule {
    hosts        = ["*"]
    path_matcher = "frontend-web"
  }
}

# ============================================
# SSL/TLS Certificate - Temporarily disabled
# ============================================
/*
resource "google_compute_ssl_certificate" "default" {
  name    = "${var.project_prefix}-ssl-cert"
  project = var.gcp_project_id

  certificate = var.ssl_certificate
  private_key = var.ssl_private_key

  lifecycle {
    create_before_destroy = true
  }
}
*/

# ============================================
# HTTPS Proxy - Temporarily disabled
# ============================================
/*
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.project_prefix}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_ssl_certificate.default.id]
  project          = var.gcp_project_id
}
*/

# ============================================
# HTTP Proxy
# ============================================

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.project_prefix}-http-proxy"
  url_map = google_compute_url_map.default.id
  project = var.gcp_project_id
}

# ============================================
# Global Forwarding Rule
# ============================================

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${var.project_prefix}-forwarding-rule"
  project               = var.gcp_project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.lb_ip.address

  labels = var.tags
}

# ============================================
# HTTP to HTTPS Redirect
# ============================================

resource "google_compute_url_map" "http_redirect" {
  name    = "${var.project_prefix}-http-redirect"
  project = var.gcp_project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name     = "${var.project_prefix}-http-proxy"
  url_map  = google_compute_url_map.http_redirect.id
  project  = var.gcp_project_id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name                  = "${var.project_prefix}-http-forwarding-rule"
  project               = var.gcp_project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect.id
  ip_address            = google_compute_global_address.lb_ip.address
}

# ============================================
# Firewall Rule for Load Balancer
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
