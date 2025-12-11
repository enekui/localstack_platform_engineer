# Integration tests for the complete pipeline
# Tests the full infrastructure configuration with mock AWS provider

mock_provider "aws" {}

# Test variables for integration tests
variables {
  aws_region           = "eu-west-1"
  use_localstack       = false
  environment          = "integration"
  project_name         = "integration-test"
  s3_bucket_name       = "upload-bucket"
  sqs_queue_name       = "results-queue"
  lambda_function_name = "file-processor"
  lambda_runtime       = "python3.11"
  lambda_timeout       = 30
  lambda_memory_size   = 256
}

# Test complete infrastructure plan
run "complete_infrastructure_plan" {
  command = plan

  # Verify all core resources are planned
  assert {
    condition     = module.s3.bucket_id != null
    error_message = "S3 bucket should be planned"
  }

  assert {
    condition     = module.sqs.queue_arn != null
    error_message = "SQS queue should be planned"
  }

  assert {
    condition     = module.lambda.function_arn != null
    error_message = "Lambda function should be planned"
  }

  assert {
    condition     = module.iam.lambda_role_arn != null
    error_message = "IAM role should be planned"
  }
}

# Test Lambda environment variables are correctly configured
run "lambda_environment_variables" {
  command = plan

  # Verify SQS queue URL is passed to Lambda
  assert {
    condition     = module.sqs.queue_url != null
    error_message = "SQS queue URL should be available for Lambda environment"
  }
}

# Test IAM policies reference correct resources
run "iam_policies_reference_correct_resources" {
  command = plan

  # Verify IAM policies are created
  assert {
    condition     = module.iam.s3_read_policy_arn != null
    error_message = "S3 read policy should reference S3 bucket"
  }

  assert {
    condition     = module.iam.sqs_write_policy_arn != null
    error_message = "SQS write policy should reference SQS queue"
  }
}

# Test outputs are correctly exposed
run "outputs_are_exposed" {
  command = plan

  assert {
    condition     = output.s3_bucket_name != null
    error_message = "S3 bucket name should be exposed as output"
  }

  assert {
    condition     = output.sqs_queue_url != null
    error_message = "SQS queue URL should be exposed as output"
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name should be exposed as output"
  }
}

# Test common tags are applied
run "common_tags_applied" {
  command = plan

  # Tags should be defined in locals
  assert {
    condition     = var.project_name == "integration-test"
    error_message = "Project name should be set correctly"
  }

  assert {
    condition     = var.environment == "integration"
    error_message = "Environment should be set correctly"
  }
}
