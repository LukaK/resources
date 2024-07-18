variable "test_user_username" {
  type        = string
  description = "Test user username"
}

variable "test_user_password" {
  type        = string
  description = "Test user password"
  sensitive   = true
}
