# ==========================================================
# vpc
# ==========================================================
resource "aws_vpc" "my-app_prod" {
  cidr_block           = "10.0.0.0/21"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.name
    Service     = var.service_name
    Environment = var.environment
  }
}


# ==========================================================
# public subnet
# ==========================================================
# subnet
resource "aws_subnet" "my-app_prod_public_a" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.name}-public-subnet-a"
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_subnet" "my-app_prod_public_c" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.name}-public-subnet-c"
    Service     = var.service_name
    Environment = var.environment
  }
}


# internet gateway
resource "aws_internet_gateway" "my-app_prod" {
  vpc_id = aws_vpc.my-app_prod.id

  tags = {
    Name        = "${var.name}-internet-gateway"
    Service     = var.service_name
    Environment = var.environment
  }
}

# route table
resource "aws_route_table" "my-app_prod_public" {
  vpc_id = aws_vpc.my-app_prod.id

  tags = {
    Name        = "${var.name}-public-route-table"
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_route" "my-app_prod_public" {
  route_table_id         = aws_route_table.my-app_prod_public.id
  gateway_id             = aws_internet_gateway.my-app_prod.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "my-app_prod_public_a" {
  subnet_id      = aws_subnet.my-app_prod_public_a.id
  route_table_id = aws_route_table.my-app_prod_public.id
}

resource "aws_route_table_association" "my-app_prod_public_c" {
  subnet_id      = aws_subnet.my-app_prod_public_c.id
  route_table_id = aws_route_table.my-app_prod_public.id
}

# nat gateway
resource "aws_eip" "my-app_prod_nat_gateway_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my-app_prod]

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "aws_nat_gateway_a" {
  allocation_id = aws_eip.my-app_prod_nat_gateway_a.id
  subnet_id     = aws_subnet.my-app_prod_public_a.id
  depends_on    = [aws_internet_gateway.my-app_prod]
}


# ==========================================================
# private subnet
# ==========================================================
# subnet
resource "aws_subnet" "my-app_prod_private" {
  vpc_id                  = aws_vpc.my-app_prod.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

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
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.name}-private-subnet-c"
    Service     = var.service_name
    Environment = var.environment
  }
}


# route table
resource "aws_route_table" "my-app_prod_private" {
  vpc_id = aws_vpc.my-app_prod.id

  tags = {
    Name        = "${var.name}-private-route-table"
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_route" "my-app_prod_private_nat" {
  route_table_id         = aws_route_table.my-app_prod_private.id
  nat_gateway_id         = aws_nat_gateway.aws_nat_gateway_a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "my-app_prod_private_nat" {
  subnet_id      = aws_subnet.my-app_prod_private.id
  route_table_id = aws_route_table.my-app_prod_private.id
}


# ==========================================================
# vpc endpoint
# ==========================================================
# for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.my-app_prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.my-app_prod_private.id]
  security_group_ids  = [module.vpc_https_sg.security_group_id]

  tags = {
    Name        = "${var.name}-ecr-api-endpoint"
    Service     = var.service_name
    Environment = var.environment
  }
}

# for ECR Docker
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

# for S3 Gateway
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

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.my-app_prod_private.id
  depends_on      = [aws_vpc_endpoint.s3]
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.my-app_prod_private.id
  route_table_id = aws_route_table.my-app_prod_private.id
}

# for CloudWatch Logs
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

# for SSM
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

# security group
module "vpc_https_sg" {
  source      = "../module/security_group/"
  name        = "vpc-https-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 443
  cidr_blocks = [aws_vpc.my-app_prod.cidr_block]
}
