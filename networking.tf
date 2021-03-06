data "aws_availability_zones" "available" {}

resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "${var.project_name}-vpc-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_subnet" "private" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.default.id}"

  tags {
    Name = "${var.project_name}-private-subnet-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_subnet" "public" {
  count                   = "${var.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, 8, var.az_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.default.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.project_name}-public-subnet-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.project_name}-igw-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_eip" "nat" {
  count      = "${var.az_count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.default"]

  tags {
    Name = "${var.project_name}-eip-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "default" {
  depends_on    = ["aws_internet_gateway.default"]
  count         = "${var.az_count}"
  subnet_id     = "${aws_subnet.public.*.id[count.index]}"
  allocation_id = "${aws_eip.nat.*.id[count.index]}"

  tags {
    Name = "${var.project_name}-natgw-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_route_table" "private" {
  count  = "${var.az_count}"
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.default.*.id[count.index]}"
  }

  tags {
    Name = "${var.project_name}-private-route-table-${count.index}-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_route_table_association" "default" {
  count          = "${var.az_count}"
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}

resource "aws_security_group" "lb" {
  name   = "lb-security-group"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.project_name}-lb-sg-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_security_group" "ecs_tasks" {
  count  = "${length(var.services)}"
  name   = "${var.project_name}-${var.services[count.index]}-sg-${terraform.workspace}"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    protocol        = "tcp"
    from_port       = "${var.service_port}"
    to_port         = "${var.service_port}"
    security_groups = ["${aws_security_group.lb.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.project_name}-${var.services[count.index]}-sg-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg-${terraform.workspace}"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    protocol        = "6"
    from_port       = 5432
    to_port         = 5432
    security_groups = ["${aws_security_group.ecs_tasks.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.project_name}-rds-sg-${terraform.workspace}"
    Env  = "${terraform.workspace}"
  }
}
