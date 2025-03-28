# ==========================================================
# VPC（仮想プライベートクラウド）の作成
# ==========================================================
resource "aws_vpc" "my-app_prod" {
  cidr_block           = "10.0.0.0/21"  # VPCのCIDRブロック（ネットワーク範囲）
  enable_dns_support   = true          # VPCでDNS解決を有効化
  enable_dns_hostnames = true          # インスタンスにDNSホスト名を付与

  tags = {
    Name        = var.name
    Service     = var.service_name
    Environment = var.environment
  }
}

# ==========================================================
# パブリックサブネット（インターネットと通信可能なサブネット）
# ==========================================================
# サブネットA（アベイラビリティゾーンAに配置）
resource "aws_subnet" "my-app_prod_public_a" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.1.0/24"  # IPアドレス範囲を指定
  availability_zone       = "${var.aws_region}a"  # 指定したリージョンのAZ（a）
  map_public_ip_on_launch = true  # インスタンスにパブリックIPを自動付与

  tags = {
    Name        = "${var.name}-public-subnet-a"
    Service     = var.service_name
    Environment = var.environment
  }
}

# サブネットC（アベイラビリティゾーンCに配置）
resource "aws_subnet" "my-app_prod_public_c" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.0.0/24"  # IPアドレス範囲を指定（ここは10.0.3.0/24が適切かも）
  availability_zone       = "${var.aws_region}c"  # 指定したリージョンのAZ（c）
  map_public_ip_on_launch = true  # インスタンスにパブリックIPを自動付与

  tags = {
    Name        = "${var.name}-public-subnet-c"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ==========================================================
# インターネットゲートウェイ（インターネットと通信するためのゲートウェイ）
# ==========================================================
resource "aws_internet_gateway" "my-app_prod" {
  vpc_id = aws_vpc.my-app_prod.id  # VPCに紐付ける

  tags = {
    Name        = "${var.name}-internet-gateway"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ==========================================================
# パブリックサブネット用のルートテーブル（インターネットへの経路）
# ==========================================================
resource "aws_route_table" "my-app_prod_public" {
  vpc_id = aws_vpc.my-app_prod.id

  tags = {
    Name        = "${var.name}-public-route-table"
    Service     = var.service_name
    Environment = var.environment
  }
}

# デフォルトルート（インターネットゲートウェイを経由する）
resource "aws_route" "my-app_prod_public" {
  route_table_id         = aws_route_table.my-app_prod_public.id
  gateway_id             = aws_internet_gateway.my-app_prod.id
  destination_cidr_block = "0.0.0.0/0"  # すべての宛先へ通信を許可
}

# サブネットAとルートテーブルを関連付け
resource "aws_route_table_association" "my-app_prod_public_a" {
  subnet_id      = aws_subnet.my-app_prod_public_a.id
  route_table_id = aws_route_table.my-app_prod_public.id
}

# サブネットCとルートテーブルを関連付け
resource "aws_route_table_association" "my-app_prod_public_c" {
  subnet_id      = aws_subnet.my-app_prod_public_c.id
  route_table_id = aws_route_table.my-app_prod_public.id
}

# ==========================================================
# NATゲートウェイ（プライベートサブネットの外部通信用）
# ==========================================================
# NATゲートウェイに割り当てるElastic IP（固定IP）
resource "aws_eip" "my-app_prod_nat_gateway_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my-app_prod]  # インターネットゲートウェイの作成を待機

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

# NATゲートウェイ（パブリックサブネットに配置し、プライベートサブネットの通信を中継）
resource "aws_nat_gateway" "aws_nat_gateway_a" {
  allocation_id = aws_eip.my-app_prod_nat_gateway_a.id  # Elastic IPを紐付け
  subnet_id     = aws_subnet.my-app_prod_public_a.id  # NATゲートウェイを配置するサブネット
  depends_on    = [aws_internet_gateway.my-app_prod]  # インターネットゲートウェイの作成を待機
}

# ==========================================================
# private subnet
# ==========================================================
# Privateサブネットを定義
resource "aws_subnet" "my-app_prod_private" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  # パブリックIPを割り当てない

  tags = {
    Name        = "${var.name}-private-subnet"
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_subnet" "my-app_prod_private_c" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false  # パブリックIPを割り当てない

  tags = {
    Name        = "${var.name}-private-subnet-c"
    Service     = var.service_name
    Environment = var.environment
  }
}


# ==========================================================
# Route Table
# ==========================================================
# プライベートサブネット用のルートテーブル
resource "aws_route_table" "my-app_prod_private" {
  vpc_id = aws_vpc.my-app_prod.id

  tags = {
    Name        = "${var.name}-private-route-table"
    Service     = var.service_name
    Environment = var.environment
  }
}

# NAT Gatewayを経由するデフォルトルートを設定
resource "aws_route" "my-app_prod_private_nat" {
  route_table_id         = aws_route_table.my-app_prod_private.id
  nat_gateway_id         = aws_nat_gateway.aws_nat_gateway_a.id
  destination_cidr_block = "0.0.0.0/0"
}

# プライベートサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "my-app_prod_private_nat" {
  subnet_id      = aws_subnet.my-app_prod_private.id
  route_table_id = aws_route_table.my-app_prod_private.id
}


# ==========================================================
# VPC Endpoints
# ==========================================================
# ECR API用のVPCエンドポイント
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.my-app_prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true  # 内部DNS解決を有効化
  subnet_ids          = [aws_subnet.my-app_prod_private.id]
  security_group_ids  = [module.vpc_https_sg.security_group_id]

  tags = {
    Name        = "${var.name}-ecr-api-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ECR Docker用のVPCエンドポイント
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.my-app_prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.my-app_prod_private.id]
  security_group_ids  = [module.vpc_https_sg.security_group_id]

  tags = {
    Name        = "${var.name}-ecr-dkr-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# S3 Gatewayエンドポイント（VPC全体で利用）
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.my-app_prod.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "${var.name}-s3-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# S3エンドポイントをルートテーブルに関連付け
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.my-app_prod_private.id
  depends_on      = [aws_vpc_endpoint.s3]
}

# ルートテーブルとプライベートサブネットの関連付け
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.my-app_prod_private.id
  route_table_id = aws_route_table.my-app_prod_private.id
}

# CloudWatch Logs用のVPCエンドポイント
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.my-app_prod.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.my-app_prod_private.id]
  security_group_ids  = [module.vpc_https_sg.security_group_id]

  tags = {
    Name        = "${var.name}-cw-logs-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# SSM用のVPCエンドポイント
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.my-app_prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.my-app_prod_private.id]
  security_group_ids  = [module.vpc_https_sg.security_group_id]

  tags = {
    Name        = "${var.name}-ssm-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# ==========================================================
# Security Group
# ==========================================================
# HTTPS通信を許可するセキュリティグループ
module "vpc_https_sg" {
  source      = "../module/security_group/"  # セキュリティグループモジュールの参照元
  name        = "vpc-https-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 443  # HTTPS通信を許可
  cidr_blocks = [aws_vpc.my-app_prod.cidr_block]  # VPC全体の通信を許可
}


# HTTPS（ポート443）を許可する理由は、VPC内のリソースがAWSの各種サービスと安全に通信するためです。具体的には、以下のようなケースで必要になります。

# 1. VPCエンドポイントとの通信
# aws_vpc_endpoint で定義した ECR (Elastic Container Registry)、CloudWatch Logs、SSM などの AWSサービスはHTTPS通信 を使用します。
# これらのサービスと安全に通信するために、VPC内のセキュリティグループで ポート443（HTTPS） を許可する必要があります。
# 2. ECRとのやり取り
# コンテナイメージの取得 (docker pull) やプッシュ (docker push) はHTTPSで行われます。
# ecr.api と ecr.dkr のVPCエンドポイントが HTTPS通信を利用 するため、それを許可する必要があります。
# 3. AWS SSM（Systems Manager）の利用
# AWS SSM（Session Manager、Parameter Storeなど）はHTTPS通信を使用してVPC内部のインスタンスとやり取りします。
# aws_vpc_endpoint "ssm" で作成されたSSMエンドポイントと通信するために、HTTPSの許可が必要です。
# 4. CloudWatch Logsへのログ送信
# CloudWatch Logs にログを送るときも HTTPS通信 を使用します。
# aws_vpc_endpoint "cloudwatch_logs" で作成したVPCエンドポイントを通じて、安全にログを送信できるようにするため、HTTPSが許可されている必要があります。
# 5. セキュリティのための制限
# HTTPSを許可することで、VPC内のリソースが外部に直接インターネット接続せず、VPCエンドポイント経由でAWSサービスに安全にアクセス できるようになります。
# これにより NAT Gatewayを使わずにAWSサービスと通信でき、コスト削減 につながることもあります。

# なぜ両方のエンドポイントが必要か？
# ecr.api だけ だと、認証情報は取得できるが、コンテナイメージのやり取りはできない。
# ecr.dkr だけ だと、ECRにログインするための認証情報を取得できない。
# そのため、 ECRを利用する場合はecr.apiとecr.dkrの両方のエンドポイントを設定する必要がある。
