################################################################################
# COMPUTE MODULE EXAMPLE
################################################################################

module "compute" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  ami_id                = var.ami
  instance_type         = var.instance_type
  instance_profile_name = var.instance_profile_name

  associate_public_ip_address = false

  root_volume_size = 15
  root_volume_type = "gp3"

  user_data = null
}