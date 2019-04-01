resource "aws_ecs_cluster" "default" {
  name = "${var.project_name}-cluster-${terraform.workspace}"
}

resource "aws_ecr_repository" "default" {
  count = "${length(var.services)}"
  name  = "${var.project_name}-${var.services[count.index]}-${terraform.workspace}"
}

data "template_file" "container_definition" {
  template = "${file("container_definition.json.tpl")}"
  count    = "${length(var.services)}"

  vars {
    name = "${var.project_name}-${var.services[count.index]}-container-${terraform.workspace}"
    port = 80

    //image  = "${aws_ecr_repository.default.*.repository_url[count.index]}"
    image     = "nginxdemos/hello"
    cpu       = "${var.fargate_cpu}"
    memory    = "${var.fargate_memory}"
    log_group = "/ecs/${var.project_name}"
  }
}

resource "aws_ecs_task_definition" "default" {
  count                    = "${length(var.services)}"
  family                   = "${var.project_name}-${var.services[count.index]}-task-${terraform.workspace}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  execution_role_arn       = "${aws_iam_role.task_execution.id}"
  container_definitions    = "${data.template_file.container_definition.*.rendered[count.index]}"
}

resource "aws_ecs_service" "default" {
  count           = "${length(var.services)}"
  name            = "${var.project_name}-${var.services[count.index]}-service-${terraform.workspace}"
  cluster         = "${aws_ecs_cluster.default.arn}"
  desired_count   = "${var.task_count}"
  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.default.arn}"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_tasks.id}"]
    subnets          = ["${aws_subnet.private.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "${data.template_file.container_definition.vars.name}"
    container_port   = "${data.template_file.container_definition.vars.port}"
    target_group_arn = "${aws_alb_target_group.default.arn}"
  }
}
