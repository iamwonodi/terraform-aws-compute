################################################################################
# EC2 INSTANCE OUTPUTS
################################################################################

output "instance_id" {
  description = "ID of the example EC2 instance."
  value       = module.compute.instance_id
}

output "private_ip" {
  description = "Private IP address of the example EC2 instance."
  value       = module.compute.private_ip
}

output "private_dns" {
  description = "Private DNS name of the example EC2 instance."
  value       = module.compute.private_dns
}


################################################################################
# IAM OUTPUTS
################################################################################

output "instance_profile_name" {
  description = "IAM instance profile supplied to the compute module."
  value       = module.compute.instance_profile_name
}