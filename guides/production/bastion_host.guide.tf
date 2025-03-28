# 踏み台(Bastion)サーバー


# BastionホストのEC2インスタンスを作成
resource "aws_instance" "bastion" {
  ami                    = "ami-02e5504ea463e3f34" # 使用するAMI ID
  instance_type          = "t2.medium" # インスタンスタイプ
  subnet_id              = aws_subnet.my-app_prod_public_a.id # 配置するサブネット
  vpc_security_group_ids = [module.ssh_sg.security_group_id] # 適用するセキュリティグループ
  # associate_public_ip_address = true # パブリックIPアドレスの関連付け（無効化）
  user_data = file("script/bastion_host_setup.sh") # 起動時に実行するスクリプト

  tags = {
    Name = "${var.name}-bastion-host" # インスタンスのタグ名
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address] # `associate_public_ip_address` の変更を無視
  }
}

# BastionホストにElastic IP（固定パブリックIP）を割り当てる
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id # 割り当てるインスタンス

  tags = {
    Name = "${var.name}-bastion-eip" # EIPのタグ名
  }
}

# SSH用のセキュリティグループを作成
module "ssh_sg" {
  source      = "../module/security_group/" # セキュリティグループモジュールの参照
  name        = "ssh-sg" # セキュリティグループ名
  vpc_id      = aws_vpc.my-app_prod.id # VPCのID
  port        = 22 # 許可するポート番号（SSH）
  cidr_blocks = ["0.0.0.0/0"] # すべてのIPからのアクセスを許可（セキュリティ上の考慮が必要）
}

# Bastionホストを停止するLambda関数の作成
resource "aws_lambda_function" "stop_bastion" {
  function_name = "${var.name}-stop-bastion" # Lambda関数の名前
  runtime       = "python3.11" # 実行環境
  handler       = "lambda_stop_bastion.lambda_handler" # ハンドラーの指定
  role          = module.lambda_stop_bastion_role.iam_role_arn # IAMロール

  # Lambda関数のデプロイ用ZIPファイル
  # `zip lambda/lambda_stop_bastion.zip lambda/lambda_stop_bastion.py -j` を実行して作成
  filename         = "./lambda/lambda_stop_bastion.zip"
  source_code_hash = filebase64sha256("./lambda/lambda_stop_bastion.zip") # ファイルの変更検知用ハッシュ

  environment {
    variables = {
      INSTANCE_ID = aws_instance.bastion.id # 停止対象のBastionホストのインスタンスID
    }
  }
}

# Lambda関数に必要なIAMポリシーの作成
data "aws_iam_policy_document" "lambda_stop_bastion" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StopInstances" # EC2インスタンスの停止を許可
    ]
    resources = ["*"] # すべてのEC2インスタンスに適用（より厳格な制限を検討）
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup", # ロググループの作成
      "logs:CreateLogStream", # ログストリームの作成
      "logs:PutLogEvents" # ログの記録
    ]
    resources = ["arn:aws:logs:*:*:*"] # すべてのログリソースに適用
  }
}

# Lambda関数用のIAMロールを作成
module "lambda_stop_bastion_role" {
  source     = "../module/iam_role/" # IAMロールモジュールの参照
  name       = "lambda-stop-bastion" # ロール名
  identifier = "lambda.amazonaws.com" # Lambdaサービスに紐づけ
  policy     = data.aws_iam_policy_document.lambda_stop_bastion.json # IAMポリシーの適用
}

# Lambda関数を定期実行するためのEventBridgeルールを作成
resource "aws_cloudwatch_event_rule" "stop_bastion" {
  name                = "${var.name}-stop-bastion" # ルール名
  schedule_expression = "rate(120 minutes)" # 2時間ごとに実行
}

# EventBridgeルールでLambda関数をターゲットとして設定
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.stop_bastion.name # イベントルールの指定
  arn  = aws_lambda_function.stop_bastion.arn # 呼び出すLambda関数
}

# EventBridgeがLambda関数を実行できるようにするための権限を設定
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch" # ステートメントID
  action        = "lambda:InvokeFunction" # Lambda関数の実行権限を付与
  function_name = aws_lambda_function.stop_bastion.function_name # 関連付けるLambda関数
  principal     = "events.amazonaws.com" # EventBridgeからの呼び出しを許可
  source_arn    = aws_cloudwatch_event_rule.stop_bastion.arn # 許可対象のEventBridgeルール
}



# なぜZIPファイルが必要なのか？
# AWS Lambdaでは、関数のコードを直接書き込む方法（インライン編集）と、ZIPファイルをアップロードする方法の2つのデプロイ方法があります。

# 短いスクリプトならAWS管理コンソールに直接書くことも可能
# 依存ライブラリが必要だったり、ファイル構成が複雑ならZIPでアップロード
# Terraform の aws_lambda_function リソースでは、Lambda関数のコードをZIPファイルとして指定しないとデプロイできません。そのため、コードと関連ファイルをZIPに圧縮してアップロードする必要があります。