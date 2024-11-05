##
## Provider Configuration
##
provider "google" {
  project = "project-id"
  region  = "europe-north1"
}

##
## Compute Resources
##

resource "google_compute_instance_template" "vm_template" {
  name         = "sql-injection-protection-template"
  machine_type = "e2-micro"

  tags = ["http", "kristiania", "lb", "l7fw"]

  disk {
    source_image = "debian-cloud/debian-12"
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
  network_interface {
    subnetwork = google_compute_subnetwork.vpc-http-servers-subnet.id
  }
}

resource "google_compute_instance_group_manager" "igm" {
  name = "igm-sql-injection-protection"
  zone = "europe-north1-a"
  version {
    instance_template = google_compute_instance_template.vm_template.id
  }
  base_instance_name = "sql-injection-protection"
  target_size        = 1
}

##
## Networking Resources
##
resource "google_compute_network" "vpc-http-servers" {
  name                    = "vpc-http-servers"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc-http-servers-subnet" {
  name          = "vpc-http-servers-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc-http-servers.name
  region        = "europe-north1"
}

# Code for external deployment, not allowed to deploy. Disabled.
#resource "google_compute_global_forwarding_rule" "default" {
#  name       = "global-rule-sql-injection"
#  target     = google_compute_target_http_proxy.default.id
#  port_range = "8080"
#}

# HTTP Proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy-sql-injection"
  url_map = google_compute_url_map.default.id
}

# URL Map for HTTP proxy
resource "google_compute_url_map" "default" {
  name            = "url-map-sql-injection"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name        = "backend-service-sql-injection"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.igm.instance_group
  }
  health_checks   = [google_compute_http_health_check.default.id]
  security_policy = google_compute_security_policy.sql_injection_protection.id
}

# Health check for backend service
resource "google_compute_http_health_check" "default" {
  name                = "http-health-check-sql-injection"
  request_path        = "/"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 2
}

# Security Policy for SQL injection + XSS prevention
#
# Doc: https://cloud.google.com/armor/docs/waf-rules
#
resource "google_compute_security_policy" "sql_injection_protection" {
  name = "sql-injection-protection-policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Prevent XSS attacks"
  }

  rule {
    action   = "deny(403)"
    priority = "1001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Prevent SQL Injection attacks"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule to allow all other traffic"
  }
}
