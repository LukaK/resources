output "user_pool_client_id" {
  description = "Id of the user pool client"
  value       = aws_cognito_user_pool_client.client.id
}
