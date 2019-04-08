locals {
  ecs_container_names  = "${formatlist("%s-%s-container-%s", var.project_name, var.services, terraform.workspace)}"
  ecs_service_names    = "${formatlist("%s-%s-service-%s", var.project_name, var.services, terraform.workspace)}"
  ecs_task_names       = "${formatlist("%s-%s-task-%s", var.project_name, var.services, terraform.workspace)}"
  ecs_repository_names = "${formatlist("%s-%s-repository-%s", var.project_name, var.services, terraform.workspace)}"
  ssm_db_password_name = "/${terraform.workspace}/${var.project_name}/database/password/master"
}
