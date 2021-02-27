data "aws_ssm_parameter" "db_master_pw" {
  name = "/wordpress/database/password/master"
}

data "aws_ssm_parameter" "db_user_pw" {
  name = "/wordpress/database/password/user"
}

data "aws_ssm_parameter" "db_user_username" {
  name = "/wordpress/database/username/user"
}

data "template_file" "compose" {
    template = file("${path.module}/docker-compose.yml")
    vars = {
        MYSQL_USER = jsonencode(data.aws_ssm_parameter.db_user_username)
        MYSQL_PASSWORD =jsonencode(data.aws_ssm_parameter.db_user_pw)
        MYSQL_ROOT_PASSWORD = jsonencode(data.aws_ssm_parameter.db_master_pw)
        BUCKET = "https://s3.amazonaws.com/realityctrl.com"
    }
}

resource "aws_s3_bucket_object" "docker_compose_s3" {
  bucket = var.bucket_name
  key = "docker-compose.yml"
  content = data.template_file.compose.rendered
}

data "template_file" "nginx" {
    template = file("${path.module}/nginx.conf")
    vars = {
        DOMAIN = "realityctrl.com"
    }
}

resource "aws_s3_bucket_object" "nginx_s3" {
  bucket = var.bucket_name
  key = "nginx/nginx.conf"
  content = data.template_file.nginx.rendered
}

data "aws_ami" "amazon_linux_arm64_ami" {
  most_recent = true
  filter{
    name = "name"
    values = ["amzn2-ami-minimal-hvm-2.0.*-arm64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_iam_instance_profile" "wordpress_profile" {
  name = "realityctrl-wordpress"
  role = "realityctrl-wordpress"
}

resource "aws_instance" "wordpress" {
    ami           = data.aws_ami.amazon_linux_arm64_ami.id
    instance_type = "t4g.micro"
    iam_instance_profile = aws_iam_instance_profile.wordpress_profile.name
    user_data = <<-EOT
        sudo yum update -y
        sudo yum install -y python3
        sudo yum install -y docker

        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install

        pip install docker-compose
        sudo service docker start
        aws s3api get-object --bucket ${var.bucket_name} -key docker-compose.yml docker-compose.yml
        aws s3api get-object --bucket ${var.bucket_name} -key nginx/nginx.conf nginx.conf
        docker compose up
      
    EOT
    root_block_device {
      volume_type = "gp3"
      volume_size = 30
      iops=3000
      throughput=125
    }
  key_name = "wordpress.pem"
}

resource "aws_eip" "lb" {
  instance = aws_instance.wordpress.id
}