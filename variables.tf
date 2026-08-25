variable "project_name" {
  type        = string
  description = "Name of the project using the compute instance."

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment such as development, staging, or production."

  validation {
    condition     = trimspace(var.environment) != ""
    error_message = "environment must not be empty."
  }
}

variable "service_name" {
  type        = string
  description = "Logical name of the service or workload running on the compute instance."

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must not be empty."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be deployed."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the EC2 instance."
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID to use for the EC2 instance. When null, the module uses the latest matching Ubuntu AMI."

  default = null

  validation {
    condition = (
      var.ami_id == null ||
      trimspace(var.ami_id) != ""
    )

    error_message = "ami_id must be null or a non-empty AMI ID."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."

  default = "t3.medium"
}

variable "instance_profile_name" {
  type        = string
  description = "Optional IAM instance profile to attach to the EC2 instance."

  default = null

  validation {
    condition = (
      var.instance_profile_name == null ||
      trimspace(var.instance_profile_name) != ""
    )

    error_message = "instance_profile_name must be null or a non-empty string."
  }
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether the EC2 instance should receive a public IPv4 address."

  default = false
}

variable "user_data" {
  type        = string
  description = "Optional base64-encoded user-data script."

  default = null
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root EBS volume in GiB."

  default = 15

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  type        = string
  description = "EBS volume type for the root volume."

  default = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.root_volume_type)
    error_message = "root_volume_type must be either gp3 or gp2."
  }
}
