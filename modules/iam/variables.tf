variable "bucket_name" {
    type=string
}

variable "aws_account_id" {
    type=string
}

variable "admin_arns" {
    type    = list(string)
    default = []
}