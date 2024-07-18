output "cdn_domain_name" {
  description = "Cloudfront distribution domain name"
  value       = module.cdn.cloudfront_distribution_domain_name
}
