resource "aws_db_parameter_group" "main" {
  name   = "${var.env}-${var.project_name}-pg"
  family = var.family
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-${var.project_name}-SG"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.env}-${var.project_name}-SG"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.env}-${var.project_name}-rds-sg"
  description = "${var.env}-${var.project_name}-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = var.sg_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.env}-${var.project_name}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier           = "${var.env}-${var.project_name}-rds"
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = data.aws_ssm_parameter.username.value
  password             = data.aws_ssm_parameter.password.value
  parameter_group_name = aws_db_parameter_group.main.name
  skip_final_snapshot  = true
  storage_encrypted    = true
  kms_key_id           = var.kms_key_id
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
}

