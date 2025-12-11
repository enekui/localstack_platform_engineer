# AWS Cloud Deployment Example
#
# This example demonstrates how to deploy the file processing pipeline
# to real AWS infrastructure.
#
# Prerequisites:
#   - Terraform >= 1.0.0
#   - AWS CLI configured with valid credentials
#   - Appropriate IAM permissions to create S3, SQS, Lambda, and IAM resources
#
# Usage:
#   1. Configure AWS credentials:
#      export AWS_ACCESS_KEY_ID="your-access-key"
#      export AWS_SECRET_ACCESS_KEY="your-secret-key"
#      export AWS_REGION="eu-west-1"
#
#   2. Deploy infrastructure:
#      cd examples/aws
#      terraform init
#      terraform plan
#      terraform apply
#
#   3. Test the pipeline:
#      # Create a test file
#      dd if=/dev/urandom of=/tmp/test.bin bs=1024 count=1024
#
#      # Upload to S3
#      aws s3 cp /tmp/test.bin s3://$(terraform output -raw s3_bucket_name)/test.bin
#
#      # Check SQS for result
#      aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)
#
#   4. Cleanup:
#      terraform destroy

module "file_processor" {
  source = "../../terraform"

  # AWS Cloud configuration
  use_localstack = false

  # Project configuration
  aws_region   = "eu-west-1"
  environment  = "prod"
  project_name = "file-processor"

  # Resource names
  s3_bucket_name       = "file-upload-bucket"
  sqs_queue_name       = "file-processing-results"
  lambda_function_name = "file-size-calculator"

  # Lambda configuration
  lambda_runtime     = "python3.11"
  lambda_timeout     = 30
  lambda_memory_size = 256
}

# Outputs for verification
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.file_processor.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.file_processor.s3_bucket_arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = module.file_processor.sqs_queue_url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = module.file_processor.sqs_queue_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.file_processor.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.file_processor.lambda_function_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.file_processor.lambda_role_arn
}
