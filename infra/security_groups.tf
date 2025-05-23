########################################################################################################################
## SG for ECS Container Instances
########################################################################################################################

resource "aws_security_group" "aws_ec2_instance" {
  name        = "${var.namespace}_EC2_ASG_SecurityGroup_${var.environment}"
  description = "Security group for ASG EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.namespace}_EC2_ASG_SecurityGroup_${var.environment}"
  }
}

resource "aws_security_group_rule" "aws_ec2_instance_ingress" {
  for_each = var.services

  security_group_id = aws_security_group.aws_ec2_instance.id
  type              = "ingress"
  from_port         = each.value.container_port
  to_port           = each.value.container_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "aws_ec2_instance_egress" {
  security_group_id = aws_security_group.aws_ec2_instance.id
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
