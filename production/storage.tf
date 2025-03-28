# ==========================================================
# storage
# ==========================================================
# private bucket
resource "aws_s3_bucket" "my-app_prod" {
  bucket = "${var.name}-bucket"
}

resource "aws_s3_bucket_versioning" "my-app_prod" {
  bucket = aws_s3_bucket.my-app_prod.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my-app_prod" {
  bucket = aws_s3_bucket.my-app_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.my-app_prod.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# log bucket
resource "aws_s3_bucket" "alb_log" {
  bucket        = "${var.name}-alb-log"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "log_expiration"
    status = "Enabled"

    expiration {
      days = 60
    }
  }
}

data "aws_iam_policy_document" "alb_log_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::582318560864:root"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_log.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log_policy.json
}
