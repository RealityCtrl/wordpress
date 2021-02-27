resource "random_password" "database_master_password" {
  length = 128
}

resource "random_password" "database_server_password" {
  length = 128
}
resource "random_password" "database_server_user" {
  length = 128
}

resource "aws_ssm_parameter" "database_root_password" {
  name        = "/wordpress/database/password/master"
  description = "Master MySql Password"
  type        = "SecureString"
  value       = random_password.database_master_password.result

  tags = {
    environment = "production"
    system = "wordpress"
  }
}

resource "aws_ssm_parameter" "database_password" {
  name        = "/wordpress/database/password/user"
  description = "Wordpress MySql User Password"
  type        = "SecureString"
  value       = random_password.database_server_password.result

  tags = {
    environment = "production"
    system = "wordpress"
  }
}

resource "aws_ssm_parameter" "database_username" {
  name        = "/wordpress/database/username/user"
  description = "Wordpress MySql User Password"
  type        = "SecureString"
  value       = random_password.database_server_user.result

  tags = {
    environment = "production"
    system = "wordpress"
  }
}