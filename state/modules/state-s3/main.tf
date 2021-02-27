resource "aws_s3_bucket" "realityctrl_terraform" {
  bucket = var.bucket_name
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    managed_by      = "terraform"
    description     = "Terraform remote state storage related to realityctrl.com"
  }
}

resource "aws_s3_bucket_policy" "realityctrl_terraform_policy" {
  bucket = aws_s3_bucket.realityctrl_terraform.id
  policy = <<-EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "Allow admin access",
      "Effect": "Allow",
      "Principal": {
        "AWS": ${jsonencode(var.admin_arns)}
      },
      "Action": [
        "s3:*"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.realityctrl_terraform.id}/*"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "realityctrl_terraform_block_public" {
  bucket = aws_s3_bucket.realityctrl_terraform.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}