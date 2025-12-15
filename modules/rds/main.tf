resource "aws_db_parameter_group" "main" {
  name   = "rds-pg"
  family = "mysql5.7"

}

resource "aws_db_instance" "main" {
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username
  password             = var.password
  parameter_group_name = aws_db_parameter_group.main.name
  skip_final_snapshot  = true
}

