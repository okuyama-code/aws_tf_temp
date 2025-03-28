# ==========================================================
# RDS（データベース）の設定
# ==========================================================

# PostgreSQL データベースを AWS RDS に作成
resource "aws_db_instance" "my-app_prod_db" {
  identifier          = "${var.name}-db"  # RDS インスタンスの識別子（ユニークな名前）
  engine              = "postgres"        # データベースエンジン（PostgreSQL を指定）
  instance_class      = "db.t4g.medium"   # RDS インスタンスの種類（CPU・メモリサイズ）
  db_name             = "my-app_prod"      # データベース名
  allocated_storage   = 10                # ストレージ容量（GB単位）

  # ユーザー名とパスワードは AWS Systems Manager Parameter Store から取得
  username            = data.aws_ssm_parameter.rds_username.value
  password            = data.aws_ssm_parameter.rds_password.value

  skip_final_snapshot = true   # 削除時にスナップショットを作成しない
  storage_encrypted   = true   # ストレージの暗号化を有効化
  deletion_protection = true   # 誤削除を防ぐための保護を有効化

  # RDS を配置する VPC 内のサブネットグループを指定
  db_subnet_group_name   = aws_db_subnet_group.nestjs_rds.name
  # VPC 内の RDS 用セキュリティグループを適用（通信制限を行う）
  vpc_security_group_ids = [module.rds_sg.security_group_id]
}

# ==========================================================
# RDS を配置するサブネットグループの設定
# ==========================================================

resource "aws_db_subnet_group" "nestjs_rds" {
  name = "${var.name}-db-subnet-group"  # サブネットグループの名前

  # RDS を配置する VPC 内のプライベートサブネットを指定
  subnet_ids = [
    aws_subnet.my-app_prod_private.id,    # プライマリのプライベートサブネット
    aws_subnet.my-app_prod_private_c.id   # セカンダリのプライベートサブネット（冗長化）
  ]

  tags = {
    Name = "${var.name}-db-subnet-group"  # タグの設定（管理しやすくするため）
  }
}

# ==========================================================
# RDS 用のセキュリティグループ（SG）の作成
# ==========================================================

module "rds_sg" {
  source      = "../module/security_group/"  # セキュリティグループのモジュールを使用
  name        = "rds-sg"                     # SG の名前
  vpc_id      = aws_vpc.my-app_prod.id        # VPC の ID を指定
  port        = 5432                          # PostgreSQL のポート番号
  cidr_blocks = [aws_vpc.my-app_prod.cidr_block] # VPC 内の通信を許可
}

# ==========================================================
# RDS にアクセスを許可するルールの設定
# ==========================================================

# 🚀 ECS（アプリケーションサーバー）から RDS へのアクセス許可
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"    # 着信トラフィックを許可
  from_port                = 5432         # PostgreSQL のポート番号
  to_port                  = 5432         # PostgreSQL のポート番号
  protocol                 = "tcp"        # TCP 通信を許可
  security_group_id        = module.rds_sg.security_group_id  # RDS のセキュリティグループ
  source_security_group_id = module.ecs_sg.security_group_id  # アクセス元の ECS の SG
}

# 🚀 Bastion（SSH サーバー）から RDS へのアクセス許可
resource "aws_security_group_rule" "rds_ingress_from_bastion" {
  type                     = "ingress"    # 着信トラフィックを許可
  from_port                = 5432         # PostgreSQL のポート番号
  to_port                  = 5432         # PostgreSQL のポート番号
  protocol                 = "tcp"        # TCP 通信を許可
  security_group_id        = module.rds_sg.security_group_id  # RDS のセキュリティグループ
  source_security_group_id = module.ssh_sg.security_group_id  # アクセス元の Bastion の SG
}
