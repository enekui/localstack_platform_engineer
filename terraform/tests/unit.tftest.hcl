# Unit tests for individual Terraform modules
# Uses mock AWS provider to test configuration without real AWS resources

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

# Test that variables are correctly configured
run "variables_are_configured" {
  command = plan

  assert {
    condition     = var.aws_region == "eu-west-1"
    error_message = "AWS region should be eu-west-1"
  }

  assert {
    condition     = var.project_name == "test-project"
    error_message = "Project name should be test-project"
  }

  assert {
    condition     = var.lambda_runtime == "python3.11"
    error_message = "Lambda runtime should be python3.11"
  }
}

# Test that locals are constructed correctly
run "locals_naming_convention" {
  command = plan

  assert {
    condition     = local.bucket_name == "test-project-test-bucket"
    error_message = "Bucket name should follow project-bucket naming convention"
  }

  assert {
    condition     = local.queue_name == "test-project-test-queue"
    error_message = "Queue name should follow project-queue naming convention"
  }

  assert {
    condition     = local.function_name == "test-project-test-function"
    error_message = "Function name should follow project-function naming convention"
  }
}

# Test that common tags are defined correctly
run "common_tags_defined" {
  command = plan

  assert {
    condition     = local.common_tags["Project"] == "test-project"
    error_message = "Project tag should be set"
  }

  assert {
    condition     = local.common_tags["Environment"] == "test"
    error_message = "Environment tag should be set"
  }

  assert {
    condition     = local.common_tags["ManagedBy"] == "terraform"
    error_message = "ManagedBy tag should be terraform"
  }
}

# Test S3 bucket ARN is correctly constructed
run "s3_arn_construction" {
  command = plan

  assert {
    condition     = local.s3_bucket_arn == "arn:aws:s3:::test-project-test-bucket"
    error_message = "S3 bucket ARN should be correctly constructed"
  }
}

# Test SQS queue ARN is correctly constructed
run "sqs_arn_construction" {
  command = plan

  assert {
    condition     = local.sqs_queue_arn == "arn:aws:sqs:eu-west-1:123456789012:test-project-test-queue"
    error_message = "SQS queue ARN should be correctly constructed with account ID"
  }
}
