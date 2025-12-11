# Deployment Examples

This folder contains deployment examples for both LocalStack (local development) and AWS Cloud (production).

## LocalStack Example

Deploy to LocalStack for local development and testing.

```bash
# Start LocalStack
localstack start -d
localstack wait -t 30

# Deploy
cd localstack
terraform init
terraform apply -auto-approve

# Verify
../../scripts/verify.sh

# Cleanup
terraform destroy -auto-approve
localstack stop
```

## AWS Cloud Example

Deploy to real AWS infrastructure.

```bash
# Configure credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-west-1"

# Deploy
cd aws
terraform init
terraform plan
terraform apply

# Test
aws s3 cp /tmp/test.bin s3://$(terraform output -raw s3_bucket_name)/test.bin
aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)

# Cleanup
terraform destroy
```

## Key Differences

| Feature | LocalStack | AWS Cloud |
|---------|------------|-----------|
| `use_localstack` | `true` | `false` |
| Endpoint | `http://localhost:4566` | AWS default |
| Account ID | `000000000000` | Real AWS account |
| Credentials | `test/test` | Real IAM credentials |
| Cost | Free | AWS pricing applies |
