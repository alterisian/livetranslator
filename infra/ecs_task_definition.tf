########################################################################################################################
## Creates ECS Task Definition
########################################################################################################################

resource "aws_ecs_task_definition" "sinatra_task" {
  family                   = "fargate-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions    = jsonencode([
    {
      name          = var.service_name,
      image         = "${var.ecs_repository_url}:${var.ecs_image_tag}",
      cpu           = var.cpu_units
      memory        = var.memory
      essential     = true
      portMappings  = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${var.service_name}-log-stream-${var.environment}"
        }
      }
    }
  ])
}
