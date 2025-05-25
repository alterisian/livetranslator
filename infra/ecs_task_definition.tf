########################################################################################################################
## Creates ECS Task Definition
########################################################################################################################

resource "aws_ecs_task_definition" "default" {
  family                   = "service"
  network_mode             = "host" # Use 'awsvpc' to use ENI and apply task security group
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["EC2"]
  # memory                   = 512 -- optional, use in case of Fargate

  container_definitions = jsonencode([for s in var.services :
    {
      name      = s.service_name,
      image     = s.image,
      essential = try(s.essential, true)
      memory    = s.memory
      cpu       = s.cpu_units
      command   = try(s.command, null)
      portMappings = [for port in s.container_ports :
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
          "awslogs-stream-prefix" = "log-stream"
        }
      }
      environment = [
        { name = "OPENAI_API_KEY", value = data.aws_ssm_parameter.openai_api_key.value },
        { name = "STREAM_KEY_NAME", value = data.aws_ssm_parameter.stream_key_name.value }
      ]
      mountPoints = try(s.mount_points, [
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
      ])
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
