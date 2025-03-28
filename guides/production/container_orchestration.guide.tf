# ==========================================================
# 📌 ローカル変数の定義（AWS のリソース ARN ）
# ==========================================================

locals {
  ssm_parameter_url = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter"
  kms_key_url       = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key"
}

# ==========================================================
# 📌 ECS クラスターの作成
# ==========================================================

resource "aws_ecs_cluster" "my-app_prod" {
  name = "${var.name}-cluster"  # クラスターの名前
}

# ==========================================================
# 📌 ECS タスク定義（コンテナの設定）
# ==========================================================

resource "aws_ecs_task_definition" "my-app_prod" {
  family                   = var.name  # タスク定義の名前
  cpu                      = "512"     # CPU 512 単位（約 0.5 vCPU）
  memory                   = "4096"    # メモリ 4GB
  network_mode             = "awsvpc"  # Fargate では "awsvpc" 必須
  requires_compatibilities = ["FARGATE"]

  # 🔹 コンテナの設定（JSON テンプレートを使用）
  container_definitions = templatefile("${path.module}/json/container_definitions.json.tpl", {

    # 🔹 RDS (PostgreSQL) の接続情報
    port        = "4000"
    db_username = aws_db_instance.my-app_prod_db.username
    db_password = aws_db_instance.my-app_prod_db.password
    db_host     = aws_db_instance.my-app_prod_db.endpoint
    db_name     = aws_db_instance.my-app_prod_db.db_name
    aws_region  = var.aws_region

    # 🔹 AWS SSM Parameter Store から機密情報を取得
    ssm_firebase_project_id    = "${local.ssm_parameter_url}/my-app_prod/FIREBASE_PROJECT_ID"
    ssm_firebase_private_key   = "${local.ssm_parameter_url}/my-app_prod/FIREBASE_PRIVATE_KEY"
    ssm_firebase_client_email  = "${local.ssm_parameter_url}/my-app_prod/FIREBASE_CLIENT_EMAIL"
    ssm_app_ios_latest_version = "${local.ssm_parameter_url}/my-app_prod/APP_IOS_LATEST_VERSION"
    ssm_aws_access_key_id      = "${local.ssm_parameter_url}/my-app_prod/AWS_ACCESS_KEY_ID"
    ssm_aws_secret_access_key  = "${local.ssm_parameter_url}/my-app_prod/AWS_SECRET_ACCESS_KEY"
    ssm_aws_s3_bucket_name     = "${local.ssm_parameter_url}/my-app_prod/AWS_S3_BUCKET_NAME"
  })

  task_role_arn      = module.ecs_task_role.iam_role_arn
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# ==========================================================
# 📌 ECS サービス（Fargate でアプリを実行）
# ==========================================================

resource "aws_ecs_service" "my-app_prod" {
  name                              = "${var.name}-service"
  cluster                           = aws_ecs_cluster.my-app_prod.arn
  task_definition                   = aws_ecs_task_definition.my-app_prod.arn
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  desired_count                     = 1
  health_check_grace_period_seconds = 180
  enable_execute_command            = true
  force_new_deployment              = true

  network_configuration {
    assign_public_ip = false  # パブリック IP を付与しない（プライベートサブネット）
    security_groups = [
      module.ecs_sg.security_group_id
    ]
    subnets = [
      aws_subnet.my-app_prod_private.id
    ]
  }

  # 🔹 ALB（ロードバランサー）と紐付ける
  load_balancer {
    target_group_arn = aws_lb_target_group.my-app_prod.arn
    container_name   = var.name
    container_port   = 4000
  }
}

# ==========================================================
# 📌 ECS 用のセキュリティグループ（SG）
# ==========================================================

module "ecs_sg" {
  source      = "../module/security_group/"
  name        = "ecs-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 4000
  cidr_blocks = [aws_vpc.my-app_prod.cidr_block]
}

# 🔹 ECS から RDS への通信を許可（5432番ポート）
resource "aws_security_group_rule" "ecs_egress_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.ecs_sg.security_group_id
  source_security_group_id = module.rds_sg.security_group_id
}

# ==========================================================
# 📌 ECR（Docker イメージを保存するリポジトリ）
# ==========================================================

resource "aws_ecr_repository" "my-app_prod_nestjs" {
  name                 = "${var.name}-nestjs"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.name}-nestjs"
  }
}

# ==========================================================
# 📌 CloudWatch Logs（ECS のログ保存）
# ==========================================================

resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/my-app_prod/ecs"
  retention_in_days = 180
}

# ==========================================================
# 📌 IAM ロール（ECS タスク用）
# ==========================================================

module "ecs_task_execution_role" {
  source     = "../module/iam_role/"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "ecs_task_role" {
  source     = "../module/iam_role/"
  name       = "ecs-task"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task.json
}


# data は Terraform Console で取得できる？
# はい、Terraform Console で data ブロックの値を取得できます！
# data ブロックは、Terraform が 既存の AWS リソースを参照するためのデータソース です。そのため、Terraform Console で実際の値を確認することが可能です。