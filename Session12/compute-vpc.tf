# We need a VPC to deploy the VM into.
resource "google_compute_network" "vpc-http-servers" {
  name                    = "vpc-http-servers"
  auto_create_subnetworks = false # We want to specify subnets
}

# Create subnet used for VM deployment
resource "google_compute_subnetwork" "vpc-http-servers-subnet" {
  name          = "vpc-http-servers-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc-http-servers.name # We attach the subnet to the deployed VPC
  region        = "europe-north1"
}

