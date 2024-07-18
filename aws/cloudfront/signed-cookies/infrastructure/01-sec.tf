module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = var.domain_name
  zone_id     = var.route53_zone_id
  subject_alternative_names = [
    var.domain_name,
    "api.${var.domain_name}"
  ]
}


resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_secretsmanager_secret" "private_key" {}
resource "aws_secretsmanager_secret_version" "private_key_value" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.example.private_key_pem
}
