variable "project_name" {}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
}

variable "region" {
  type    = "string"
  default = "eu-west-1"
}

variable "services" {
  type = "list"
}

variable "service_port" {
  description = "Port where the service will run"
}

variable "task_count" {
  description = "Count of tasks running in one ECS service"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}
