# Define the API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "my-api-gateway"
  description = "API Gateway for authorizing users and issuing signed cookies"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Define the OAuth configuration
resource "aws_api_gateway_authorizer" "oauth_authorizer" {
  name                             = "oauth-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api_gateway.id
  type                             = "COGNITO_USER_POOLS"
  identity_source                  = "method.request.header.Authorization"
  provider_arns                    = [aws_cognito_user_pool.user_pool.arn]
  authorizer_result_ttl_in_seconds = 300
}

# Configure the API Gateway to trigger the Lambda function and protect it using OAuth and Cognito
resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "signed-cookies"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.oauth_authorizer.id
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_function.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "prod"
}


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api_gateway.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name = "lambda-cloudfront-signer"
  description   = "Lambda function for issuing signed cookies"
  handler       = "code.lambda_signer.lambda_handler"
  runtime       = "python3.12"

  build_in_docker = true
  source_path     = "../api/cloudfront-signer"

  environment_variables = {
    REGION_NAME       = data.aws_region.current.name
    SM_PRIVATE_KEY_ID = aws_secretsmanager_secret.private_key.id
    PRIVATE_KEY_ID    = aws_cloudfront_public_key.example_key.id
    CDN_DOMAIN_NAME   = var.domain_name
    CDN_PRIVATE_PATH  = "https://${var.domain_name}/private/*"
  }

  attach_policy_statements = true
  policy_statements = {
    sm = {
      effect    = "Allow",
      actions   = ["secretsmanager:GetSecretValue"],
      resources = [aws_secretsmanager_secret.private_key.id]
    }
  }
}
