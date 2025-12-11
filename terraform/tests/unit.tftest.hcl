# Unit tests for individual Terraform modules
# Uses mock AWS provider to test without real AWS resources

mock_provider "aws" {}

# Test variables for unit tests
variables {
  aws_region           = "eu-west-1"
  use_localstack       = false
  environment          = "test"
  project_name         = "test-project"
  s3_bucket_name       = "test-bucket"
  sqs_queue_name       = "test-queue"
  lambda_function_name = "test-function"
  lambda_runtime       = "python3.11"
  lambda_timeout       = 30
  lambda_memory_size   = 256
}

# Test S3 module configuration
run "s3_module_creates_bucket" {
  command = plan

  assert {
    condition     = module.s3.bucket_id != null
    error_message = "S3 bucket should be created"
  }

  assert {
    condition     = module.s3.bucket_arn != null
    error_message = "S3 bucket ARN should be available"
  }
}

# Test SQS module configuration
run "sqs_module_creates_queue" {
  command = plan

  assert {
    condition     = module.sqs.queue_arn != null
    error_message = "SQS queue should be created"
  }

  assert {
    condition     = module.sqs.queue_url != null
    error_message = "SQS queue URL should be available"
  }
}

# Test IAM module creates role with correct configuration
run "iam_module_creates_role" {
  command = plan

  assert {
    condition     = module.iam.lambda_role_arn != null
    error_message = "Lambda IAM role should be created"
  }

  assert {
    condition     = module.iam.s3_read_policy_arn != null
    error_message = "S3 read policy should be created"
  }

  assert {
    condition     = module.iam.sqs_write_policy_arn != null
    error_message = "SQS write policy should be created"
  }
}

# Test Lambda module configuration
run "lambda_module_creates_function" {
  command = plan

  assert {
    condition     = module.lambda.function_arn != null
    error_message = "Lambda function should be created"
  }

  assert {
    condition     = module.lambda.function_name != null
    error_message = "Lambda function name should be available"
  }
}

# Test resource naming convention
run "resources_follow_naming_convention" {
  command = plan

  assert {
    condition     = can(regex("^test-project-", module.s3.bucket_id))
    error_message = "S3 bucket name should follow naming convention"
  }

  assert {
    condition     = can(regex("^test-project-", module.lambda.function_name))
    error_message = "Lambda function name should follow naming convention"
  }
}
