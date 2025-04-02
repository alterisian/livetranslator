########################################################################################################################
## Creates ECS Service
########################################################################################################################

resource "aws_ecs_service" "service" {
  name                               = "${var.namespace}_ECS_Service_${var.environment}"
  cluster                            = aws_ecs_cluster.default.id
  task_definition                    = aws_ecs_task_definition.sinatra_task.arn
  launch_type                        = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_container_instance.id]
    subnets          = data.aws_subnets.public.ids
    assign_public_ip = true
  }

  desired_count = 1
}
