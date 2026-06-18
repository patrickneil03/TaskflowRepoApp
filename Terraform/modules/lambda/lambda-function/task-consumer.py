import json
import boto3
import logging
import os

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
# Use an environment variable for flexibility, defaulting to 'Todo'
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'Todo')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    logger.info(f"Received SQS event batch: {json.dumps(event)}")

    success_count = 0
    fail_count = 0

    # SQS events always deliver batches wrapped inside a 'Records' list
    for record in event.get('Records', []):
        try:
            # SQS stores your payload string inside the 'body' attribute
            task_item = json.loads(record['body'])
            
            logger.info(f"Consumer writing task to DynamoDB. User: {task_item.get('userId')}, Task: {task_item.get('taskId')}")
            
            # Save directly into your table using the payload constructed by the producer
            table.put_item(Item=task_item)
            success_count += 1

        except Exception as e:
            logger.error(f"Failed to process individual SQS record. Error: {str(e)}")
            fail_count += 1
            # Note: Letting an exception bubble up inside the loop allows you 
            # to log it, but we catch it here so one bad message doesn't ruin the whole batch.

    logger.info(f"Batch processing complete. Successes: {success_count}, Failures: {fail_count}")
    
    return {
        'processedRecords': success_count,
        'failedRecords': fail_count
    }