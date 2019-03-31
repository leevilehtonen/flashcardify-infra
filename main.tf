terraform {
  backend "s3" {
    bucket  = "flashcardify-infra"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "${var.region}"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project-name}-vpc-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_subnet" "default" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.default.id}"

  tags = {
    Name = "${var.project-name}-subnet-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "default" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.default.*.id, count.index)}"
  route_table_id = "${aws_route_table.default.id}"
}

resource "aws_s3_bucket" "frontend" {
  bucket        = "flashcardify-frontend-${terraform.workspace}"
  force_destroy = true
  acl           = "public-read"
  policy        = "${data.aws_iam_policy_document.static_website.json}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  name = "${var.project-name}.${terraform.workspace}"
  vpc  = "${aws_vpc.default.id}"
}

resource "aws_service_discovery_service" "default" {
  count = "${length(var.services)}"
  name  = "${var.services[count.index]}"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.default.id}"

    dns_records {
      ttl  = 300
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_cluster" "default" {
  name = "flashcardify-cluster-${terraform.workspace}"
}

resource "aws_ecr_repository" "default" {
  count = "${length(var.services)}"
  name  = "${var.services[count.index]}-${terraform.workspace}"
}

data "template_file" "container_definition" {
  template = "${file("container_definition.json.tpl")}"
  count    = "${length(var.services)}"

  vars {
    name = "${var.services[count.index]}-${terraform.workspace}-container"

    //image  = "${aws_ecr_repository.default.*.repository_url[count.index]}"
    image     = "httpd:2.4"
    cpu       = "${var.fargate_cpu}"
    memory    = "${var.fargate_memory}"
    log_group = "/ecs/${var.project-name}"
  }
}

resource "aws_ecs_task_definition" "default" {
  count                    = "${length(var.services)}"
  family                   = "${var.services[count.index]}-${terraform.workspace}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  execution_role_arn       = "${aws_iam_role.task_execution.id}"
  container_definitions    = "${data.template_file.container_definition.*.rendered[count.index]}"
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-tasks-security-group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "default" {
  count           = "${length(var.services)}"
  name            = "${var.services[count.index]}-${terraform.workspace}"
  cluster         = "${aws_ecs_cluster.default.arn}"
  desired_count   = "${var.task_count}"
  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.default.arn}"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_tasks.id}"]
    subnets          = ["${aws_subnet.default.*.id}"]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = "${aws_service_discovery_service.default.arn}"
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.name}"
  role_arn           = "${aws_iam_role.task_autoscaling.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "/ecs/${var.project-name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "default" {
  name           = "${var.project-name}-ecs-log-stream"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"
}
