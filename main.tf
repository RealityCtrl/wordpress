terraform {
  backend "s3" {
    bucket = "realityctrl-terraform"
    key    = "wordpress/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "realitctrl_config_bucket" {
  source = "./modules/storage"

  providers = {
    aws = aws.default
  }

  bucket_name = var.bucket_name
  admin_arns  = var.admin_arns
}

module "realitctrl_credentials" {
  source = "./modules/credentials"

  providers = {
    aws = aws.default
  }
}

module "realitctrl_instance_role" {
  source = "./modules/iam"

  providers = {
    aws = aws.default
  }
  bucket_name       = var.bucket_name
  admin_arns        = var.admin_arns
  aws_account_id    = var.aws_account_id
}

module "realitctrl_instance" {
  source = "./modules/server"

  providers = {
    aws = aws.default
  }
  bucket_name       = var.bucket_name
  aws_account_id    = var.aws_account_id
  cert_email        = var.cert_email
  depends_on = [
      module.realitctrl_config_bucket,
      module.realitctrl_credentials,
      module.realitctrl_instance_role
  ]
}

module "realitctrl_domain_record" {
  source = "./modules/domain"

  providers = {
    aws = aws.default
  }
  instance_elastic_ip = module.realitctrl_instance.instance_elastic_ip
  hosted_zone      = var.hosted_zone
}