resource "aws_ecs_cluster" "default" {
  name = "${var.project_name}-cluster-${terraform.workspace}"
}

resource "aws_ecr_repository" "default" {
  count = "${length(var.services)}"
  name  = "${local.ecs_repository_names[count.index]}"
}

data "template_file" "container_definition" {
  template = "${file("container_definition.json.tpl")}"
  count    = "${length(var.services)}"

  vars {
    name  = "${local.ecs_container_names[count.index]}"
    port  = "${var.service_port}"
    image = "${aws_ecr_repository.default.*.repository_url[count.index]}"

    //image     = "nginxdemos/hello"
    cpu       = "${var.fargate_cpu}"
    memory    = "${var.fargate_memory}"
    log_group = "/ecs/${var.project_name}"
  }
}

resource "aws_ecs_task_definition" "default" {
  count                    = "${length(var.services)}"
  family                   = "${local.ecs_task_names[count.index]}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  execution_role_arn       = "${aws_iam_role.task_execution.id}"
  container_definitions    = "${data.template_file.container_definition.*.rendered[count.index]}"
}

resource "aws_ecs_service" "default" {
  count           = "${length(var.services)}"
  name            = "${local.ecs_service_names[count.index]}"
  cluster         = "${aws_ecs_cluster.default.arn}"
  desired_count   = "${var.task_count}"
  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.default.*.arn[count.index]}"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_tasks.*.id[count.index]}"]
    subnets          = ["${aws_subnet.private.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "${local.ecs_container_names[count.index]}"
    container_port   = "${var.service_port}"
    target_group_arn = "${aws_alb_target_group.default.*.arn[count.index]}"
  }
}
