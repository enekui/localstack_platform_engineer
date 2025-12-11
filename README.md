# LocalStack Platform Engineering - File Processing Pipeline

An event-driven file processing pipeline built with Terraform and LocalStack. This solution demonstrates cloud-native architecture patterns using AWS services (S3, Lambda, SQS) that can run locally with LocalStack or deploy to real AWS infrastructure.

## Architecture

```
                         FILE PROCESSING PIPELINE
    ┌──────────────────────────────────────────────────────────────────┐
    │                                                                  │
    │   ┌─────────┐      ┌─────────────┐      ┌─────────────────────┐ │
    │   │         │      │             │      │                     │ │
    │   │   S3    │─────▶│   Lambda    │─────▶│        SQS          │ │
    │   │ Bucket  │      │  Function   │      │       Queue         │ │
    │   │         │      │             │      │                     │ │
    │   └─────────┘      └─────────────┘      └─────────────────────┘ │
    │       │                  │                        │             │
    │       │                  │                        │             │
    │   Upload File      Stream & Calculate        Result Message    │
    │   (Trigger)        Object Size               {object_uri,      │
    │                                               size_mb}         │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘

    Data Flow:
    ──────────
    1. User uploads file to S3 bucket
    2. S3 triggers Lambda function
    3. Lambda streams object content to calculate size
    4. Lambda sends result message to SQS queue
```

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform-tests.yml   # CI/CD pipeline for Terraform tests
├── terraform/
│   ├── main.tf                   # Root module - orchestrates all resources
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── providers.tf              # AWS/LocalStack provider configuration
│   ├── tests/
│   │   ├── unit.tftest.hcl       # Unit tests (mock AWS)
│   │   └── integration.tftest.hcl # Integration tests (mock AWS)
│   └── modules/
│       ├── s3/                   # S3 bucket wrapper module
│       ├── sqs/                  # SQS queue wrapper module
│       ├── lambda/               # Lambda function wrapper module
│       └── iam/                  # IAM roles/policies wrapper module
├── lambda/
│   └── handler.py                # Python Lambda handler
├── scripts/
│   └── verify.sh                 # Pipeline verification script
├── examples/
│   ├── localstack/               # LocalStack deployment example
│   │   └── main.tf
│   └── aws/                      # AWS Cloud deployment example
│       └── main.tf
└── README.md                     # This file
```

## Requirements

- **Docker**: >= 20.10
- **LocalStack CLI**: >= 3.0 (see [installation guide](https://docs.localstack.cloud/getting-started/installation/))
- **Terraform**: >= 1.0.0
- **AWS CLI**: >= 2.0 (for verification script)
- **jq**: For JSON parsing in verification script

### Installing LocalStack CLI

**macOS (Homebrew):**
```bash
brew install localstack/tap/localstack-cli
```

**Linux/Other:**
```bash
pip install localstack
```

For detailed installation instructions, see: https://docs.localstack.cloud/getting-started/installation/

## Quick Start

### 1. Start LocalStack

```bash
# Start LocalStack in detached mode
localstack start -d

# Wait for LocalStack to be ready
localstack wait -t 30

# Verify LocalStack is running
localstack status
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply -auto-approve
```

### 3. Verify the Pipeline

```bash
# Run the verification script
./scripts/verify.sh
```

The script will:
1. Generate a 1MB test file with random content
2. Upload it to the S3 bucket
3. Poll the SQS queue for the processing result
4. Display the result message

Expected output:
```json
{
  "object_uri": "s3://file-processor-file-upload-bucket/test-uploads/test-file-1234567890.bin",
  "size_mb": 1.00
}
```

### 4. Cleanup

```bash
# Destroy Terraform resources
cd terraform
terraform destroy -auto-approve

# Stop LocalStack
localstack stop
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCALSTACK_ENDPOINT` | `http://localhost:4566` | LocalStack endpoint URL |
| `AWS_REGION` | `eu-west-1` | AWS region |
| `S3_BUCKET` | `file-processor-file-upload-bucket` | S3 bucket name |
| `SQS_QUEUE` | `file-processor-file-processing-results` | SQS queue name |
| `TEST_FILE_SIZE_MB` | `1` | Size of test file in MB |

### Terraform Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-west-1` | AWS region |
| `use_localstack` | `true` | Use LocalStack instead of real AWS |
| `environment` | `dev` | Environment name |
| `project_name` | `file-processor` | Project name prefix |

## Deployment Examples

Ready-to-use deployment examples are available in the `examples/` folder:

### LocalStack (Local Development)

```bash
cd examples/localstack
terraform init
terraform apply -auto-approve
```

### AWS Cloud (Production)

```bash
cd examples/aws
terraform init
terraform apply
```

See [examples/README.md](examples/README.md) for detailed instructions.

## Deploying to Real AWS

To deploy to real AWS instead of LocalStack:

```bash
cd terraform

# Set variables for AWS deployment
terraform apply \
  -var="use_localstack=false" \
  -var="environment=prod"
```

Make sure you have valid AWS credentials configured:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="eu-west-1"
```

### Key Differences: LocalStack vs AWS

| Feature | LocalStack | AWS Cloud |
|---------|------------|-----------|
| `use_localstack` | `true` (default) | `false` |
| Endpoint | `http://localhost:4566` | AWS default |
| Account ID | `000000000000` | Real AWS account |
| Credentials | `test/test` | Real IAM credentials |
| Cost | Free | AWS pricing applies |

## Running Tests

### Terraform Tests

```bash
cd terraform

# Run all tests
terraform test

# Run unit tests only
terraform test -filter=tests/unit.tftest.hcl

# Run integration tests only
terraform test -filter=tests/integration.tftest.hcl
```

### Terraform Validation

```bash
cd terraform

# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate
```

## LocalStack CLI Commands

```bash
# Start LocalStack
localstack start -d

# Check status
localstack status

# View logs
localstack logs

# Stop LocalStack
localstack stop

# Restart LocalStack
localstack restart
```

## Security

This solution implements **least privilege IAM policies**:

- **Lambda Role**: Can only:
  - Read objects from the specific S3 bucket (`s3:GetObject`)
  - Send messages to the specific SQS queue (`sqs:SendMessage`)
  - Write logs to CloudWatch Logs

- **No wildcard permissions**: All IAM policies are scoped to specific resource ARNs

## Module Dependencies

This project uses official Terraform AWS modules as base:

- [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest)
- [terraform-aws-modules/sqs/aws](https://registry.terraform.io/modules/terraform-aws-modules/sqs/aws/latest)
- [terraform-aws-modules/lambda/aws](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest)
- [terraform-aws-modules/iam/aws](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest)

## Troubleshooting

### LocalStack not starting
```bash
# Check Docker is running
docker info

# Check LocalStack status
localstack status

# View LocalStack logs
localstack logs
```

### Lambda not triggering
```bash
# Check S3 bucket notification configuration
aws --endpoint-url=http://localhost:4566 \
    s3api get-bucket-notification-configuration \
    --bucket file-processor-file-upload-bucket
```

### No messages in SQS
```bash
# Check Lambda logs
aws --endpoint-url=http://localhost:4566 \
    logs tail /aws/lambda/file-processor-file-size-calculator \
    --follow
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
