########################################################################################################################
## Creates ECS Task Definition
########################################################################################################################

resource "aws_ecs_task_definition" "sinatra_task" {
  family                   = "service"
  network_mode             = "host" # Use 'awsvpc' to use ENI and apply task security group
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["EC2"]
  memory                   = 512

  container_definitions    = jsonencode([
    {
      name          = var.service_name,
      image         = "${var.ecs_repository_url}:${var.ecs_image_tag}",
      essential     = true
      memory        = var.memory
      cpu           = var.cpu_units
      portMappings  = [
        {
          hostPort      = var.container_port
          containerPort = var.container_port
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
