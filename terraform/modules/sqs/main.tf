module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name = var.queue_name

  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Dead letter queue configuration
  create_dlq = var.create_dlq
  dlq_name   = var.create_dlq ? "${var.queue_name}-dlq" : null
  redrive_policy = var.create_dlq ? {
    maxReceiveCount = var.max_receive_count
  } : {}
  dlq_message_retention_seconds = var.dlq_message_retention_seconds

  tags = var.tags
}
