locals {
  ami_owner = "099720109477"

  ami_name = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"

  selected_ami_id = (
    var.ami_id != null
    ? var.ami_id
    : data.aws_ami.ubuntu[0].id
  )

  instance_name = "${var.project_name}-${var.environment}-${var.service_name}"

  iam_role_name = "${var.project_name}-${var.environment}-${var.service_name}-role"

  instance_profile_name = "${var.project_name}-${var.environment}-${var.service_name}-profile"

  root_volume_name = "${var.project_name}-${var.environment}-${var.service_name}-root-os-drive"

  common_tags = {
    Name        = local.instance_name
    Project     = var.project_name
    Environment = var.environment
    Service     = var.service_name
  }
}

