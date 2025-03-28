# ==========================================================
# 📌 変数定義（パラメータを外部から渡せるようにする）
# ==========================================================

# IAM ロールの名前（例: ecs-task-role）
variable "name" {}

# IAM ポリシーの JSON（外部から渡す）
variable "policy" {}

# この IAM ロールを利用する AWS サービス（例: "ecs-tasks.amazonaws.com"）
variable "identifier" {}

# ==========================================================
# 📌 IAM ロールの作成
# ==========================================================

resource "aws_iam_role" "default" {
  name               = var.name  # IAM ロールの名前
  assume_role_policy = data.aws_iam_policy_document.assume_role.json  # ロールを引き受けるポリシー
}

# IAM ロールの信頼ポリシーを定義（どの AWS サービスがこのロールを利用できるか）
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]  # ロールの引き受けを許可

    principals {
      type        = "Service"
      identifiers = [var.identifier]  # 指定された AWS サービスのみ許可（例: "ecs-tasks.amazonaws.com"）
    }
  }
}

# ==========================================================
# 📌 IAM ポリシーの作成
# ==========================================================

resource "aws_iam_policy" "default" {
  name   = var.name  # ポリシーの名前（ロール名と同じ）
  policy = var.policy  # 外部から渡される JSON のポリシーを適用
}

# ==========================================================
# 📌 IAM ロールとポリシーの関連付け
# ==========================================================

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name  # 作成した IAM ロール
  policy_arn = aws_iam_policy.default.arn  # 作成した IAM ポリシー
}

# ==========================================================
# 📌 出力（Terraform 実行後に IAM ロールの ARN を確認できる）
# ==========================================================

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}


# 🔹 どんな時に使う？
# ✅ ECS タスクに権限を付与したいとき

# 例: ECS のコンテナが S3 にアクセスできるようにする
# ✅ Lambda にアクセス権限を付与したいとき

# 例: Lambda 関数が DynamoDB へ書き込みできるようにする
# ✅ EC2 に権限を付与したいとき

# 例: EC2 インスタンスが SSM パラメータストアから環境変数を取得できるようにする


# 外部の Terraform コードでこの IAM ロールを利用するとき、module を使って簡単に呼び出せます
# ```
# module "ecs_task_role" {
#   source     = "./iam_role"  # モジュールのパス（リモートの場合は GitHub や S3 を指定）
#   name       = "ecs-task-role"
#   identifier = "ecs-tasks.amazonaws.com"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetObject",
#         "s3:PutObject"
#       ],
#       "Resource": "arn:aws:s3:::my-bucket/*"
#     }
#   ]
# }
# EOF
# }
# ```