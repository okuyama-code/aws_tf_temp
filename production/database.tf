# ==========================================================
# rdb
# ==========================================================
# rdb
resource "aws_db_instance" "my-app_prod_db" {
  identifier          = "${var.name}-db"
  engine              = "postgres"
  instance_class      = "db.t4g.medium"
  db_name             = "my-app_prod"
  allocated_storage   = 10
  username            = data.aws_ssm_parameter.rds_username.value
  password            = data.aws_ssm_parameter.rds_password.value
  skip_final_snapshot = true
  storage_encrypted   = true
  deletion_protection = true

  db_subnet_group_name   = aws_db_subnet_group.nestjs_rds.name
  vpc_security_group_ids = [module.rds_sg.security_group_id]
}

resource "aws_db_subnet_group" "nestjs_rds" {
  name = "${var.name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.my-app_prod_private.id,
    aws_subnet.my-app_prod_private_c.id
  ]

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

# security group
module "rds_sg" {
  source      = "../module/security_group/"
  name        = "rds-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 5432
  cidr_blocks = [aws_vpc.my-app_prod.cidr_block]
}

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_sg.security_group_id
  source_security_group_id = module.ecs_sg.security_group_id
}

resource "aws_security_group_rule" "rds_ingress_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_sg.security_group_id
  source_security_group_id = module.ssh_sg.security_group_id
}
