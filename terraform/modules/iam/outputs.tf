output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.lambda_role.iam_role_arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = module.lambda_role.iam_role_name
}

output "s3_read_policy_arn" {
  description = "ARN of the S3 read policy"
  value       = module.s3_read_policy.arn
}

output "sqs_write_policy_arn" {
  description = "ARN of the SQS write policy"
  value       = module.sqs_write_policy.arn
}

output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch logs policy"
  value       = module.cloudwatch_logs_policy.arn
}
