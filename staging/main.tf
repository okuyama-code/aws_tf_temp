locals {
  instance_name = "${var.environment}-${var.project_name}"
}

# APIに対するLightsailインスタンスの作成
resource "aws_lightsail_instance" "my-app" {
  name              = local.instance_name
  availability_zone = "ap-northeast-1a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "micro_2_0"

  ip_address_type = "ipv4"

  tags = {
    name = local.instance_name
    env  = var.environment
  }
}

# 固定IPアドレスの作成
resource "aws_lightsail_static_ip" "my-app" {
  name = "${local.instance_name}-static-ip"
}

# 固定IPアドレスの割り当て
resource "aws_lightsail_static_ip_attachment" "my-app" {
  static_ip_name = aws_lightsail_static_ip.my-app.id
  instance_name  = aws_lightsail_instance.my-app.name
}

resource "aws_lightsail_instance_public_ports" "my-app" {
  instance_name = aws_lightsail_instance.my-app.name

  # SSHポート設定 (22番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.ssh_allowed_cidrs
  }

  # HTTPポート設定 (80番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidrs     = ["0.0.0.0/0"]
  }

  # HTTPSポート設定 (443番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidrs     = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "my-app" {
  bucket = "app-storage-${local.instance_name}"
  tags = {
    env  = var.environment
    Name = "app-storage"
  }
}

resource "aws_s3_bucket_versioning" "my-app" {
  bucket = aws_s3_bucket.my-app.id
  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "my-app" {
  bucket                  = aws_s3_bucket.my-app.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "my-app" {
  bucket = aws_s3_bucket.my-app.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "PublicReadGetObject",
        Effect : "Allow",
        Principal : "*",
        Action : "s3:GetObject",
        Resource = [
          "${aws_s3_bucket.my-app.arn}/*"
        ]
      }
    ]
  })
}

# 管理画面用のLightsailインスタンス作成
resource "aws_lightsail_instance" "admin" {
  name              = "${local.instance_name}-admin"
  availability_zone = "ap-northeast-1a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "micro_2_0"

  ip_address_type = "ipv4"

  tags = {
    name = "${local.instance_name}-admin"
    env  = var.environment
  }
}

# 管理画面用の固定IPアドレス作成
resource "aws_lightsail_static_ip" "admin" {
  name = "${local.instance_name}-admin-static-ip"
}

# 管理画面用の固定IPアドレス割り当て
resource "aws_lightsail_static_ip_attachment" "admin" {
  static_ip_name = aws_lightsail_static_ip.admin.id
  instance_name  = aws_lightsail_instance.admin.name
}

# 管理画面用インスタンスのパブリックポート設定
resource "aws_lightsail_instance_public_ports" "admin" {
  instance_name = aws_lightsail_instance.admin.name

  # SSHポート設定 (22番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.ssh_allowed_cidrs
  }

  # HTTPポート設定 (80番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidrs     = ["0.0.0.0/0"]
  }

  # HTTPSポート設定 (443番ポート)
  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidrs     = ["0.0.0.0/0"]
  }
}
