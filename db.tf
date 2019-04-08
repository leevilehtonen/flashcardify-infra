resource "aws_db_instance" "default" {
  allocated_storage           = 20
  allow_major_version_upgrade = true
  apply_immediately           = true
  multi_az                    = false
  db_subnet_group_name        = "${aws_db_subnet_group.default.id}"
  engine                      = "postgres"
  engine_version              = "11.1"
  instance_class              = "db.t2.micro"
  identifier                  = "${var.project_name}-rds-${terraform.workspace}"
  username                    = "postgres"
  password                    = "${aws_ssm_parameter.password.value}"
  name                        = "${var.project_name}"
  storage_encrypted           = false
  storage_type                = "gp2"
  skip_final_snapshot         = true

  tags {
    Name = "${var.project_name}-rds-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-rds-subnet-group-${terraform.workspace}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags {
    Name = "${var.project_name}-rds-subnet-group-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "random_string" "password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "password" {
  name        = "${local.ssm_db_password_name}"
  description = "Master password for RDS"
  type        = "SecureString"
  value       = "${random_string.password.result}"
}
