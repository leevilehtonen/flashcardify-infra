resource "aws_cloudwatch_log_group" "default" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "default" {
  name           = "${var.project_name}-ecs-log-stream"
  log_group_name = "${aws_cloudwatch_log_group.default.name}"
}
