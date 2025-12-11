# Lambda execution role using official IAM module
module "lambda_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role             = true
  role_name               = var.role_name
  role_requires_mfa       = false
  trusted_role_services   = ["lambda.amazonaws.com"]
  custom_role_policy_arns = [
    module.s3_read_policy.arn,
    module.sqs_write_policy.arn,
    module.cloudwatch_logs_policy.arn
  ]

  tags = var.tags
}

# S3 read policy (least privilege - specific bucket only)
module "s3_read_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name        = "${var.role_name}-s3-read"
  description = "Allow Lambda to read from specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetObjectFromBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })

  tags = var.tags
}

# SQS write policy (least privilege - specific queue only)
module "sqs_write_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name        = "${var.role_name}-sqs-write"
  description = "Allow Lambda to write to specific SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SendMessageToQueue"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_arn
      }
    ]
  })

  tags = var.tags
}

# CloudWatch Logs policy (required for Lambda logging)
module "cloudwatch_logs_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name        = "${var.role_name}-cloudwatch-logs"
  description = "Allow Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateLogGroup"
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.lambda_function_name}:*"
      }
    ]
  })

  tags = var.tags
}
