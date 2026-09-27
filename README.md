# Terraform AWS Compute Module

A reusable Terraform module for provisioning a single AWS EC2 compute instance.

The module is intentionally designed as a **small, predictable compute primitive**. It focuses on provisioning and configuring the EC2 instance itself while allowing surrounding infrastructure such as networking, IAM, security groups, and AMI selection to be controlled by the calling infrastructure.

The module can consume:

* A caller-supplied AMI
* The latest matching Ubuntu AMI when no custom AMI is supplied
* A caller-supplied IAM instance profile
* Caller-supplied subnet and security group
* Configurable EC2 instance type
* Configurable encrypted root EBS volume
* Optional public IPv4 address
* Optional user-data bootstrap

---

## Architecture

The compute module is responsible only for the EC2 workload.

```text
                         CORE INFRASTRUCTURE
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
        VPC / Subnets       Security Groups      IAM Profile
              │                   │                   │
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  │
                                  ▼
                       ┌──────────────────────┐
                       │   Compute Module     │
                       │                      │
                       │     EC2 Instance     │
                       └──────────┬───────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
                   AMI       Root EBS       User Data
```

The caller owns the supporting infrastructure and supplies the required resource identifiers to the compute module.

This separation keeps the module reusable across different network architectures and workload types.

---

## Supporting Infrastructure

The compute module does **not** create the surrounding AWS infrastructure.

The caller supplies:

* VPC/subnet
* Security group
* IAM instance profile
* AMI, when a custom AMI is required
* Route 53 resources, when required by the workload
* Any other supporting infrastructure

Example:

```hcl
module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "db-hub"

  subnet_id         = module.vpc_base.internal_subnet_ids[0]
  security_group_id = module.security_groups.internal_security_group_id

  instance_profile_name = module.aws_profile.instance_profile_name

  ami_id = module.ubuntu_ami.ami_id

  instance_type = "t3.medium"
}
```

---

# Features

The module provides:

* Single EC2 instance provisioning
* Caller-supplied AMI support
* Automatic Ubuntu AMI discovery when no custom AMI is supplied
* Configurable EC2 instance type
* Configurable subnet
* Configurable security group
* Caller-supplied IAM instance profile
* Encrypted root EBS volume
* GP3 or GP2 root volume support
* Configurable root volume size
* Private networking by default
* Optional public IPv4 address
* Optional user-data bootstrap
* Consistent resource naming
* Consistent resource tagging
* Lifecycle protection through `create_before_destroy`

---

# Design Principles

## Generic and Reusable

The module does not contain application-specific configuration.

The caller determines:

* Project
* Environment
* Service
* AMI
* IAM instance profile
* Subnet
* Security group
* Instance type
* Root volume configuration
* Public IP behavior
* User-data configuration

This allows the same module to be reused for:

* Internal services
* Worker processes
* Administrative hosts
* Database utilities
* Docker hosts
* Application support services
* Development utilities
* Bastion-style workloads
* Compute workloads using custom golden AMIs

---

## Separation of Responsibilities

The compute module intentionally does not manage IAM policy decisions.

IAM is handled independently.

For example:

```text
                    AWS PROFILE MODULE
                           │
                           ▼
                     IAM Role
                           │
                 ┌─────────┼─────────┐
                 │         │         │
                SSM       ECR     Route 53
                 │         │         │
                 └─────────┼─────────┘
                           │
                           ▼
                  IAM Instance Profile
                           │
                           │ supplied to
                           ▼
                    COMPUTE MODULE
                           │
                           ▼
                      EC2 Instance
```

This allows the same IAM profile module to be reused by:

* EC2
* EC2 Image Builder
* Other EC2-based workloads

The compute module therefore does not need to recreate IAM roles or policies for every workload.

---

# IAM Instance Profile

The compute module expects the caller to provide an IAM instance profile.

Example:

```hcl
instance_profile_name = module.aws_profile.instance_profile_name
```

The compute module attaches the supplied profile to the EC2 instance:

```hcl
instance_profile_name = var.instance_profile_name
```

The compute module does not create:

* IAM roles
* IAM policies
* IAM policy attachments
* IAM instance profiles

Those responsibilities belong to the caller or a dedicated IAM/profile module.

This provides a cleaner separation between:

