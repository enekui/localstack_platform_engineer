# LocalStack Deployment Example
#
# This example demonstrates how to deploy the file processing pipeline
# to LocalStack for local development and testing.
#
# Prerequisites:
#   - LocalStack CLI installed: brew install localstack/tap/localstack-cli
#   - Terraform >= 1.0.0
#
# Usage:
#   1. Start LocalStack:
#      localstack start -d
#      localstack wait -t 30
#
#   2. Deploy infrastructure:
#      cd examples/localstack
#      terraform init
#      terraform apply -auto-approve
#
#   3. Verify the pipeline:
#      ../../scripts/verify.sh
#
#   4. Cleanup:
#      terraform destroy -auto-approve
#      localstack stop

module "file_processor" {
  source = "../../terraform"

  # LocalStack configuration (default)
  use_localstack      = true
  localstack_endpoint = "http://localhost:4566"

  # Project configuration
  aws_region   = "eu-west-1"
  environment  = "dev"
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

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = module.file_processor.sqs_queue_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.file_processor.lambda_function_name
}
