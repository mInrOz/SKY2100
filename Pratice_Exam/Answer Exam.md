
### What kind of migration strategy should be used based on the scenario?
Based on the information in the scenario given:
```
Just for him to realize that Hillary Clintons old e-mail server is still running in the basement.

The server is old, its not possible to upgrade the email software, and it needs to be protected as the Epstein and Diddys guest list on this server.

Trump has heard about this "cloud" thing, and he is adamant in saying it needs to be moved to the cloud. And he wants it done tomorrow!
```
The following insights is given:
- A traditional server is used
- Server is "old", and not possible to upgrade
- The server is vulnerable
- Time constraint

Based on the information from the scenario, the best migration strategy would be "lift-and shift". Lift and Shift is the best strategy due to the time constraint, and that a server is specified. There is no application details, which makes it hard to plan any other strategies.

The following other options exsists:
- Rehost
- Relocate
- Refactor
- Repurchase
- Replatform
- Retain
- Retire
**Retire** would be a good option, but its not a possibility as the server needs to be kept.
**Replatform** is not possible as we dont know the information about the e-mail server, and OS. E-mail service is not upgradable.
**Refactor** Is not possible due to the time constraint
**Rehost** Is the only viable option due to the time constraint.


### What kind of services will be used, what are the responsibility of Trump and what is the responsibility of the cloud provider? What are the hosting options available.

Based on the scenario, moving Hillary Clinton's old email server to the cloud presents several challenges and considerations. Given the server's age and inability to upgrade the email software, a lift-and-shift migration using Infrastructure-as-a-Service (IaaS) is the most viable option.  This involves migrating the server's existing operating system, email software, and data to a virtual machine (VM) hosted in the cloud.  Here's a breakdown of the process, responsibilities, and options:

**Cloud Services and Hosting Options:**

* **IaaS:** This service model is the most appropriate for this scenario. Trump's team would essentially rent virtualized hardware (servers, storage, network) from a cloud provider and install the old email server's software onto the virtual machine.  This minimizes changes to the server itself, preserving the data and functionality as is.
* **Hosting Options:** Within IaaS, there are several hosting options:
    * **Virtual Private Cloud (VPC):** This provides a logically isolated section of the cloud provider's infrastructure dedicated solely to Trump's use.  This enhances security and control.
    * **Dedicated Servers (Bare Metal):** Though less common in a cloud context, Trump could opt for dedicated physical servers hosted in the cloud provider's data center.  This offers maximum performance but comes at a higher cost and may still require software upgrades depending on hardware compatibility.
    * **Cloud Regions and Availability Zones:** Selecting the right cloud region (geographic location) and availability zones (isolated locations within a region) is crucial for redundancy and data sovereignty.  This ensures data backups are stored securely in different locations, safeguarding against outages.

**Responsibilities:**

* **Trump's Responsibilities:**
    * **Data Migration:** Trump's team is responsible for migrating the data from the physical server to the cloud VM.
    * **Software and OS Maintenance:**  Since the email software is not being upgraded, Trump's team is responsible for patching and securing the operating system and email software within the VM.
    * **Security Hardening:** While the cloud provider secures the underlying infrastructure, Trump's team is responsible for configuring firewalls, intrusion detection systems, and other security measures within the VM to protect the sensitive data.
    * **Access Control:**  Implementing strict access controls to limit who can access the server and the data is crucial.  This includes strong passwords, multi-factor authentication, and regular audits.
    * **Compliance:**  Depending on the nature of the data on the server, Trump's team may need to ensure compliance with relevant regulations (e.g., data privacy laws).
* **Cloud Provider's Responsibilities:**
    * **Physical Infrastructure Security:** The provider is responsible for securing the physical data centers, hardware, and network infrastructure.
    * **Availability and Uptime:**  The provider guarantees a certain level of uptime and availability of the cloud services as defined in a Service Level Agreement (SLA).
    * **Basic Infrastructure Management:** The provider manages the underlying hardware, networking, and virtualization layer, ensuring the VM runs smoothly.

**General Information and Useful Details:**

* **Security Best Practices:**  Given the sensitivity of the data, employing strong encryption both in transit and at rest is critical. Regular security assessments and penetration testing should be conducted to identify and address vulnerabilities.
* **Data Backup and Recovery:** A robust backup and disaster recovery plan is essential. Data should be regularly backed up to a separate location in the cloud to ensure it can be restored in case of an incident.
* **Cost Optimization:**  Cloud pricing is typically usage-based. Monitoring and optimizing resource allocation can help control costs.

