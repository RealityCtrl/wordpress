provider "aws" {
  alias = "default"
  profile = var.aws_profile
  region  = var.aws_region
}