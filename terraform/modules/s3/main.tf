module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  # Versioning
  versioning = var.enable_versioning ? {
    enabled = true
  } : {}

  tags = var.tags
}

# S3 bucket notification for Lambda trigger
resource "aws_s3_bucket_notification" "lambda_trigger" {
  count  = var.enable_lambda_notification ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.notification_prefix
    filter_suffix       = var.notification_suffix
  }

  depends_on = [var.lambda_permission_dependency]
}
