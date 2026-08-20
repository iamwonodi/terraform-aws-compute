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

output "iam_role_arn" {
  description = "IAM role ARN attached to the example instance."
  value       = module.compute.iam_role_arn
}