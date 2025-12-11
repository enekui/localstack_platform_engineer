output "queue_id" {
  description = "The URL of the SQS queue"
  value       = module.sqs.queue_id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = module.sqs.queue_arn
}

output "queue_url" {
  description = "The URL of the SQS queue"
  value       = module.sqs.queue_url
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = module.sqs.queue_name
}

output "dlq_arn" {
  description = "The ARN of the dead letter queue"
  value       = var.create_dlq ? module.sqs.dead_letter_queue_arn : null
}
