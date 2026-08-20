# Terraform AWS Compute Module

A reusable Terraform module for provisioning a fixed EC2 compute instance with optional IAM capabilities.

The module is designed to provide a generic compute building block that can be reused across different projects, environments, and service workloads.

---

## Architecture

The module provisions a single EC2 instance and an IAM instance profile.

Optional AWS capabilities are attached to the same EC2 IAM role only when explicitly enabled.

```text
                           Terraform AWS Compute Module
                                      │
                                      │
                         ┌────────────▼────────────┐
                         │       EC2 Instance      │
                         │                         │
                         │  Ubuntu 24.04 LTS       │
                         │  Configurable Type      │
                         │  Private by Default     │
                         │  Encrypted GP3 Root     │
                         └────────────┬────────────┘
                                      │
                                      │
                         ┌────────────▼────────────┐
                         │    IAM Instance Profile │
                         └────────────┬────────────┘
                                      │
                              ┌───────▼───────┐
                              │    IAM Role   │
                              └───────┬───────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
          ┌─────────────┐      ┌─────────────┐      ┌──────────────┐
          │     SSM     │      │     ECR     │      │   Route 53   │
          │             │      │             │      │              │
          │ Optional    │      │ Optional    │      │ Optional     │
          │ Default ON  │      │ Default OFF │      │ Default OFF  │
          └─────────────┘      └─────────────┘      └──────────────┘
```

### Supporting Infrastructure

The module does **not** create the surrounding VPC, subnet, security group, or Route 53 hosted zone.

Those resources are supplied by the calling infrastructure.

```text
                 Core Infrastructure
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
   VPC / Subnet    Security Group    Route 53 Zone
        │               │                │
        └───────────────┼────────────────┘
                        │
                        ▼
              ┌───────────────────┐
              │   Compute Module  │
              │                   │
              │   EC2 Instance   │
              └───────────────────┘
```

This separation keeps the module generic and reusable.

---

## Features

The module provides:

* Ubuntu 24.04 LTS EC2 instance
* Configurable EC2 instance type
* Configurable subnet
* Configurable security group
* Encrypted GP3 root EBS volume
* IAM role
* IAM instance profile
* AWS Systems Manager access
* Optional Amazon ECR read access
* Optional Route 53 record-management access
* Optional public IPv4 address
* Optional user-data bootstrap
* Dynamic Ubuntu AMI selection
* Consistent resource naming and tagging

---

## Design Principles

### Generic and Reusable

The module does not contain application-specific configuration.

The caller determines:

* project name
* environment
* service name
* subnet
* security group
* instance type
* user-data
* optional AWS capabilities

This allows the same module to be used for workloads such as:

* database utilities
* internal services
* worker processes
* administrative hosts
* Docker hosts
* application support services
* development utilities

---

### Least Privilege

Optional IAM capabilities are disabled unless explicitly requested.

The default configuration is:

```text
SSM       = enabled
ECR       = disabled
Route 53  = disabled
```

ECR permissions are granted only when the instance needs to pull private container images.

Route 53 permissions are granted only when the instance needs to modify records in a specific hosted zone.

---

### Private by Default

The EC2 instance does not receive a public IPv4 address unless explicitly requested.

```hcl
associate_public_ip_address = false
```

This makes the module suitable for private, internal, and isolated network architectures.

---

### Caller-Owned Networking

The module does not create:

* VPCs
* subnets
* route tables
* internet gateways
* NAT gateways
* security groups

Instead, the caller supplies the appropriate resource IDs.

For example:

```hcl
subnet_id         = module.vpc_base.internal_subnet_ids[0]
security_group_id = module.internal_sg.security_group_id
```

This prevents the compute module from making assumptions about the caller's network architecture.

---

## Usage

```hcl
module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.0.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "db-hub"

  subnet_id         = module.vpc_base.internal_subnet_ids[0]
  security_group_id = module.internal_sg.security_group_id

  instance_type = "t3.medium"

  enable_ssm_access      = true
  enable_ecr_read_access = false

  associate_public_ip_address = false

  user_data = local.user_data
}
```

---

## IAM Capabilities

The module creates one IAM role for the EC2 instance.

Permissions are attached to that role according to the enabled features.

```text
                    EC2 Instance
                          │
                          ▼
                  IAM Instance Profile
                          │
                          ▼
                     IAM Role
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
         SSM             ECR            Route 53
       Optional        Optional         Optional
       Default ON      Default OFF     Default OFF
```

This avoids creating multiple IAM roles for a single EC2 instance.

---

## AWS Systems Manager Access

SSM access is enabled by default.

```hcl
enable_ssm_access = true
```

When enabled, the module attaches:

```text
arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

This allows the instance to be managed through AWS Systems Manager without requiring inbound SSH access.

To disable it:

```hcl
enable_ssm_access = false
```

---

## Amazon ECR Access

ECR read access is disabled by default.

Enable it when the EC2 instance needs to authenticate with Amazon ECR and pull private container images.

```hcl
enable_ecr_read_access = true
```

When enabled, the module attaches:

```text
arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

The instance can then use the AWS CLI and Docker to authenticate against ECR using its instance IAM role.

No static AWS credentials are required.

---

## Route 53 Access

Route 53 write access is disabled by default.

Enable it only when the instance needs to modify records in a specific hosted zone.

```hcl
enable_route53_write_access = true
hosted_zone_id              = module.dns_acm.private_zone_id
```

The module restricts the Route 53 permission to the supplied hosted zone.

Only the following Route 53 operation is granted:

```text
route53:ChangeResourceRecordSets
```

