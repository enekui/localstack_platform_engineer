variable "role_name" {
  description = "Name of the IAM role for Lambda"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for read access"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for write access"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for CloudWatch log group"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
