# ==========================================================
# 🔹 RDS（データベース）の認証情報
# ==========================================================

# 🔸 データベースのユーザー名を AWS Systems Manager Parameter Store に保存
resource "aws_ssm_parameter" "rds_username" {
  name  = "/my-app_prod/RDS_USERNAME"  # パラメータのキー名（環境ごとに変更可）
  type  = "SecureString"              # 機密情報なので SecureString に設定（暗号化される）
  value = "nestjs-admin"              # データベースのユーザー名（デフォルト値）

  lifecycle {
    ignore_changes = [value]  # Terraform で変更を管理せず、手動変更を許容
  }
}

# 🔸 データベースのパスワードを AWS Systems Manager Parameter Store に保存
resource "aws_ssm_parameter" "rds_password" {
  name  = "/my-app_prod/RDS_PASSWORD"
  type  = "SecureString"  # パスワードは機密情報のため暗号化
  value = "secure-password"

  lifecycle {
    ignore_changes = [value]
  }
}

# ==========================================================
# 🔹 Firebase の設定情報
# ==========================================================

# 🔸 Firebase プロジェクト ID
resource "aws_ssm_parameter" "firebase_project_id" {
  name  = "/my-app_prod/FIREBASE_PROJECT_ID"
  type  = "SecureString"  # 機密情報として暗号化
  value = "firebase-project-id"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 Firebase プライベートキー（認証情報）
resource "aws_ssm_parameter" "firebase_private_key" {
  name  = "/my-app_prod/FIREBASE_PRIVATE_KEY"
  type  = "SecureString"
  value = "firebase-private-key"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 Firebase クライアントメール
resource "aws_ssm_parameter" "firebase_client_email" {
  name  = "/my-app_prod/FIREBASE_CLIENT_EMAIL"
  type  = "SecureString"
  value = "firebase-client-email"

  lifecycle {
    ignore_changes = [value]
  }
}

# ==========================================================
# 🔹 iOS アプリのバージョン管理情報
# ==========================================================

# 🔸 iOS の最新バージョン
resource "aws_ssm_parameter" "app_ios_latest_version" {
  name  = "/my-app_prod/APP_IOS_LATEST_VERSION"
  type  = "String"  # バージョン番号は機密情報ではないため String に設定
  value = "1.0.0"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 iOS の必須アップデートフラグ（false = 強制アップデートなし）
resource "aws_ssm_parameter" "app_ios_required_update" {
  name  = "/my-app_prod/APP_IOS_REQUIRED_UPDATE"
  type  = "String"
  value = "false"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 iOS の任意アップデートフラグ（true = 任意アップデートあり）
resource "aws_ssm_parameter" "app_ios_optional_update" {
  name  = "/my-app_prod/APP_IOS_OPTIONAL_UPDATE"
  type  = "String"
  value = "true"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 iOS アプリストアの URL
resource "aws_ssm_parameter" "app_ios_store_url" {
  name  = "/my-app_prod/APP_IOS_STORE_URL"
  type  = "String"
  value = "store-url"

  lifecycle {
    ignore_changes = [value]
  }
}

# ==========================================================
# 🔹 Android アプリのバージョン管理情報
# ==========================================================

# 🔸 Android の最新バージョン
resource "aws_ssm_parameter" "app_android_latest_version" {
  name  = "/my-app_prod/APP_ANDROID_LATEST_VERSION"
  type  = "String"
  value = "1.0.0"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 Android の必須アップデートフラグ
resource "aws_ssm_parameter" "app_android_required_update" {
  name  = "/my-app_prod/APP_ANDROID_REQUIRED_UPDATE"
  type  = "String"
  value = "false"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 Android の任意アップデートフラグ
resource "aws_ssm_parameter" "app_android_optional_update" {
  name  = "/my-app_prod/APP_ANDROID_OPTIONAL_UPDATE"
  type  = "String"
  value = "true"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 Android アプリストアの URL
resource "aws_ssm_parameter" "app_android_store_url" {
  name  = "/my-app_prod/APP_ANDROID_STORE_URL"
  type  = "String"
  value = "store-url"

  lifecycle {
    ignore_changes = [value]
  }
}

# ==========================================================
# 🔹 AWS 認証情報（S3 などにアクセスするため）
# ==========================================================

# 🔸 AWS アクセスキー ID
resource "aws_ssm_parameter" "aws_access_key_id" {
  name  = "/my-app_prod/AWS_ACCESS_KEY_ID"
  type  = "SecureString"
  value = "access-key"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 AWS シークレットアクセスキー
resource "aws_ssm_parameter" "aws_secret_access_key" {
  name  = "/my-app_prod/AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = "secret-key"

  lifecycle {
    ignore_changes = [value]
  }
}

# 🔸 AWS S3 バケット名
resource "aws_ssm_parameter" "aws_s3_bucket_name" {
  name  = "/my-app_prod/AWS_S3_BUCKET_NAME"
  type  = "String"
  value = "s3-bucket-name"

  lifecycle {
    ignore_changes = [value]
  }
}
