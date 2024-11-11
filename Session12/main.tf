##
## Provider Configuration
##
#provider "google" {
#  project = "tnn-sb-t991100"
#  region  = "europe-north1"
#}

##
## Compute Resources
##

#
# We create an instance template, which we will use to deploy a Virtual Machine
# We reference the VPC and Network that the VM should be placed into
# We use Debian 12 as the Operating System
#
#
# We specify a "Instance Group Manager", to manage the deployments of VMs
# The Instance Template is referenced in the Instance Group Manager
# We specify "target_size" to 1, as we only need one virtual machine to simulate the vulnerable e-mail service.
#

##
## Networking Resources
##


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
#
# The backend service, targets the instance group
# The backend service as a security policy attached to it, which protects from SQLi + XSS
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

  # A default rule is required, we have specified a default allow rule
  # That matches all traffic which is not blocked by the SQLi or XSS deny rules.
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