```text
Identity
   │
   └── aws-profile module

Compute
   │
   └── compute module
```

---

# AMI Selection

The module supports two AMI strategies.

## Caller-Supplied AMI

The caller can explicitly provide an AMI.

```hcl
ami_id = module.ubuntu_ami.ami_id
```

This is the recommended approach when the infrastructure uses a golden AMI created by the separate Ubuntu AMI module.

For example:

```text
Ubuntu Parent AMI
        │
        ▼
 Ubuntu AMI Module
        │
        ▼
   Golden AMI
        │
        ▼
 Compute Module
        │
        ▼
   EC2 Instance
```

This allows the compute workload to use a known, versioned AMI rather than dynamically selecting a new base image.

---

## Automatic Ubuntu AMI Selection

If the caller leaves the AMI variable as `null`, the module can fall back to its built-in Ubuntu AMI lookup.

Conceptually:

```hcl
ami_id = null
```

causes the module to use its Ubuntu AMI data source.

This provides a convenient default for workloads that do not require a custom golden AMI.

The caller therefore has two choices:

```text
ami supplied
    │
    └── Use supplied AMI

ami_id = null
    │
    └── Use module's Ubuntu AMI lookup
```

---

# Golden AMI Integration

For environments using the separate Ubuntu AMI module, the recommended architecture is:

```text
                 Ubuntu Parent AMI
                         │
                         ▼
                ┌─────────────────┐
                │ Ubuntu AMI      │
                │ Module          │
                └────────┬────────┘
                         │
                         ▼
                   Golden AMI
                         │
                         ▼
                ┌─────────────────┐
                │ Compute Module  │
                └────────┬────────┘
                         │
                         ▼
                    EC2 Instance
```

The core infrastructure can therefore build the AMI independently and pass the resulting AMI ID to compute.

Example:

```hcl
module "ubuntu_ami" {
  source = "git::https://github.com/iamwonodi/terraform-aws-ubuntu-ami.git?ref=v1.1.0"

  # Ubuntu AMI configuration
}
```

Then:

```hcl
module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "db-hub"

  # The golden AMI is built in the same apply, so its ID is unknown at plan
  # time: say outright that no Ubuntu lookup is wanted.
  ami_id             = module.ubuntu_ami.ami_id
  ami_lookup_enabled = false

  subnet_id         = module.vpc_base.internal_subnet_ids[0]
  security_group_id = module.security_groups.internal_security_group_id

  instance_profile_name = module.aws_profile.instance_profile_name

  instance_type = "t3.medium"
}
```

This is preferable when the organization wants consistent, preconfigured operating-system images.

---

# Private by Default

The EC2 instance does not receive a public IPv4 address unless explicitly requested.

```hcl
associate_public_ip_address = false
```

This makes the module suitable for:

* Private subnets
* Internal subnets
* Isolated workloads
* Backend services
* Database support workloads

A public IP can be explicitly enabled:

```hcl
associate_public_ip_address = true
```

The surrounding networking architecture remains the responsibility of the caller.

---

# Caller-Owned Networking

The module does not create:

* VPCs
* Subnets
* Route tables
* Internet gateways
* NAT gateways
* Security groups

The caller supplies the appropriate resource IDs.

Example:

```hcl
subnet_id = module.vpc_base.internal_subnet_ids[0]

security_group_id = module.security_groups.internal_security_group_id
```

This prevents the compute module from making assumptions about the caller's network architecture.

---

# User Data

The module supports caller-provided user data.

Example:

```hcl
user_data = base64encode(templatefile(
  "${path.module}/scripts/user-data.sh",
  {
    project_name = var.project_name
  }
))
```

If user data is not required:

```hcl
user_data = null
```

The module intentionally does not embed application-specific bootstrap commands.

The calling infrastructure owns application initialization.

---

# Root Storage

The module creates an encrypted root EBS volume.

Default configuration:

```hcl
root_volume_size = 15
root_volume_type = "gp3"
```

The root volume is:

* Encrypted
* GP3 by default
* Deleted when the instance terminates
* Configurable in size

Example:

```hcl
root_volume_size = 30
```

The volume type can be:

```hcl
root_volume_type = "gp3"
```

or:

```hcl
root_volume_type = "gp2"
```

---

# Resource Naming

Resources use the following naming convention:

```text
project_name-environment-service_name
```

