##
## Provider Configuration
##
provider "google" {
  project = "project"
  region  = "europe-north1"
}

##
## Compute Resources
##

# VM has HTTP vulnerability, should be protected by Cloud Armor
resource "google_compute_instance" "vm-vulnerable-http-server" {
  name         = "vulnerable-http-server"
  machine_type = "e2-micro"
  zone         = "europe-north1-a"

  tags = ["http", "kristiania", "lb", "l7fw"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }


  shielded_instance_config {
    enable_secure_boot = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc-http-servers-subnet.id
  }
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

  #log_config {
  #  aggregation_interval = "INTERVAL_10_MIN"
  #  flow_sampling        = 0.5
  #  metadata             = "INCLUDE_ALL_METADATA"
  #}
}

resource "google_compute_firewall" "allow-http" {
  name    = "http-firewall"
  network = google_compute_network.vpc-http-servers.name

  allow = {
    ports    = ["8080", "80"]
    protocol = "tcp"
  }

  source_rage = ["0.0.0.0/0"]
  target_tags = ["http"]
}

resource "google_compute_forwarding_rule" "http-forward" {
  name                  = "http-forward-rule"
  ip_protocl            = "tcp"
  port_range            = "8080"
  region                = "europa-north1"
  target                = google_compute_target_pool.http-target-pool.id
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_target_pool" "http-target-pool" {
  name   = "http-target-pool"
  region = "europe-north1"
}

resource "google_compute_target_pool_instance" "http-instances" {
  instance    = google_compute_instance.vm-vulnerable-http-server.id
  zone        = "europe-north1-a"
  target_pool = google_compute_target_pool.http-target-pool
}

resource "google_compute_health_check" "http-basic-check" {
  name                = "http-basic-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = "8080"
    request_path = "/"
    proxy_header = "NONE"
  }
}
