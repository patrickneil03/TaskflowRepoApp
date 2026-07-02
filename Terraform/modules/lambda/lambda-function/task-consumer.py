import json
import boto3
import logging
import os

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'Todo')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    logger.info(f"Received SQS event batch: {json.dumps(event)}")

    # This list will keep track of any individual messages that fail processing
    batch_item_failures = []
    success_count = 0

    for record in event.get('Records', []):
        message_id = record.get('messageId')
        try:
            # SQS stores your payload string inside the 'body' attribute
            task_item = json.loads(record['body'])
            
            logger.info(f"Consumer writing task to DynamoDB. User: {task_item.get('userId')}, Task: {task_item.get('taskId')}")
            
            # Save directly into your table using the payload constructed by the producer
            table.put_item(Item=task_item)
            success_count += 1

        except Exception as e:
            logger.error(f"Failed to process SQS record {message_id}. Error: {str(e)}")
            # Append the failed message ID using the exact structural key expected by AWS
            batch_item_failures.append({"itemIdentifier": message_id})

    logger.info(f"Batch processing complete. Successes: {success_count}, Failures: {len(batch_item_failures)}")
    
    # Returning this exact schema allows SQS to know exactly which records to retry
    return {
        "batchItemFailures": batch_item_failures
    }