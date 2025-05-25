########################################################################################################################
## Service variables
########################################################################################################################

variable "namespace" {
  description = "Namespace for project"
  default     = "livetranslator"
}

variable "environment" {
  description = "Environment for deployment"
  default     = "test"
}

variable "services" {
  description = "Map of services to deploy"
  default = {
    "sinatra" = {
      service_name    = "sinatra"
      image           = "jaysphoto/livetranslator:latest"
      container_ports = [4567]
      cpu_units       = 256
      memory          = 128
    },
    "transcriber" = {
      service_name    = "transcriber"
      image           = "jaysphoto/livetranslator:latest"
      container_ports = []
      cpu_units       = 256
      memory          = 128
      command         = ["ruby", "live_transcriber.rb"]
    },
    "livestream" = {
      service_name    = "livestream"
      image           = "jaysphoto/nginx-rtmp:latest"
      container_ports = [1935] # tcp/1935: RTMP endpoint for live streaming
      cpu_units       = 1024   # 1 vCPU
      memory          = 128
      essential       = false # Not essential for the task, can be stopped if needed
      mount_points = [        # Custom mount point for the livestream container
        {
          sourceVolume  = "live-audio"
          containerPath = "/opt/data/live_audio"
          readOnly      = false
        }
      ]
    }
  }
  type = map(object({
    service_name    = string
    image           = string
    container_ports = list(number)         # List of container ports to expose
    essential       = optional(bool, true) # Whether the container is essential for the task
    cpu_units       = number               # Amount of CPU units for a single ECS task (256 CPU units = 0.25 vCPU)
    memory          = number               # Amount of memory in MB for a single ECS task (512 MiB, 1 GB or 2 GB for 0.25 vCPU)
    command         = optional(list(string), null)
    mount_points = optional(
      list(object({
        sourceVolume  = string
        containerPath = string
        readOnly      = bool
      })),
      [{
        sourceVolume  = "live-audio"
        containerPath = "/app/live_audio"
        readOnly      = false
        },
        {
          sourceVolume  = "live-text"
          containerPath = "/app/live_text"
          readOnly      = false
      }]
    )
  }))
}


########################################################################################################################
## AWS credentials
########################################################################################################################

variable "region" {
  description = "AWS region"
  default     = "eu-south-2"
  type        = string
}


########################################################################################################################
## Network variables
########################################################################################################################

variable "az_count" {
  description = "Number of availability zones to use"
  default     = 1
  type        = number
}


########################################################################################################################
## ECS variables
########################################################################################################################

variable "ecs_task_desired_count" {
  description = "How many ECS tasks should run in parallel"
  default     = 1
  type        = number
}

variable "ecs_task_min_count" {
  description = "How many ECS tasks should minimally run in parallel"
  default     = 1
  type        = number
}

variable "ecs_task_max_count" {
  description = "How many ECS tasks should maximally run in parallel"
  default     = 1
  type        = number
}


########################################################################################################################
## EC2 + Autoscaling variables
########################################################################################################################
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
  type        = string
}

variable "iam_role_name" {
  description = "IAM role name for EC2 instance"
  default     = "ecs_instance_role"
  type        = string
}


########################################################################################################################
## Cloudwatch
########################################################################################################################

variable "retention_in_days" {
  description = "Retention period for Cloudwatch logs"
  default     = 3
  type        = number
}
