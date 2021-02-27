variable "bucket_name" {
  type = string
}

variable "admin_arns" {
    type    = list(string)
    default = []
}