output "cdn_custom_domain_name" {
  value       = "https://${var.domain_name}"
  description = "Cloudfront custom domain name"
}

output "media_bucket_name" {
  description = "Name of the media bucket"
  value       = module.media_bucket.s3_bucket_id
}