For example:

```text
my-project-production-db-hub
```

The IAM instance profile is not created by this module, so IAM naming is controlled by the module or infrastructure responsible for creating that profile.

The compute instance and root volume use names derived from the project, environment, and service.

---

# Inputs

The following inputs represent the core interface of the compute module.

| Name                          | Type     | Default       | Description                                                                |
| ----------------------------- | -------- | ------------- | -------------------------------------------------------------------------- |
| `project_name`                | `string` | —             | Name of the project using the module                                       |
| `environment`                 | `string` | —             | Deployment environment                                                     |
| `service_name`                | `string` | —             | Logical service or workload name                                           |
| `ami_id`                      | `string` | `null`        | Optional AMI ID. When null, the module falls back to its Ubuntu AMI lookup |
| `ami_lookup_enabled`          | `bool`   | `null`        | Whether to run the Ubuntu AMI lookup. When null, it runs only if `ami_id` is null. Set `false` when `ami_id` is known only after apply |
| `subnet_id`                   | `string` | —             | Subnet where the EC2 instance is deployed                                  |
| `security_group_id`           | `string` | —             | Security group attached to the EC2 instance                                |
| `instance_profile_name`       | `string` | `null`        | IAM instance profile supplied by the caller                                |
| `instance_type`               | `string` | `"t3.medium"` | EC2 instance type                                                          |
| `associate_public_ip_address` | `bool`   | `false`       | Whether the instance receives a public IPv4 address                        |
| `user_data`                   | `string` | `null`        | Optional base64-encoded user-data script                                   |
| `root_volume_size`            | `number` | `15`          | Root EBS volume size in GiB                                                |
| `root_volume_type`            | `string` | `"gp3"`       | Root EBS volume type                                                       |

---

# Outputs

The module exposes the following EC2 outputs.

## EC2

* `instance_id`
* `instance_arn`
* `private_ip`
* `private_dns`
* `availability_zone`
* `subnet_id`

The module does not expose IAM role or instance-profile outputs because IAM resources are not created by this module.

The caller already owns the IAM profile supplied to the compute instance.

---

# Complete Example

A complete working example is available under:

```text
examples/complete/
```

The example demonstrates how to consume the compute module from another Terraform configuration.

The example provides:

```text
examples/
└── complete/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

# Example

A minimal example:

```hcl
module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "example-worker"

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  instance_profile_name = var.instance_profile_name

  ami_id = var.ami_id

  instance_type = "t3.medium"

  associate_public_ip_address = false

  root_volume_size = 15
  root_volume_type = "gp3"

  user_data = null
}
```

---

# Example Using the Ubuntu AMI Module

When using the dedicated Ubuntu AMI module:

```hcl
module "ubuntu_ami" {
  source = "git::https://github.com/iamwonodi/terraform-aws-ubuntu-ami.git?ref=v1.1.0"

  # Ubuntu AMI configuration
}
```

The resulting AMI can be supplied directly to compute:

```hcl
module "compute" {
  source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"

  project_name = var.project_name
  environment  = var.environment
  service_name = "example-worker"

  ami_id = module.ubuntu_ami.ami_id

  subnet_id         = module.vpc_base.private_subnet_ids[0]
  security_group_id = module.security_groups.compute_security_group_id

  instance_profile_name = module.aws_profile.instance_profile_name

  instance_type = "t3.medium"
}
```

This gives the core infrastructure a clean dependency chain:

```text
aws-profile
     │
     │ instance profile
     ▼
compute ◄──── ami
     │         ▲
     │         │
     ▼      ubuntu-ami
    EC2
