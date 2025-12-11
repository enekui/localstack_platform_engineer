locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Construct names and ARNs to avoid circular dependencies
  bucket_name   = "${var.project_name}-${var.s3_bucket_name}"
  queue_name    = "${var.project_name}-${var.sqs_queue_name}"
  function_name = "${var.project_name}-${var.lambda_function_name}"
  s3_bucket_arn = "arn:aws:s3:::${local.bucket_name}"
  sqs_queue_arn = "arn:aws:sqs:${var.aws_region}:000000000000:${local.queue_name}"
}

# IAM role and policies for Lambda (created first, uses constructed ARNs)
module "iam" {
  source = "./modules/iam"

  role_name            = "${var.project_name}-lambda-role"
  s3_bucket_arn        = local.s3_bucket_arn
  sqs_queue_arn        = local.sqs_queue_arn
  lambda_function_name = local.function_name
  aws_region           = var.aws_region

  tags = local.common_tags
}

# SQS Queue for processing results
module "sqs" {
  source = "./modules/sqs"

  queue_name                = local.queue_name
  visibility_timeout        = var.lambda_timeout + 10
  message_retention_seconds = 345600 # 4 days

  tags = local.common_tags
}

# Lambda function for file processing
module "lambda" {
  source = "./modules/lambda"

  function_name   = local.function_name
  description     = "Calculates S3 object size by streaming content"
  handler         = "handler.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  lambda_role_arn = module.iam.lambda_role_arn
  source_path     = "${path.module}/../lambda"
  s3_bucket_arn   = local.s3_bucket_arn

  environment_variables = {
    SQS_QUEUE_URL    = module.sqs.queue_url
    AWS_ENDPOINT_URL = var.use_localstack ? var.localstack_endpoint : null
  }

  tags = local.common_tags

  depends_on = [module.iam]
}

# S3 Bucket for file uploads (created last to avoid circular dependency)
module "s3" {
  source = "./modules/s3"

  bucket_name   = local.bucket_name
  force_destroy = true

  # Lambda trigger configuration
  enable_lambda_notification   = true
  lambda_function_arn          = module.lambda.function_arn
  lambda_permission_dependency = module.lambda.function_arn

  tags = local.common_tags
}
