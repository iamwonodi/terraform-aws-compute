
module "compute" {
  source = "../../"

  project_name = var.project_name
  environment  = var.environment
  service_name = var.service_name

  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id

  instance_type = var.instance_type

  enable_ssm_access      = true
  enable_ecr_read_access = false

  associate_public_ip_address = false

  root_volume_size = 15
  root_volume_type = "gp3"

  user_data = null
}