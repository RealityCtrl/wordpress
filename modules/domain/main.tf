
resource "aws_route53_record" "realityctrl_www" {
  zone_id = var.hosted_zone
  name    = "www.realityctrl.com"
  type    = "A"
  ttl     = "300"
  records = [var.instance_elastic_ip]
}

resource "aws_route53_record" "realityctrl" {
  zone_id = var.hosted_zone
  name    = "realityctrl.com"
  type    = "A"
  ttl     = "300"
  records = [var.instance_elastic_ip]
}
