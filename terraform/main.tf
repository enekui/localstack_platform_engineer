locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# SQS Queue for processing results
module "sqs" {
  source = "./modules/sqs"

  queue_name                = "${var.project_name}-${var.sqs_queue_name}"
  visibility_timeout        = var.lambda_timeout + 10
  message_retention_seconds = 345600 # 4 days

  tags = local.common_tags
}

# S3 Bucket for file uploads
module "s3" {
  source = "./modules/s3"

  bucket_name   = "${var.project_name}-${var.s3_bucket_name}"
  force_destroy = true

  # Lambda trigger configuration
  lambda_function_arn          = module.lambda.function_arn
  lambda_permission_dependency = module.lambda.function_arn

  tags = local.common_tags

  depends_on = [module.lambda]
}

# IAM role and policies for Lambda
module "iam" {
  source = "./modules/iam"

  role_name            = "${var.project_name}-lambda-role"
  s3_bucket_arn        = module.s3.bucket_arn
  sqs_queue_arn        = module.sqs.queue_arn
  lambda_function_name = "${var.project_name}-${var.lambda_function_name}"
  aws_region           = var.aws_region

  tags = local.common_tags

  depends_on = [module.s3, module.sqs]
}

# Lambda function for file processing
module "lambda" {
  source = "./modules/lambda"

  function_name   = "${var.project_name}-${var.lambda_function_name}"
  description     = "Calculates S3 object size by streaming content"
  handler         = "handler.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  lambda_role_arn = module.iam.lambda_role_arn
  source_path     = "${path.module}/../lambda"
  s3_bucket_arn   = module.s3.bucket_arn

  environment_variables = {
    SQS_QUEUE_URL    = module.sqs.queue_url
    AWS_ENDPOINT_URL = var.use_localstack ? var.localstack_endpoint : null
  }

  tags = local.common_tags

  depends_on = [module.iam]
}
