########################################################################################################################
## Creates ECS Task Definition
########################################################################################################################

resource "aws_ecs_task_definition" "task" {
  for_each = var.services

  family                   = "service"
  network_mode             = "host" # Use 'awsvpc' to use ENI and apply task security group
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["EC2"]
  # memory                   = 512 -- optional, use in case of Fargate

  container_definitions = jsonencode([
    {
      name      = each.value.service_name,
      image     = each.value.image,
      essential = true
      memory    = each.value.memory
      cpu       = each.value.cpu_units
      command   = each.value.command
      portMappings = [for port in each.value.container_ports :
        {
          hostPort      = port
          containerPort = port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${each.value.service_name}-log-stream"
        }
      }
      environment = [
        { name = "OPENAI_API_KEY", value = data.aws_ssm_parameter.openai_api_key.value }
      ]
      mountPoints = [
        {
          sourceVolume  = "live-audio"
          containerPath = "/app/live-audio"
          readOnly      = false
        },
        {
          sourceVolume  = "live-text"
          containerPath = "/app/live-text"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "live-audio"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  volume {
    name = "live-text"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }
}
