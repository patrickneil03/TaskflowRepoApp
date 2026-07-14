import json
import boto3
import os
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import logging

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')
table = dynamodb.Table(os.getenv('DYNAMODB_TABLE', 'Todo'))
QUEUE_URL = os.getenv('SQS_QUEUE_URL')

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_tasks_nearing_deadline():
    """Query DynamoDB GSI for pending tasks with deadlines in the next 25 hours (UTC)"""
    now = datetime.now(ZoneInfo("UTC"))
    deadline_cutoff = now + timedelta(hours=25)

    query_kwargs = {
        'IndexName': 'DeadlineIndex',
        'KeyConditionExpression': 'taskStatus = :status AND deadline BETWEEN :now AND :future',
        'ExpressionAttributeValues': {
            ':status': 'PENDING',
            ':now': now.isoformat().replace('+00:00', 'Z'),
            ':future': deadline_cutoff.isoformat().replace('+00:00', 'Z')
        }
    }

    tasks = []
    start_key = None

    while True:
        if start_key:
            query_kwargs['ExclusiveStartKey'] = start_key

        response = table.query(**query_kwargs)
        tasks.extend(response.get('Items', []))

        start_key = response.get('LastEvaluatedKey', None)
        if not start_key:
            break

    return tasks

def lambda_handler(event, context):
    try:
        tasks = get_tasks_nearing_deadline()
        total_tasks = len(tasks)
        logger.info(f"Sweeper found {total_tasks} tasks nearing deadline.")

        if total_tasks == 0:
            return {'statusCode': 200, 'body': 'No tasks to queue.'}

        # Send tasks to SQS in batches of 10 (SQS limit for batch operations)
        batch_entries = []
        for index, task in enumerate(tasks):
            # Construct a lightweight payload
            payload = {
                'userId': task['userId'],
                'taskId': task['taskId'],
                'taskText': task['taskText'],
                'deadline': task['deadline']
            }

            batch_entries.append({
                'Id': str(index), # Unique identifier for messages within this batch
                'MessageBody': json.dumps(payload)
            })

            # When we hit 10 records, or the end of the list, send the batch
            if len(batch_entries) == 10 or index == total_tasks - 1:
                sqs.send_message_batch(
                    QueueUrl=QUEUE_URL,
                    Entries=batch_entries
                )
                batch_entries = [] # Reset batch

        logger.info(f"Successfully queued {total_tasks} tasks to SQS.")
        return {
            'statusCode': 200,
            'body': f"Successfully queued {total_tasks} tasks."
        }

    except Exception as e:
        logger.error(f"Fatal Sweeper error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': 'Internal Sweeper Error'
        }