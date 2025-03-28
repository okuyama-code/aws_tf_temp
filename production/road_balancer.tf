# ==========================================================
# application load balancer
# ==========================================================
# application load balancer
resource "aws_lb" "my-app_prod" {
  name                       = "${var.name}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  subnets = [
    aws_subnet.my-app_prod_public_a.id,
    aws_subnet.my-app_prod_public_c.id
  ]

  security_groups = [
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]

  tags = {
    Name        = "${var.name}-alb"
    Service     = var.service_name
    Environment = var.environment
  }
}

# security group
module "https_sg" {
  source      = "../module/security_group/"
  name        = "https-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "../module/security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

# ==========================================================
# dns
# ==========================================================
resource "aws_route53_zone" "my-app_api_prod" {
  name = "prod-api.themy-app.jp"
}

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

# ssl certificate
resource "aws_acm_certificate" "my-app_api_prod" {
  domain_name               = aws_route53_record.my-app_api_prod.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# dns ssl validation
resource "aws_route53_record" "my-app_api_prod_certificate" {
  name    = tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.my-app_api_prod.domain_validation_options)[0].resource_record_value]
  zone_id = aws_route53_zone.my-app_api_prod.zone_id
  ttl     = 60
}

resource "aws_acm_certificate_validation" "my-app_api_prod" {
  certificate_arn         = aws_acm_certificate.my-app_api_prod.arn
  validation_record_fqdns = [aws_route53_record.my-app_api_prod_certificate.fqdn]
}

# ==========================================================
# https
# ==========================================================
# listener
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

# foward to target group
resource "aws_lb_target_group" "my-app_prod" {
  name                 = var.name
  target_type          = "ip"
  vpc_id               = aws_vpc.my-app_prod.id
  port                 = 4000
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path     = "/api/health"
    port     = "traffic-port"
    protocol = "HTTP"
    # ECSが起動しているのにも関わらず、ヘルスチェックで unhealthy になる際は適宜調整.
    healthy_threshold   = 5
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 60
    matcher             = 200
  }

  depends_on = [aws_lb.my-app_prod]
}

resource "aws_lb_listener_rule" "my-app_prod_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-app_prod.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
