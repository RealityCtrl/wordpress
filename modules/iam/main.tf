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
                        "Service": "ec2.amazonaws.com",
                        "Service":"ssm.amazonaws.com"
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
resource "aws_iam_role_policy" "ssm__policy" {
  name = "WordpressSSMPolicy"
  role = aws_iam_role.server_role.id
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
                {
            "Effect": "Allow",
            "Action": [
                "iam:CreateInstanceProfile",
                "iam:ListInstanceProfilesForRole",
                "iam:PassRole",
                "ec2:DescribeIamInstanceProfileAssociations",
                "iam:GetInstanceProfile",
                "ec2:DisassociateIamInstanceProfile",
                "ec2:AssociateIamInstanceProfile",
                "iam:AddRoleToInstanceProfile"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}