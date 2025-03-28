# HTTPS（443）と HTTP（80）の ALB を作成
# Route 53 でカスタムドメインを ALB に紐付け
# ACM で SSL 証明書を発行し、HTTPS を有効化
# HTTP から HTTPS へリダイレクト
# ALB のターゲットグループを作成し、バックエンド（ECS など）へ転送

# ==========================================================
# 📌 Application Load Balancer (ALB) の設定
# ==========================================================

# 🚀 ALB（Application Load Balancer）の作成
resource "aws_lb" "my-app_prod" {
  name                       = "${var.name}-alb"  # ALB の名前
  load_balancer_type         = "application"      # Application Load Balancer を指定
  internal                   = false             # 外部公開（true にすると内部専用）
  idle_timeout               = 60                # 接続が 60 秒間アイドル状態なら切断
  enable_deletion_protection = true              # 誤削除を防止
  drop_invalid_header_fields = true              # 無効な HTTP ヘッダーを削除

  # 🔹 ALB のアクセスログを S3 に保存
  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  # 🔹 ALB を配置するパブリックサブネット（マルチ AZ 対応）
  subnets = [
    aws_subnet.my-app_prod_public_a.id,
    aws_subnet.my-app_prod_public_c.id
  ]

  # 🔹 ALB に適用するセキュリティグループ
  security_groups = [
    module.https_sg.security_group_id,        # HTTPS（443）を許可
    module.http_redirect_sg.security_group_id # HTTP（80）をリダイレクト
  ]

  tags = {
    Name        = "${var.name}-alb"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ==========================================================
# 📌 ALB のセキュリティグループ（SG）設定
# ==========================================================

# 🔹 HTTPS（443）を許可するセキュリティグループ
module "https_sg" {
  source      = "../module/security_group/"
  name        = "https-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]  # 全世界からのアクセスを許可
}

# 🔹 HTTP（80）をリダイレクト用に許可するセキュリティグループ
module "http_redirect_sg" {
  source      = "../module/security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

# ==========================================================
# 📌 Route 53 (DNS) 設定
# ==========================================================

# 🔹 Route 53 のホストゾーン（ドメイン）
resource "aws_route53_zone" "my-app_api_prod" {
  name = "prod-api.themy-app.jp"  # ALB に紐付けるドメイン名
}

# 🔹 ALB の A レコードを設定
resource "aws_route53_record" "my-app_api_prod" {
  zone_id = aws_route53_zone.my-app_api_prod.zone_id
  name    = aws_route53_zone.my-app_api_prod.name
  type    = "A"

  alias {
    name                   = aws_lb.my-app_prod.dns_name
    zone_id                = aws_lb.my-app_prod.zone_id
    evaluate_target_health = true
  }
}

# ==========================================================
# 📌 SSL証明書 (ACM) の発行と DNS 検証
# ==========================================================

# 🔹 SSL 証明書のリクエスト
resource "aws_acm_certificate" "my-app_api_prod" {
  domain_name               = aws_route53_record.my-app_api_prod.name
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 🔹 DNS で SSL 証明書の検証
resource "aws_route53_record" "my-app_api_prod_certificate" {
  name    = tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_value]
  zone_id = aws_route53_zone.my-app_api_prod.zone_id
  ttl     = 60
}

# 🔹 SSL 証明書の検証完了
resource "aws_acm_certificate_validation" "my-app_api_prod" {
  certificate_arn         = aws_acm_certificate.my-app_api_prod.arn
  validation_record_fqdns = [aws_route53_record.my-app_api_prod_certificate.fqdn]
}

# ==========================================================
# 📌 ALB のリスナー設定（HTTPS / HTTP）
# ==========================================================

# 🔹 HTTPS リスナー（ALB で HTTPS を受ける）
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.my-app_prod.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.my-app_api_prod.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-app_prod.arn
  }

  depends_on = [aws_acm_certificate_validation.my-app_api_prod]
}

# 🔹 HTTP から HTTPS へのリダイレクト
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.my-app_prod.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ==========================================================
# 📌 ターゲットグループ（ALB → ECS など）
# ==========================================================

resource "aws_lb_target_group" "my-app_prod" {
  name                 = var.name
  target_type          = "ip"
  vpc_id               = aws_vpc.my-app_prod.id
  port                 = 4000
  protocol             = "HTTP"

  health_check {
    path                = "/api/health"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
    matcher             = 200
  }

  depends_on = [aws_lb.my-app_prod]
}
