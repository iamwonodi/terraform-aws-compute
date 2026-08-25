
################################################################################
# EC2 INSTANCE
################################################################################

resource "aws_instance" "compute" {
  ami           = local.selected_ami_id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile = var.instance_profile_name

  associate_public_ip_address = var.associate_public_ip_address

  user_data_base64 = var.user_data

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type

    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = local.root_volume_name
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}
