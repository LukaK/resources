output "api_custom_domain_name" {
  value       = "https://api.${var.domain_name}"
  description = "Api gateway domain name"
}