```

---

# Testing

```powershell
terraform fmt -recursive
terraform init
terraform validate
terraform test
```

`terraform test` plans the module against a mocked AWS provider (no credentials needed), including with an AMI ID that is unknown until apply.

---

# Releases

* `v1.2.0` adds `ami_lookup_enabled`. `v1.1.0` decided whether to look up Ubuntu with `count = var.ami_id == null ? 1 : 0`, which Terraform cannot plan when `ami_id` is known only after apply (a golden AMI built in the same apply): "Invalid count argument". Set `ami_lookup_enabled = false` in that case. Left null, the module behaves exactly as `v1.1.0`. This README's inputs table and examples now use the module's real input names (`ami_id`, `instance_profile_name`).
* `v1.1.0` caller-supplied AMI.

---

# What This Module Does Not Create

The module intentionally does not create:

* IAM roles
* IAM policies
* IAM instance profiles
* VPC
* Subnets
* Route tables
* Internet Gateway
* NAT Gateway
* Security Groups
* Application Load Balancer
* Target Groups
* Route 53 Hosted Zones
* ACM Certificates
* ECR Repositories
* Ubuntu golden AMIs

These resources belong to surrounding infrastructure or dedicated reusable modules.

---

# Module Responsibility

The compute module is responsible for:

```text
EC2 Instance
     │
     ├── AMI
     ├── Instance Type
     ├── Subnet Placement
     ├── Security Group Association
     ├── IAM Instance Profile Association
     ├── Root EBS Volume
     ├── Public IP Configuration
     └── User Data
```

The module does not own the resources represented by the supplied IDs.

For example:

```text
IAM Profile Module
        │
        ▼
IAM Instance Profile
        │
        │ supplied to
        ▼
Compute Module
        │
        ▼
EC2 Instance
```

---

# Example Architecture Within Core Infrastructure

```text
                         CORE INFRASTRUCTURE
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
     VPC / Subnets          Security Groups          IAM Profile
          │                       │                       │
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ Compute Module  │
                         └────────┬────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    ▼             ▼             ▼
                   AMI         Root EBS     User Data
                    │
                    ▼
               EC2 Instance
```

When a golden AMI is used:

```text
                         CORE INFRASTRUCTURE

       ┌──────────────────┐
       │ Ubuntu AMI       │
       │ Module            │
       └────────┬─────────┘
                │
                ▼
           Golden AMI
                │
                │
                ▼
       ┌──────────────────┐
       │ Compute Module   │
       └────────┬─────────┘
                │
                ▼
           EC2 Instance
                ▲
                │
       IAM Instance Profile
                ▲
                │
       ┌──────────────────┐
       │ AWS Profile      │
       │ Module            │
       └──────────────────┘
```

This architecture keeps the reusable modules independently responsible for their own concerns.

---

# Module Composition

The recommended architecture is to compose several focused modules rather than building one large compute module.

```text
terraform-aws-vpc-base
          │
          ▼
       Network
          │
          │
terraform-aws-aws-profile
          │
          ▼
    IAM Instance Profile
          │
          │
terraform-aws-ubuntu-ami
          │
          ▼
       Golden AMI
          │
          │
          ▼
terraform-aws-compute
          │
          ▼
      EC2 Instance
```

Each module has a clear responsibility:

| Module        | Responsibility                                 |
| ------------- | ---------------------------------------------- |
| `vpc-base`    | VPC and subnet infrastructure                  |
| `aws-profile` | EC2 IAM roles, policies, and instance profiles |
| `ubuntu-ami`  | Ubuntu golden AMI creation                     |
| `compute`     | EC2 instance provisioning                      |

This makes the infrastructure easier to maintain, test, version, and reuse.

---

# Requirements

* Terraform `>= 1.6.0`
* AWS provider `>= 6.0.0, < 7.0.0`
* AWS account with permission to create EC2 resources
* Existing VPC/subnet
* Existing security group
* Existing IAM instance profile
* Appropriate permissions for the caller

If a custom AMI is supplied, the caller must also have permission to use that AMI.

---

# Versioning

The module follows semantic versioning.

Example:

```text
v1.0.0
v1.1.0
v1.2.0
```

Reference a specific version from Git:

```hcl
source = "git::https://github.com/iamwonodi/terraform-aws-compute.git?ref=v1.2.0"
```

Using a version tag ensures that consuming infrastructure does not unexpectedly change when the module repository is updated.

---

# Design Goal

The primary goal of this module is to provide a:

**small, predictable, reusable EC2 compute primitive.**

The module intentionally avoids owning unrelated infrastructure.

Its responsibility is simple:

```text
Input
 │
 ├── AMI
 ├── IAM Instance Profile
 ├── Subnet
 ├── Security Group
 ├── Instance Type
 ├── Storage
 └── User Data
 │
 ▼
EC2 Instance
```

This allows the surrounding infrastructure to compose the compute module with independently versioned networking, IAM, AMI, DNS, security, and other infrastructure modules.
