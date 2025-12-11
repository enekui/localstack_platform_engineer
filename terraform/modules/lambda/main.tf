module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = var.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Use existing IAM role (created by IAM module)
  create_role = false
  lambda_role = var.lambda_role_arn

  # Source code
  source_path = var.source_path

  # Environment variables
  environment_variables = var.environment_variables

  # S3 trigger permission
  allowed_triggers = var.s3_bucket_arn != null ? {
    S3BucketNotification = {
      service    = "s3"
      source_arn = var.s3_bucket_arn
    }
  } : {}

  # Disable versioning to avoid $LATEST permission issue
  create_current_version_allowed_triggers = false

  tags = var.tags
}
