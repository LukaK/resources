module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name = "test-function"
  description   = "Test lambda api handler"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  source_path = "../api/"
}
