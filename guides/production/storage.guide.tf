# ==========================================================
# Storage (S3 Bucket 設定)
# ==========================================================

# ==========================================================
# Private Bucket (非公開のS3バケット)
# ==========================================================
# S3バケットを作成 (プライベートバケット)
resource "aws_s3_bucket" "my-app_prod" {
  bucket = "${var.name}-bucket"  # バケット名を変数から指定
}

# バージョニング設定 (オブジェクトの世代管理を有効化)
resource "aws_s3_bucket_versioning" "my-app_prod" {
  bucket = aws_s3_bucket.my-app_prod.id

  versioning_configuration {
    status = "Enabled"  # バージョニングを有効化 (過去バージョンの保持)
  }
}

# サーバーサイド暗号化の設定 (デフォルトでAES256暗号化を適用)
resource "aws_s3_bucket_server_side_encryption_configuration" "my-app_prod" {
  bucket = aws_s3_bucket.my-app_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # S3のオブジェクトを自動でAES256暗号化
    }
  }
}

# パブリックアクセスをブロック (セキュリティ対策)
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.my-app_prod.id
  block_public_acls       = true  # パブリックなACLをブロック
  block_public_policy     = true  # パブリックなバケットポリシーをブロック
  ignore_public_acls      = true  # 既存のパブリックACLを無視
  restrict_public_buckets = true  # バケットを完全非公開に制限
}


# ==========================================================
# Log Bucket (ALBのログ保存用S3バケット)
# ==========================================================
# ALBのログ保存用のS3バケットを作成
resource "aws_s3_bucket" "alb_log" {
  bucket        = "${var.name}-alb-log"  # バケット名を変数から指定
  force_destroy = true  # 削除時にバケット内のデータも強制的に削除
}

# ライフサイクル設定 (ログの自動削除)
resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "log_expiration"
    status = "Enabled"  # ルールを有効化

    expiration {
      days = 60  # 60日経過したログファイルを自動削除
    }
  }
}

# ALB (Application Load Balancer) からのログ保存を許可するバケットポリシー
# AWSの公式ドキュメントに基づく設定
# 582318560864 は AWS のALBログ保存用の公式アカウントID (リージョンによって異なる可能性あり)
# 謎のAWSアカウントID「582318560864」
# 上記の「582318560864」は自分のAWSアカウントIDではなく何のアカウントなんだろうと疑問に思って調べたところ、サービス側でELBを管理しているアカウントであることがわかりました。
# 各リージョンごとにアカウントは作成されていて、「582318560864」はap-northeast-1(東京リージョン)のアカウントでした。
# https://zenn.dev/sugay0519/articles/b889f94d606b1a
# https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/enable-access-logging.html#access-log-create-bucket
data "aws_iam_policy_document" "alb_log_policy" {
  statement {
    effect = "Allow"  # 許可ポリシー

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::582318560864:root"]  # ALBログ保存用AWSアカウント
    }

    actions   = ["s3:PutObject"]  # S3バケットにオブジェクトを保存する権限を付与
    resources = ["${aws_s3_bucket.alb_log.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }
}

# ALBログ保存用のバケットポリシーを適用
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log_policy.json
}
