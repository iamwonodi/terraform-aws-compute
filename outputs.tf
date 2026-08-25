################################################################################
# EC2 INSTANCE OUTPUTS
################################################################################

output "instance_id" {
  description = "ID of the EC2 compute instance."

  value = aws_instance.compute.id
}

output "instance_arn" {
  description = "ARN of the EC2 compute instance."

  value = aws_instance.compute.arn
}

output "private_ip" {
  description = "Private IPv4 address assigned to the compute instance."

  value = aws_instance.compute.private_ip
}

output "private_dns" {
  description = "Private DNS name assigned to the compute instance."

  value = aws_instance.compute.private_dns
}

output "availability_zone" {
  description = "Availability Zone in which the compute instance is running."

  value = aws_instance.compute.availability_zone
}

output "subnet_id" {
  description = "Subnet containing the compute instance."

  value = aws_instance.compute.subnet_id
}

################################################################################
# IAM OUTPUTS
################################################################################

output "instance_profile_name" {
  description = "IAM instance profile supplied to the compute module."
  value       = aws_instance.compute.iam_instance_profile
}

