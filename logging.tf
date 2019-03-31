resource "aws_cloudwatch_log_group" "default" {
  name              = "/ecs/${var.project-name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "default" {
  name           = "${var.project-name}-ecs-log-stream"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"
}
