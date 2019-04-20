data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "auto_scaling__assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "static_website" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["arn:aws:s3:::flashcardify-frontend-${terraform.workspace}/*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "ssm" {
  statement {
    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "${aws_ssm_parameter.db_password.arn}",
    ]

    effect = "Allow"
  }
}

data "aws_iam_policy" "task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "task_autoscaling" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_iam_policy" "ecs_ssm_policy" {
  name   = "${var.project_name}-ecs-ssm-policy"
  policy = "${data.aws_iam_policy_document.ssm.json}"
}

resource "aws_iam_role" "task_execution" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume.json}"
}

resource "aws_iam_role" "task_autoscaling" {
  name               = "ecsAutoscaleRole"
  assume_role_policy = "${data.aws_iam_policy_document.auto_scaling__assume.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = "${aws_iam_role.task_execution.id}"
  policy_arn = "${data.aws_iam_policy.task_execution.arn}"
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling" {
  role       = "${aws_iam_role.task_autoscaling.id}"
  policy_arn = "${data.aws_iam_policy.task_autoscaling.arn}"
}

resource "aws_iam_role_policy_attachment" "ecs_ssm" {
  role       = "${aws_iam_role.task_execution.id}"
  policy_arn = "${aws_iam_policy.ecs_ssm_policy.arn}"
}
