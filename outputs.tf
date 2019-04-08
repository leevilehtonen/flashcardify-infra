output "ecr_repositories" {
  value = "${aws_ecr_repository.default.*.repository_url}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.default.name}"
}

output "ecs_service_names" {
  value = "${local.ecs_service_names}"
}

output "ecs_container_names" {
  value = "${local.ecs_container_names}"
}
