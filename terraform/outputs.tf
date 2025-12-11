output "s3_bucket_name" {
  description = "Name of the S3 bucket for file uploads"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue for processing results"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = module.sqs.queue_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_role_arn
}
