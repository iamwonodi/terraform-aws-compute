################################################################################
# DEFAULT UBUNTU AMI
#
# Used only when the caller does not provide an explicit AMI ID (see
# local.ami_lookup_enabled).
################################################################################


data "aws_ami" "ubuntu" {
  count = local.ami_lookup_enabled ? 1 : 0

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