########################################################################################################################
## SG for ECS Container Instances
########################################################################################################################

resource "aws_security_group" "ecs_container_instance" {
  name        = "${var.namespace}_ECS_Task_SecurityGroup_${var.environment}"
  description = "Security group for ECS task"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow ingress traffic from public to container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.namespace}_ECS_Task_SecurityGroup_${var.environment}"
  }
}

resource "aws_security_group" "aws_ec2_instance" {
  name        = "${var.namespace}_EC2_ASG_SecurityGroup_${var.environment}"
  description = "Security group for ASG EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow ingress traffic from public to EC2 host port"
    from_port   = var.host_port
    to_port     = var.host_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.namespace}_EC2_ASG_SecurityGroup_${var.environment}"
  }
}
