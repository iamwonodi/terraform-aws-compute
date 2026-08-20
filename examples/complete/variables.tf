
variable "project_name" {
  type        = string
  description = "Project name."
  default     = "example-project"
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  default     = "development"
}

variable "service_name" {
  type        = string
  description = "Compute service name."
  default     = "example-worker"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the EC2 instance."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for the EC2 instance."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.medium"
}