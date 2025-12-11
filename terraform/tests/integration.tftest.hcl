# Integration tests for the complete pipeline
# Tests the full infrastructure configuration with mock AWS provider

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "AIDATEST"
    }
  }

  override_data {
    target = module.iam.module.lambda_role.data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "AIDATEST"
    }
  }

  override_data {
    target = module.iam.module.lambda_role.data.aws_partition.current
    values = {
      partition          = "aws"
      dns_suffix         = "amazonaws.com"
      reverse_dns_prefix = "com.amazonaws"
    }
  }

  override_data {
    target = module.iam.module.lambda_role.data.aws_iam_policy_document.assume_role[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":[\"sts:AssumeRole\",\"sts:TagSession\"]}]}"
    }
  }

  override_data {
    target = module.s3.module.s3_bucket.data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = module.s3.module.s3_bucket.data.aws_partition.current
    values = {
      partition = "aws"
    }
  }

  override_data {
    target = module.s3.module.s3_bucket.data.aws_region.current
    values = {
      name = "eu-west-1"
    }
  }

  override_data {
    target = module.sqs.module.sqs.data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = module.sqs.module.sqs.data.aws_partition.current
    values = {
      partition = "aws"
    }
  }

  override_data {
    target = module.sqs.module.sqs.data.aws_region.current
    values = {
      name = "eu-west-1"
    }
  }

  override_data {
    target = module.lambda.module.lambda_function.data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = module.lambda.module.lambda_function.data.aws_partition.current
    values = {
      partition = "aws"
    }
  }

  override_data {
    target = module.lambda.module.lambda_function.data.aws_region.current
    values = {
      name = "eu-west-1"
    }
  }
}

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

# Test complete infrastructure configuration
run "complete_infrastructure_configuration" {
  command = plan

  # Verify resource naming follows convention
  assert {
    condition     = local.bucket_name == "integration-test-upload-bucket"
    error_message = "S3 bucket should follow project naming convention"
  }

  assert {
    condition     = local.queue_name == "integration-test-results-queue"
    error_message = "SQS queue should follow project naming convention"
  }

  assert {
    condition     = local.function_name == "integration-test-file-processor"
    error_message = "Lambda function should follow project naming convention"
  }
}

# Test IAM policies reference correct resources
run "iam_policies_use_correct_arns" {
  command = plan

  # Verify S3 ARN is correctly constructed
  assert {
    condition     = local.s3_bucket_arn == "arn:aws:s3:::integration-test-upload-bucket"
    error_message = "S3 bucket ARN should be correctly constructed for IAM policy"
  }

  # Verify SQS ARN includes account ID
  assert {
    condition     = local.sqs_queue_arn == "arn:aws:sqs:eu-west-1:123456789012:integration-test-results-queue"
    error_message = "SQS queue ARN should include account ID for IAM policy"
  }
}

# Test environment configuration
run "environment_configuration" {
  command = plan

  assert {
    condition     = var.environment == "integration"
    error_message = "Environment should be integration"
  }

  assert {
    condition     = local.common_tags["Environment"] == "integration"
    error_message = "Environment tag should be set correctly"
  }
}

# Test Lambda configuration
run "lambda_configuration" {
  command = plan

  assert {
    condition     = var.lambda_timeout == 30
    error_message = "Lambda timeout should be 30 seconds"
  }

  assert {
    condition     = var.lambda_memory_size == 256
    error_message = "Lambda memory should be 256 MB"
  }

  assert {
    condition     = var.lambda_runtime == "python3.11"
    error_message = "Lambda runtime should be python3.11"
  }
}

# Test LocalStack vs AWS configuration
run "localstack_disabled_uses_real_account" {
  command = plan

  # When use_localstack is false, account_id should use data source
  assert {
    condition     = var.use_localstack == false
    error_message = "use_localstack should be false for integration tests"
  }

  # Account ID should be from data source (123456789012 from mock)
  assert {
    condition     = local.account_id == "123456789012"
    error_message = "Account ID should be from AWS data source when not using LocalStack"
  }
}
