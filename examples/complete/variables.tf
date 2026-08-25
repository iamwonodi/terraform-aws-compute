################################################################################
# PROJECT
################################################################################

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
  description = "Logical name of the compute workload."
  default     = "example-worker"
}


################################################################################
# NETWORK
################################################################################

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be deployed."
}

variable "security_group_id" {
  type        = string
  description = "Security group ID attached to the EC2 instance."
}


################################################################################
# COMPUTE
################################################################################

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.medium"
}


################################################################################
# AMI
################################################################################

variable "ami" {
  type        = string
  description = "AMI ID supplied by the caller. This can be an AMI created by the Ubuntu AMI module or another compatible AMI otherwise defaults to Null."
  default     = null
}


################################################################################
# IAM
################################################################################

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name supplied by the caller."
}