resource "aws_appautoscaling_target" "ecs_target" {
  count              = "${length(var.services)}"
  max_capacity       = 4
  min_capacity       = 0
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.*.name[count.index]}"
  role_arn           = "${aws_iam_role.task_autoscaling.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
