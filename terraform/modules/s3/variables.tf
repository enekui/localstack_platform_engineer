variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "enable_lambda_notification" {
  description = "Enable S3 notification to Lambda"
  type        = bool
  default     = true
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to trigger on object creation"
  type        = string
  default     = ""
}

variable "notification_prefix" {
  description = "Prefix filter for S3 notifications"
  type        = string
  default     = ""
}

variable "notification_suffix" {
  description = "Suffix filter for S3 notifications"
  type        = string
  default     = ""
}

variable "lambda_permission_dependency" {
  description = "Dependency to ensure Lambda permission is created before notification"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
