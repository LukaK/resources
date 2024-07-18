resource "aws_cognito_user_pool" "user_pool" {
  name = "my-user-pool"

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "birthdate"
    required                 = false

    string_attribute_constraints {
      max_length = "10"
      min_length = "4"
    }
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                = "my-user-pool-client"
  user_pool_id        = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.test_user_username
  password     = var.test_user_password

}
