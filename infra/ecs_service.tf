########################################################################################################################
## Creates ECS Service
########################################################################################################################

resource "aws_ecs_service" "service" {
  name            = "${var.namespace}_ECS_Service_${var.environment}"
  cluster         = aws_ecs_cluster.default.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.sinatra_task.arn

  depends_on      = [aws_ecs_task_definition.sinatra_task]

  # force_new_deployment = true
  
  # network_configuration {
  #  security_groups  = [aws_security_group.ecs_container_instance.id]
  #  subnets          = data.aws_subnets.public.ids
  # }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [desired_count, capacity_provider_strategy]
  }
}
