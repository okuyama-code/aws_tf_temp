# fbastion host for db access
resource "aws_instance" "bastion" {
  ami                    = "ami-02e5504ea463e3f34"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.my-app_prod_public_a.id
  vpc_security_group_ids = [module.ssh_sg.security_group_id]
  # associate_public_ip_address = true
  user_data = file("script/bastion_host_setup.sh")

  tags = {
    Name = "${var.name}-bastion-host"
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id

  tags = {
    Name = "${var.name}-bastion-eip"
  }
}

module "ssh_sg" {
  source      = "../module/security_group/"
  name        = "ssh-sg"
  vpc_id      = aws_vpc.my-app_prod.id
  port        = 22
  cidr_blocks = ["0.0.0.0/0"]
}


# lambda function to stop bastion host
resource "aws_lambda_function" "stop_bastion" {
  function_name = "${var.name}-stop-bastion"
  runtime       = "python3.11"
  handler       = "lambda_stop_bastion.lambda_handler"
  role          = module.lambda_stop_bastion_role.iam_role_arn

  # exec `zip lambda/lambda_stop_bastion.zip lambda/lambda_stop_bastion.py -j` to create the zip file
  filename         = "./lambda/lambda_stop_bastion.zip"
  source_code_hash = filebase64sha256("./lambda/lambda_stop_bastion.zip")

  environment {
    variables = {
      INSTANCE_ID = aws_instance.bastion.id
    }
  }
}

# iam role
data "aws_iam_policy_document" "lambda_stop_bastion" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StopInstances"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

module "lambda_stop_bastion_role" {
  source     = "../module/iam_role/"
  name       = "lambda-stop-bastion"
  identifier = "lambda.amazonaws.com"
  policy     = data.aws_iam_policy_document.lambda_stop_bastion.json
}

# event bridge for lambda
resource "aws_cloudwatch_event_rule" "stop_bastion" {
  name                = "${var.name}-stop-bastion"
  schedule_expression = "rate(120 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.stop_bastion.name
  arn  = aws_lambda_function.stop_bastion.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_bastion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_bastion.arn
}
