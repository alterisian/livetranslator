########################################################################################################################
## Service variables
########################################################################################################################

variable "namespace" {
    description = "Namespace for project"
    default     = "livetranslator"
}

variable "service_name" {
  description = "A Docker image-compatible name for the service"
  type        = string
  default     = "api"
}

variable "environment" {
    description = "Environment for deployment"
    default     = "test"
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

variable "container_port" {
  description = "Port of the container"
  type        = number
  default     = 4567
}

variable "cpu_units" {
  description = "Amount of CPU units for a single ECS task (256 CPU units = 0.25 vCPU)"
  default     = 256
  type        = number
}

variable "memory" {
  description = "Amount of memory in MB for a single ECS task (512 MiB, 1 GB or 2 GB for 0.25 vCPU)"
  default     = 128
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

variable "host_port" {
  description = "Public port of the EC2 instance"
  default     = 4567
  type        = number
}


########################################################################################################################
## Cloudwatch
########################################################################################################################

variable "retention_in_days" {
  description = "Retention period for Cloudwatch logs"
  default     = 3
  type        = number
}

########################################################################################################################
## ECR
########################################################################################################################

variable "ecs_repository_url" {
  description   = "Docker repository URL"
  type          = string
  default       = "jaysphoto/livetranslator"
}


variable "ecs_image_tag" {
  description   = "Docker image tag to pull from repository"
  type          = string
  default       = "latest"
}
