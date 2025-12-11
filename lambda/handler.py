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

# Initialize AWS clients
s3_client = boto3.client(
    's3',
    endpoint_url=os.environ.get('AWS_ENDPOINT_URL'),
)
sqs_client = boto3.client(
    'sqs',
    endpoint_url=os.environ.get('AWS_ENDPOINT_URL'),
)

# Configuration
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
CHUNK_SIZE = 8192  # 8KB chunks for streaming


def calculate_size_by_streaming(bucket: str, key: str) -> int:
    """
    Calculate the size of an S3 object by streaming its content.

    This function downloads the object in chunks to calculate its size,
    demonstrating actual data handling without relying on metadata.

    Args:
        bucket: S3 bucket name
        key: S3 object key

    Returns:
        Size of the object in bytes
    """
    logger.info(f"Streaming object s3://{bucket}/{key} to calculate size")

    total_size = 0

    # Get the object and stream its content
    response = s3_client.get_object(Bucket=bucket, Key=key)
    body = response['Body']

    # Read the object in chunks to avoid loading entire content into memory
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
    """
    Send the processing result to SQS queue.

    Args:
        object_uri: S3 object URI (s3://bucket/key)
        size_mb: Size in megabytes

    Returns:
        SQS send_message response
    """
    message = {
        'object_uri': object_uri,
        'size_mb': size_mb
    }

    logger.info(f"Sending message to SQS: {message}")

    response = sqs_client.send_message(
        QueueUrl=SQS_QUEUE_URL,
        MessageBody=json.dumps(message)
    )

    logger.info(f"Message sent successfully. MessageId: {response['MessageId']}")
    return response


def lambda_handler(event: dict, context) -> dict:
    """
    Lambda handler for S3 object creation events.

    Args:
        event: S3 event notification
        context: Lambda context

    Returns:
        Response with processing results
    """
    logger.info(f"Received event: {json.dumps(event)}")

    results = []

    for record in event.get('Records', []):
        # Extract bucket and key from S3 event
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])

        logger.info(f"Processing object: s3://{bucket}/{key}")

        try:
            # Calculate size by streaming the object content
            size_bytes = calculate_size_by_streaming(bucket, key)
            size_mb = bytes_to_mb(size_bytes)

            # Construct S3 URI
            object_uri = f"s3://{bucket}/{key}"

            # Send result to SQS
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
