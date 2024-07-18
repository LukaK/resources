resource "aws_api_gateway_domain_name" "example" {
  domain_name              = "api.${var.domain_name}"
  regional_certificate_arn = module.acm.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


resource "aws_route53_record" "example" {
  name    = aws_api_gateway_domain_name.example.domain_name
  type    = "A"
  zone_id = var.route53_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.example.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.example.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "example" {
  api_id      = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.example.domain_name
}
