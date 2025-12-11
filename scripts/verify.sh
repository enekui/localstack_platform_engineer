#!/bin/bash
#
# Verification script for the file processing pipeline
# This script tests the complete pipeline by:
# 1. Generating a dummy file with random content
# 2. Uploading it to the S3 bucket
# 3. Polling the SQS queue for the processing result
# 4. Displaying the result to verify the pipeline works
#

set -e

# Configuration
LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
AWS_REGION="${AWS_REGION:-eu-west-1}"
S3_BUCKET="${S3_BUCKET:-file-processor-file-upload-bucket}"
SQS_QUEUE="${SQS_QUEUE:-file-processor-file-processing-results}"
TEST_FILE_SIZE_MB="${TEST_FILE_SIZE_MB:-1}"
MAX_POLL_ATTEMPTS="${MAX_POLL_ATTEMPTS:-30}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if LocalStack is running
check_localstack() {
    log_info "Checking if LocalStack is running..."
    if curl -s "${LOCALSTACK_ENDPOINT}/_localstack/health" > /dev/null 2>&1; then
        log_success "LocalStack is running"
        return 0
    else
        log_error "LocalStack is not running. Please start it with: docker-compose up -d"
        return 1
    fi
}

# Get SQS Queue URL
get_queue_url() {
    aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
        --region "${AWS_REGION}" \
        sqs get-queue-url \
        --queue-name "${SQS_QUEUE}" \
        --query 'QueueUrl' \
        --output text 2>/dev/null
}

# Generate a test file with random content
generate_test_file() {
    local file_path="$1"
    local size_mb="$2"

    log_info "Generating test file (${size_mb}MB)..."
    dd if=/dev/urandom of="${file_path}" bs=1M count="${size_mb}" 2>/dev/null

    local actual_size=$(stat -f%z "${file_path}" 2>/dev/null || stat -c%s "${file_path}" 2>/dev/null)
    log_success "Generated test file: ${file_path} (${actual_size} bytes)"
}

# Upload file to S3
upload_to_s3() {
    local file_path="$1"
    local s3_key="$2"

    log_info "Uploading file to s3://${S3_BUCKET}/${s3_key}..."

    aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
        --region "${AWS_REGION}" \
        s3 cp "${file_path}" "s3://${S3_BUCKET}/${s3_key}"

    log_success "File uploaded successfully"
}

# Poll SQS queue for results
poll_sqs() {
    local queue_url="$1"
    local expected_key="$2"
    local attempt=1

    log_info "Polling SQS queue for results (max ${MAX_POLL_ATTEMPTS} attempts)..."

    while [ $attempt -le $MAX_POLL_ATTEMPTS ]; do
        log_info "Attempt ${attempt}/${MAX_POLL_ATTEMPTS}..."

        local message=$(aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
            --region "${AWS_REGION}" \
            sqs receive-message \
            --queue-url "${queue_url}" \
            --max-number-of-messages 1 \
            --wait-time-seconds 5 \
            --query 'Messages[0]' \
            --output json 2>/dev/null)

        if [ "$message" != "null" ] && [ -n "$message" ]; then
            local body=$(echo "$message" | jq -r '.Body')
            local receipt_handle=$(echo "$message" | jq -r '.ReceiptHandle')

            # Check if this message is for our file
            if echo "$body" | jq -e ".object_uri | contains(\"${expected_key}\")" > /dev/null 2>&1; then
                log_success "Received result message!"
                echo ""
                echo "========================================"
                echo "         PIPELINE RESULT"
                echo "========================================"
                echo "$body" | jq '.'
                echo "========================================"
                echo ""

                # Delete the message from queue
                aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
                    --region "${AWS_REGION}" \
                    sqs delete-message \
                    --queue-url "${queue_url}" \
                    --receipt-handle "${receipt_handle}" 2>/dev/null

                return 0
            fi
        fi

        sleep $POLL_INTERVAL
        attempt=$((attempt + 1))
    done

    log_error "Timeout waiting for SQS message"
    return 1
}

# Cleanup function
cleanup() {
    local file_path="$1"
    if [ -f "${file_path}" ]; then
        rm -f "${file_path}"
        log_info "Cleaned up test file"
    fi
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "  File Processing Pipeline Verification"
    echo "========================================"
    echo ""

    # Check prerequisites
    check_localstack || exit 1

    # Get SQS Queue URL
    local queue_url=$(get_queue_url)
    if [ -z "$queue_url" ]; then
        log_error "Could not find SQS queue. Make sure Terraform has been applied."
        exit 1
    fi
    log_info "SQS Queue URL: ${queue_url}"

    # Generate unique test file
    local timestamp=$(date +%s)
    local test_file="/tmp/test-file-${timestamp}.bin"
    local s3_key="test-uploads/test-file-${timestamp}.bin"

    # Set trap for cleanup
    trap "cleanup ${test_file}" EXIT

    # Generate test file
    generate_test_file "${test_file}" "${TEST_FILE_SIZE_MB}"

    # Upload to S3
    upload_to_s3 "${test_file}" "${s3_key}"

    # Poll for results
    echo ""
    if poll_sqs "${queue_url}" "${s3_key}"; then
        log_success "Pipeline verification completed successfully!"
        exit 0
    else
        log_error "Pipeline verification failed"
        exit 1
    fi
}

# Run main function
main "$@"
