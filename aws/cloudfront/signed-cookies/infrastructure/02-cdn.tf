module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.0"

  comment             = "Example Cloudfront Distribution"
  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = false
  wait_for_deployment = true

  aliases = [var.domain_name]

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
      domain_name           = module.media_bucket.s3_bucket_bucket_domain_name
      origin_access_control = "s3_oac"
    }
  }

  ordered_cache_behavior = [
    {
      target_origin_id       = "media_bucket"
      viewer_protocol_policy = "redirect-to-https"
      path_pattern           = "/private/*"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      trusted_key_groups = [aws_cloudfront_key_group.example_key_group.id]

    }
  ]

  default_cache_behavior = {
    target_origin_id       = "media_bucket"
    viewer_protocol_policy = "redirect-to-https"

    path_pattern = "/public/*"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
  }

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

}

resource "aws_route53_record" "record" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.route53_zone_id

  alias {
    evaluate_target_health = true
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
  }
}


resource "aws_cloudfront_public_key" "example_key" {
  comment     = "example public key"
  name        = "example-key"
  encoded_key = tls_private_key.example.public_key_pem
}

resource "aws_cloudfront_key_group" "example_key_group" {
  comment = "example key group"
  items   = [aws_cloudfront_public_key.example_key.id]
  name    = "example-key-group"
}

module "media_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  # Allow deletion of non-empty bucket
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "s3_policy" {

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.media_bucket.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.media_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}
