# database
resource "aws_ssm_parameter" "rds_username" {
  name  = "/my-app_prod/RDS_USERNAME"
  type  = "SecureString"
  value = "nestjs-admin"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "rds_username" {
  name = "/my-app_prod/RDS_USERNAME"
}

resource "aws_ssm_parameter" "rds_password" {
  name  = "/my-app_prod/RDS_PASSWORD"
  type  = "SecureString"
  value = "secure-password"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "rds_password" {
  name = "/my-app_prod/RDS_PASSWORD"
}


# firebase
resource "aws_ssm_parameter" "firebase_project_id" {
  name  = "/my-app_prod/FIREBASE_PROJECT_ID"
  type  = "SecureString"
  value = "firebase-project-id"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "firebase_private_key" {
  name  = "/my-app_prod/FIREBASE_PRIVATE_KEY"
  type  = "SecureString"
  value = "firebase-private-key"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "firebase_client_email" {
  name  = "/my-app_prod/FIREBASE_CLIENT_EMAIL"
  type  = "SecureString"
  value = "firebase-client-email"

  lifecycle {
    ignore_changes = [value]
  }
}


# iOS
resource "aws_ssm_parameter" "app_ios_latest_version" {
  name  = "/my-app_prod/APP_IOS_LATEST_VERSION"
  type  = "String"
  value = "1.0.0"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_ios_required_update" {
  name  = "/my-app_prod/APP_IOS_REQUIRED_UPDATE"
  type  = "String"
  value = "false"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_ios_optional_update" {
  name  = "/my-app_prod/APP_IOS_OPTIONAL_UPDATE"
  type  = "String"
  value = "true"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_ios_store_url" {
  name  = "/my-app_prod/APP_IOS_STORE_URL"
  type  = "String"
  value = "store-url"

  lifecycle {
    ignore_changes = [value]
  }
}


# Android
resource "aws_ssm_parameter" "app_android_latest_version" {
  name  = "/my-app_prod/APP_ANDROID_LATEST_VERSION"
  type  = "String"
  value = "1.0.0"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_android_required_update" {
  name  = "/my-app_prod/APP_ANDROID_REQUIRED_UPDATE"
  type  = "String"
  value = "false"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_android_optional_update" {
  name  = "/my-app_prod/APP_ANDROID_OPTIONAL_UPDATE"
  type  = "String"
  value = "true"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "app_android_store_url" {
  name  = "/my-app_prod/APP_ANDROID_STORE_URL"
  type  = "String"
  value = "store-url"

  lifecycle {
    ignore_changes = [value]
  }
}


# aws
resource "aws_ssm_parameter" "aws_access_key_id" {
  name  = "/my-app_prod/AWS_ACCESS_KEY_ID"
  type  = "SecureString"
  value = "access-key"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "aws_secret_access_key" {
  name  = "/my-app_prod/AWS_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = "secret-key"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "aws_s3_bucket_name" {
  name  = "/my-app_prod/AWS_S3_BUCKET_NAME"
  type  = "String"
  value = "s3-bucket-name"

  lifecycle {
    ignore_changes = [value]
  }
}
