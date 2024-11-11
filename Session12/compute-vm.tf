#
# We create an instance template, which we will use to deploy a Virtual Machine
# We reference the VPC and Network that the VM should be placed into
# We use Debian 12 as the Operating System
#
resource "google_compute_instance_template" "vm_template" {
  name         = "sql-injection-protection-template"
  machine_type = "e2-micro"

  tags = ["http", "kristiania", "lb", "l7fw"]

  disk {
    source_image = "debian-cloud/debian-12"
  }

  # TFSec recomends enabling VPC Flow logs
  # https://aquasecurity.github.io/tfsec/v1.28.11/checks/google/compute/enable-vpc-flow-logs/
  log_config {
  }

  # We enable VPC flow logs, per best-practice
  # And to have tracability on the networking layer
  log_config {
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
  network_interface {
    subnetwork = google_compute_subnetwork.vpc-http-servers-subnet.id
  }
}

#
# We specify a "Instance Group Manager", to manage the deployments of VMs
# The Instance Template is referenced in the Instance Group Manager
# We specify "target_size" to 1, as we only need one virtual machine to simulate the vulnerable e-mail service.
#

resource "google_compute_instance_group_manager" "igm" {
  name = "igm-sql-injection-protection"
  zone = "europe-north1-a" # Trump lives in Norway, we choose the closest zone available.
  version {
    instance_template = google_compute_instance_template.vm_template.id
  }
  base_instance_name = "sql-injection-protection"
  target_size        = 1
}

