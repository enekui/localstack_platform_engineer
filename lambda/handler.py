"""
Lambda handler for processing S3 file uploads.

This function is triggered by S3 object creation events.
It streams the object content to calculate its size (without loading into memory)
and sends the result to an SQS queue.
"""

import json
import logging
import os
from urllib.parse import unquote_plus

import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Determine endpoint URL for LocalStack compatibility
# LocalStack sets LOCALSTACK_HOSTNAME for Lambda functions running in Docker
def get_endpoint_url():
    localstack_host = os.environ.get('LOCALSTACK_HOSTNAME')
    if localstack_host:
        return f"http://{localstack_host}:4566"
    return os.environ.get('AWS_ENDPOINT_URL')

ENDPOINT_URL = get_endpoint_url()

# Initialize AWS clients
s3_client = boto3.client('s3', endpoint_url=ENDPOINT_URL)
sqs_client = boto3.client('sqs', endpoint_url=ENDPOINT_URL)

# Configuration
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
CHUNK_SIZE = 8192  # 8KB chunks for streaming


def calculate_size_by_streaming(bucket: str, key: str) -> int:
    """
    Calculate the size of an S3 object by streaming its content.
    """
    logger.info(f"Streaming object s3://{bucket}/{key} to calculate size")

    total_size = 0
    response = s3_client.get_object(Bucket=bucket, Key=key)
    body = response['Body']

    while True:
        chunk = body.read(CHUNK_SIZE)
        if not chunk:
            break
        total_size += len(chunk)

    body.close()
    logger.info(f"Calculated size: {total_size} bytes")
    return total_size


def bytes_to_mb(size_bytes: int) -> float:
    """Convert bytes to megabytes with 2 decimal places."""
    return round(size_bytes / (1024 * 1024), 2)


def send_to_sqs(object_uri: str, size_mb: float) -> dict:
    """Send the processing result to SQS queue."""
    message = {
        'object_uri': object_uri,
        'size_mb': size_mb
    }

    logger.info(f"Sending message to SQS: {message}")

    # For LocalStack, we need to fix the queue URL to use internal hostname
    queue_url = SQS_QUEUE_URL
    localstack_host = os.environ.get('LOCALSTACK_HOSTNAME')
    if localstack_host and queue_url:
        # Replace external hostname with internal LocalStack hostname
        queue_url = queue_url.replace('localhost.localstack.cloud', localstack_host)
        queue_url = queue_url.replace('localhost', localstack_host)

    logger.info(f"Using SQS Queue URL: {queue_url}")

    response = sqs_client.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message)
    )

    logger.info(f"Message sent successfully. MessageId: {response['MessageId']}")
    return response


def lambda_handler(event: dict, context) -> dict:
    """Lambda handler for S3 object creation events."""
    logger.info(f"Received event: {json.dumps(event)}")
    logger.info(f"Using endpoint: {ENDPOINT_URL}")

    results = []

    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])

        logger.info(f"Processing object: s3://{bucket}/{key}")

        try:
            size_bytes = calculate_size_by_streaming(bucket, key)
            size_mb = bytes_to_mb(size_bytes)
            object_uri = f"s3://{bucket}/{key}"

            send_to_sqs(object_uri, size_mb)

            results.append({
                'object_uri': object_uri,
                'size_mb': size_mb,
                'status': 'success'
            })

        except Exception as e:
            logger.error(f"Error processing s3://{bucket}/{key}: {str(e)}")
            results.append({
                'object_uri': f"s3://{bucket}/{key}",
                'error': str(e),
                'status': 'error'
            })

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Processing complete',
            'results': results
        })
    }
