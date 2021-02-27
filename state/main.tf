module "realitctrl_state" {
  source = "./modules/state-s3"

  providers = {
    aws = aws.default
  }

  bucket_name = var.bucket_name
  admin_arns  = var.admin_arns
}