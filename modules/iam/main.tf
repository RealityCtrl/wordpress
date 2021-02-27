resource "aws_iam_role" "server_role" {
  name = "realityctrl-wordpress"
  assume_role_policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": ${jsonencode(setunion(["arn:aws:iam::${var.aws_account_id}:root"], var.admin_arns))},
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole",
                    "Condition": {}
                }
            ]
        }
    EOF
}

resource "aws_iam_role_policy" "s3_deployment_policy" {
  name = "FunctionDeploymentBucketPolicy"
  role = aws_iam_role.server_role.id
  policy = <<-EOF
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Sid": "FunctionDeploymentBucket",
                    "Action": [
                        "s3:ListBucket",
                        "s3:ListObjects*",
                        "s3:DeleteObject",
                        "s3:GetObject",
                        "s3:GetObjectVersion",
                        "s3:GetBucketLocation",
                        "s3:ListBucket",
                        "s3:ListBucketVersions",
                        "s3:GetEncryptionConfiguration",
                        "s3:PutEncryptionConfiguration"
                    ],
                    "Resource": [
                        "arn:aws:s3:::${var.bucket_name}",
                        "arn:aws:s3:::${var.bucket_name}/*"
                    ]
                }
            ]
        }
    EOF
}