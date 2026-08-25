################################################################################
# DEFAULT UBUNTU AMI
#
# Used only when the caller does not provide an explicit AMI ID.
################################################################################


data "aws_ami" "ubuntu" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true

  owners = [local.ami_owner]

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}