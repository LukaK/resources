output "api_url" {
  description = "Api gateway url"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}
