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

output "iam_role_name" {
  description = "Name of the IAM role attached to the compute instance."

  value = aws_iam_role.compute.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the compute instance."

  value = aws_iam_role.compute.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile attached to the compute instance."

  value = aws_iam_instance_profile.compute.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile attached to the compute instance."

  value = aws_iam_instance_profile.compute.arn
}