The `hosted_zone_id` must be supplied when Route 53 access is enabled.

---

## User Data

The module accepts caller-provided user data.

The `user_data` variable is expected to contain a base64-encoded script because it is supplied to the EC2 resource through `user_data_base64`.

Example:

```hcl
user_data = base64encode(templatefile(
  "${path.module}/scripts/user-data.sh",
  {
    project_name = var.project_name
  }
))
```

If the instance does not require user data:

```hcl
user_data = null
```

The module intentionally does not embed application-specific bootstrap logic.

The calling infrastructure owns the application bootstrap process.

---

## Public IP Address

Instances are private by default.

```hcl
associate_public_ip_address = false
```

A public IPv4 address can be explicitly enabled:

```hcl
associate_public_ip_address = true
```

For most internal workloads, keeping this disabled is recommended.

---

## Root Storage

The module creates an encrypted root EBS volume.

Default configuration:

```hcl
root_volume_size = 15
root_volume_type = "gp3"
```

The root volume is:

* encrypted
* GP3
* deleted when the instance terminates

The size can be increased when the workload requires additional disk capacity.

Example:

```hcl
root_volume_size = 30
```

---

## Ubuntu AMI

The module dynamically selects the latest matching Ubuntu 24.04 LTS AMD64 AMI.

The AMI is discovered through AWS data sources rather than requiring the caller to provide an AMI ID.

This allows the module to remain reusable across AWS regions.

---

## Resource Naming

Resources use the following naming convention:

```text
project_name-environment-service_name
```

For example:

```text
my-project-development-db-hub
```

The service name makes it possible to deploy multiple compute workloads within the same project and environment without resource-name collisions.

---

## Inputs

| Name                          | Type     | Default       | Description                                                  |
| ----------------------------- | -------- | ------------- | ------------------------------------------------------------ |
| `project_name`                | `string` | —             | Name of the project using the module                         |
| `environment`                 | `string` | —             | Deployment environment                                       |
| `service_name`                | `string` | —             | Logical service or workload name                             |
| `subnet_id`                   | `string` | —             | Subnet where the EC2 instance will be deployed               |
| `security_group_id`           | `string` | —             | Security group attached to the EC2 instance                  |
| `instance_type`               | `string` | `"t3.medium"` | EC2 instance type                                            |
| `associate_public_ip_address` | `bool`   | `false`       | Whether the instance receives a public IPv4 address          |
| `user_data`                   | `string` | `null`        | Base64-encoded EC2 user-data script                          |
| `root_volume_size`            | `number` | `15`          | Root EBS volume size in GiB                                  |
| `root_volume_type`            | `string` | `"gp3"`       | Root EBS volume type                                         |
| `enable_ssm_access`           | `bool`   | `true`        | Whether to enable AWS Systems Manager access                 |
| `enable_ecr_read_access`      | `bool`   | `false`       | Whether to enable Amazon ECR read access                     |
| `enable_route53_write_access` | `bool`   | `false`       | Whether to enable Route 53 record modification               |
| `hosted_zone_id`              | `string` | `null`        | Route 53 hosted zone ID used when Route 53 access is enabled |

---

## Outputs

The module exposes:

### EC2

* `instance_id`
* `instance_arn`
* `private_ip`
* `private_dns`
* `availability_zone`
* `subnet_id`

### IAM

* `iam_role_name`
* `iam_role_arn`
* `instance_profile_name`
* `instance_profile_arn`

---

## Complete Example

A complete working example is available under:

```text
examples/complete/
```

The example demonstrates how to consume the module from another Terraform configuration.

---

## Requirements

* Terraform `>= 1.6.0`
* AWS provider `>= 6.0.0, < 7.0.0`
* AWS account with permissions to create EC2 and IAM resources
* Appropriate networking resources supplied by the caller

---

## Module Responsibility

This module is responsible for:

```text
EC2 Instance
      │
      ├── Ubuntu AMI
      ├── Instance Type
      ├── Root EBS Volume
      ├── Security Group Association
      ├── Subnet Placement
      ├── IAM Instance Profile
      └── User Data
```

Optional IAM capabilities:

```text
      ├── SSM
      ├── ECR Read
      └── Route 53 Write
```

---

## What This Module Does Not Create

The module intentionally does not create:

* VPC
* Subnets
* Security Groups
* Route Tables
* Internet Gateway
* NAT Gateway
* Application Load Balancer
* Target Groups
* Route 53 Hosted Zones
* ACM Certificates
* ECR Repositories

Those resources belong to the surrounding infrastructure and are passed into this module through variables.

---

## Example Architecture Within a Core Infrastructure

```text
                         CORE INFRASTRUCTURE
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
        VPC / Subnets       Security Groups      Route 53 / ACM
             │                    │                    │
             └────────────────────┼────────────────────┘
                                  │
                                  ▼
                    ┌────────────────────────┐
                    │   terraform-aws-compute │
                    └────────────┬───────────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │ EC2 Instance  │
                         │               │
                         │ Ubuntu 24.04  │
                         │ Private IP    │
                         │ Encrypted EBS │
                         └───────┬───────┘
                                 │
                                 ▼
                         IAM Instance Role
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ▼                ▼                ▼
               SSM              ECR            Route 53
             optional         optional         optional
```

This architecture allows the core infrastructure to provide the shared AWS foundation while individual services determine how their compute resources are configured.

---

## Design Goal

The primary goal of this module is to provide a **small, predictable, reusable EC2 compute primitive**.

The module should remain independent of application-specific deployment logic while still providing the IAM capabilities commonly required by workloads running on the instance.

That makes the same module suitable for development, staging, production, and other AWS environments.
