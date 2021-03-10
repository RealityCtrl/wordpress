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
        MYSQL_USER = data.aws_ssm_parameter.db_user_username.value
        MYSQL_PASSWORD = data.aws_ssm_parameter.db_user_pw.value
        MYSQL_ROOT_PASSWORD = data.aws_ssm_parameter.db_master_pw.value
        BUCKET = "https://s3.amazonaws.com/realityctrl.com"
        EMAIL = var.cert_email
        DOMAIN = "realityctrl.com"
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

data "template_file" "nginx_https" {
    template = file("${path.module}/nginx_https.conf")
    vars = {
        DOMAIN = "realityctrl.com"
    }
}

resource "aws_s3_bucket_object" "nginx_https_s3" {
  bucket = var.bucket_name
  key = "nginx/nginx_https.conf"
  content = data.template_file.nginx_https.rendered
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
    user_data = <<EOT
#!/bin/bash
sudo yum install -y https://s3.eu-west-1.amazonaws.com/amazon-ssm-eu-west-1/latest/linux_arm64/amazon-ssm-agent.rpm
echo "yum update"
sudo yum update

echo "yum install docker"
sudo yum install -y docker

echo "yum install zip uzip"
sudo yum install -y zip unzip 

echo "install awscli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "install docker-compose"
sudo yum install -y python37 python3-devel.$(uname -m) libpython3.7-dev libffi-devel openssl-devel 
sudo yum groupinstall -y "Development Tools" # need gcc and friends
sudo python3 -m pip install -U pip  # make sure pip is up2date
python3 -m pip install docker-compose 
docker-compose --version

echo "start docker service"
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo chkconfig docker on

mkdir nginx
echo "download docker-compose.yml"
aws s3api get-object --bucket ${var.bucket_name} --key docker-compose.yml docker-compose.yml --region eu-west-1
echo "download nginx.conf"
aws s3api get-object --bucket ${var.bucket_name} --key nginx/nginx.conf /nginx/nginx.conf --region eu-west-1
echo "start compose file"
docker-compose up -d db wordpress webserver

docker-compose up --no-deps certbot

echo "download nginx_https.conf"
rm nginx/nginx.conf
aws s3api get-object --bucket ${var.bucket_name} --key nginx/nginx_https.conf /nginx/nginx.conf --region eu-west-1
echo "restart nginx"
docker-compose up -d --force-recreate --no-deps webserver
echo "started"
    EOT
    root_block_device {
      volume_type = "gp3"
      volume_size = 30
      iops=3000
      throughput=125
    }
  key_name = "wordpress"
}

resource "aws_eip" "lb" {
  instance = aws_instance.wordpress.id
}