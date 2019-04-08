resource "aws_alb" "default" {
  count              = "${length(var.services)}"
  name               = "${var.services[count.index]}-service-lb-${terraform.workspace}"
  load_balancer_type = "application"
  subnets            = ["${aws_subnet.public.*.id}"]
  ip_address_type    = "ipv4"
  security_groups    = ["${aws_security_group.lb.id}"]

  tags {
    Project = "${var.project_name}"
    Env     = "${terraform.workspace}"
  }
}

resource "aws_alb_target_group" "default" {
  count       = "${length(var.services)}"
  name        = "${var.services[count.index]}-service-lb-tg-${terraform.workspace}"
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"
  vpc_id      = "${aws_vpc.default.id}"

  tags {
    Project = "${var.project_name}"
    Env     = "${terraform.workspace}"
  }

  depends_on = ["aws_alb.default"]
}

resource "aws_alb_listener" "default" {
  count             = "${length(var.services)}"
  load_balancer_arn = "${aws_alb.default.*.arn[count.index]}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.default.*.arn[count.index]}"
  }
}
