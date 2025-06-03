########################################################################################################################
## Creates EC2 Auto Scaling group as ECS Cluster Capacity Provider
########################################################################################################################

locals {
  name = "${var.namespace}_EC2_ASG_${var.environment}"
  tags = {
    Name             = "${local.name}",
    AmazonECSManaged = "true"
  }
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_autoscaling_group" "default" {
  name                = local.name
  vpc_zone_identifier = data.aws_subnets.public.ids
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.default.id
    version = "$Latest"
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.namespace}_ECS_Capacity_Provider_${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.default.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status = "ENABLED"

      target_capacity           = 1
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }
}


########################################################################################################################
## EC2 Instance launch template, security group, instance profile and IAM role
########################################################################################################################

resource "aws_launch_template" "default" {
  name_prefix = "${var.namespace}_LT_${var.environment}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.instance_type

  user_data = base64encode(<<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.namespace}_ECSCluster_${var.environment}
    ECS_LOGLEVEL=debug
    ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
    ECS_ENABLE_TASK_IAM_ROLE=true
    EOF
  EOT
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "gp3"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.aws_ec2_instance.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.default.name
  }
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.namespace}_ECSInstanceProfile_${var.environment}"
  role = aws_iam_role.default.name
}

resource "aws_iam_role" "default" {
  name               = var.iam_role_name
  description        = "ECS role for ${var.iam_role_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
