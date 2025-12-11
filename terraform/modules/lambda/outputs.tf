output "function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.lambda_function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_invoke_arn
}

output "function_url" {
  description = "Lambda function URL (if enabled)"
  value       = try(module.lambda_function.lambda_function_url, null)
}
