resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  tags = var.tags
}

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                       = "${var.queue_name}-dlq"
  message_retention_seconds  = var.dlq_message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout

  tags = var.tags
}

resource "aws_sqs_queue_redrive_policy" "this" {
  count = var.create_dlq ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  })
}
