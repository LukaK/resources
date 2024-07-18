module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  aliases = [var.domain_name]

  comment             = "Example Cloudfront Distribution"
  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = false
  wait_for_deployment = true

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    media_bucket = {
      domain_name           = module.bucket.s3_bucket_bucket_domain_name
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "media_bucket"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
  }

  viewer_certificate = {
    acm_certificate_arn = var.certificate_arn
    ssl_support_method  = "sni-only"
  }

}
