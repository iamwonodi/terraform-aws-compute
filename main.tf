################################################################################
# IAM ROLE
#
# One EC2 IAM role is created for the instance. Optional capabilities such as
# ECR access and Route 53 write access are attached to this role only when
# explicitly enabled by the caller.
################################################################################

resource "aws_iam_role" "compute" {
  name = local.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

################################################################################
# SSM ACCESS
################################################################################

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm_access ? 1 : 0

  role       = aws_iam_role.compute.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
# ECR READ ACCESS
#
# Allows the EC2 instance to authenticate with ECR and pull private images.
# No ECR permissions are granted unless explicitly enabled.
################################################################################

resource "aws_iam_role_policy_attachment" "ecr_read" {
  count = var.enable_ecr_read_access ? 1 : 0

  role       = aws_iam_role.compute.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

################################################################################
# ROUTE 53 WRITE POLICY
#
# Created only when Route 53 write access is explicitly enabled.
################################################################################

resource "aws_iam_policy" "route53_write" {
  count = var.enable_route53_write_access ? 1 : 0

  name = "${var.project_name}-${var.environment}-${var.service_name}-route53-write"

  description = "Allows ${var.service_name} to modify records in the specified Route 53 hosted zone."

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "route53:ChangeResourceRecordSets",
          # "route53:ListResourceRecordSets"
        ]

        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      }
    ]
  })

  tags = local.common_tags
}

################################################################################
# ROUTE 53 POLICY ATTACHMENT
################################################################################

resource "aws_iam_role_policy_attachment" "route53_write" {
  count = var.enable_route53_write_access ? 1 : 0

  role       = aws_iam_role.compute.name
  policy_arn = aws_iam_policy.route53_write[0].arn
}

################################################################################
# IAM INSTANCE PROFILE
################################################################################

resource "aws_iam_instance_profile" "compute" {
  name = local.instance_profile_name
  role = aws_iam_role.compute.name

  tags = local.common_tags
}

################################################################################
# EC2 INSTANCE
################################################################################

resource "aws_instance" "compute" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.compute.name

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

    precondition {
      condition = (
        !var.enable_route53_write_access ||
        (
          var.hosted_zone_id != null &&
          trimspace(var.hosted_zone_id) != ""
        )
      )

      error_message = "hosted_zone_id must be provided when enable_route53_write_access is true."
    }
  }
}