### What are the benefits and negative about using the cloud?
- Moving cost from CAPEX to OPEX
- Flexibility compared to on-prem solutions.
- Cloud vendors will do security better than most companies
- Cloud is often more expensive, compared to on-prem solutions
- Cloud offers automation possibilities

### The e-mail server is vulnerable to XSS and SQLi, how can it be protected?
We are utilizing GCP (Google Cloud Platform), and GCP offers a service called `Cloud Armor` which is a L7 (Layer 7) based firewall. (Also called a Web Application Firewall in other enviornments).

We will enable the `XSS`and `SQLi` protection packages offered by [Cloud Armor](https://cloud.google.com/armor/docs/waf-rules). Google maintains the `Cloud Armor`service, and updates the protection packages as new vulnerabilities or attack possibilities arises.

Another possible solution that is not used, is to set up a VM (Virtual Machine), which acts as a L7 firewall, inspecting all traffic and blocking based on rules. Squid can be used to achieve this pourpose. But this is not used, because it increases complexity, cost, and operational overhead.




### Simulate a vulnerable VM in your chosen cloud provider
I will deploy a VM, on GCP, with port 80 exposed. As I am assuming that the e-mail service is a web-portal exposed on port 80 (HTTP).
To simulate this, I will deploy a VM, with Nginx listening on port 80. To simulate the e-mail service.

See the following `resource blocks` in the `main.tf` file for code that deploys the VM:
`compute_instance_group_manager` on line 42-50 + `compute_instance_template` on line 13-34

```hcl
resource "google_compute_instance_group_manager" "igm" {
  name = "igm-sql-injection-protection"
  zone = "europe-north1-a" # Trump lives in Norway, we choose the closest zone available.
  version {
    instance_template = google_compute_instance_template.vm_template.id
  }
  base_instance_name = "sql-injection-protection"
  target_size        = 1
}

```

See network code in `main.tf` for network configuration, that is required to be in place before we deploy the VM.
### The VM is vulnerable, protect it with a L7 Firewall

GCP (Google Cloud Platform), offers **Cloud Armor** as a managed service, that is a L7 Firewall service. That can protect against multiple common attacks.
We will use Cloud Armor to protect the vulnerable VM.

This is done, by creating a **HTTP-Proxy** which has a **URL-MAP** associated with it. Which sends traffic to a **backend-service** which is protected by L7 Firewall rules, specified in the `google_compute_security_policy` block.

Specifically we protect the VM, from **SQLi** and **XSS** attacks.

### Use a Vulnerability Analysis Tool
We use the **tfsec** tool, to analyze our Terraform code.
Which reported:
```
❯ tfsec
Result #1 LOW Subnetwork does not have VPC flow logs enabled.
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  main.tf:63-68
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   63    resource "google_compute_subnetwork" "vpc-http-servers-subnet" {
   64      name          = "vpc-http-servers-subnet"
   65      ip_cidr_range = "10.10.0.0/24"
   66      network       = google_compute_network.vpc-http-servers.name # We attach the subnet to the deployed VPC
   67      region        = "europe-north1"
   68    }
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
          ID google-compute-enable-vpc-flow-logs
      Impact Limited auditing capability and awareness
  Resolution Enable VPC flow logs

  More Information
  - https://aquasecurity.github.io/tfsec/v1.28.11/checks/google/compute/enable-vpc-flow-logs/
  - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork#enable_flow_logs
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────


  results
  ──────────────────────────────────────────
  passed               0
  ignored              0
  critical             0
  high                 0
  medium               0
  low                  1

  1 potential problem(s) detected.
  ```

**TFsec** reported a low finding, which is not a critical error or vulnerability. Which does not decrease our security in our deployed environment.
But we non the less improve our code, and deployed infrastructure by enabling VPC-Flow logs, VPC-Flow logs is enabled by the following code:
```hcl
resource <..>
vpc_flow = enabled

<..>

```


### Example
We deloy a VPC, and we attach a network to this VPC.
The network as a subnet of `10.0.0.0/24` attached to the network.


### Example DevSecOps

Further improvement to development of Infrastructure as Code.
Instead of running Terraform locally on my machine, this can be done in an automated way on GitHub, with a Git repository and GitHub actions.

Doing it this way, we can enforce the "security check" with tfsec, and depending on findings we can stop or proceed with deployment.