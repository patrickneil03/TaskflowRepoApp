import json
import boto3
import logging
import os
import uuid
from boto3.dynamodb.conditions import Key
from datetime import datetime
from zoneinfo import ZoneInfo

sqs = boto3.client('sqs')
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN")

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
# Note: In production, pull this dynamically from OS env: os.environ.get('DYNAMODB_TABLE', 'Todo')
table = dynamodb.Table('Todo')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    request_context = event.get('requestContext', {})
    http_context = request_context.get('http', {})
    
    method = http_context.get('method', '')
    raw_path = event.get('rawPath', '') 
    body = json.loads(event['body']) if event.get('body') else {}
    path_parameters = event.get('pathParameters', {})

    headers = {
        'Content-Type': 'application/json'
    }

    authorizer_claims = request_context.get('authorizer', {}).get('jwt', {}).get('claims', {})
    user_id = authorizer_claims.get('cognito:username') or authorizer_claims.get('sub')
    
    if not user_id:
        return {
            'statusCode': 401,
            'headers': headers,
            'body': json.dumps({'message': 'Unauthorized'})
        }

    # ==========================================
    # 1) GET /taskhandler - Fetch tasks directly (Synchronous)
    # ==========================================
    if raw_path == '/taskhandler' and method == 'GET':
        try:
            response = table.query(
                KeyConditionExpression=Key('userId').eq(user_id)
            )
            tasks = response.get('Items', [])
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps(tasks)
            }
        except Exception as e:
            logger.error(f"Error fetching tasks: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # ==========================================
    # 2) POST /taskhandler - Create task (Queued)
    # ==========================================
    elif raw_path == '/taskhandler' and method == 'POST':
        try:
            task_id = str(uuid.uuid4())
            task_text = body.get('taskText', '')
            deadline = body.get('deadline', None)
            
            if not task_text:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'message': 'taskText is required'})
                }

            local_tz = ZoneInfo("Asia/Manila")
            created_at = datetime.now(local_tz).strftime('%m/%d/%y %H:%M')
            
            # Form SQS Payload with action metadata
            payload = {
                'action': 'CREATE',
                'userId': user_id,
                'taskId': task_id,
                'taskText': task_text,
                'createdAt': created_at
            }
            
            if deadline:
                try:
                    datetime.fromisoformat(deadline)
                    payload['deadline'] = deadline
                except ValueError:
                    return {
                        'statusCode': 400,
                        'headers': headers,
                        'body': json.dumps({'message': 'Invalid deadline format.'})
                    }

            logger.info(f"Queuing CREATE action: {payload}")
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(payload))

            return {
                'statusCode': 202, # 202 Accepted means request is accepted for processing
                'headers': headers,
                'body': json.dumps({
                    'message': 'Task creation queued successfully',
                    'taskId': task_id
                })
            }
        except Exception as e:
            logger.error(f"Error queuing task: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # ==========================================
    # 3) PUT /taskhandler/{id} - Update full details (Queued)
    # ==========================================
    elif '/taskhandler/' in raw_path and method == 'PUT':
        task_id = path_parameters.get('id')
        task_text = body.get('taskText', '')
        deadline = body.get('deadline', None)

        if not task_id or not task_text:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId and taskText are required'})
            }

        try:
            if deadline:
                try:
                    datetime.fromisoformat(deadline)
                except ValueError:
                    return {
                        'statusCode': 400,
                        'headers': headers,
                        'body': json.dumps({'message': 'Invalid deadline format'})
                    }

            payload = {
                'action': 'UPDATE_FULL',
                'userId': user_id,
                'taskId': task_id,
                'taskText': task_text,
                'deadline': deadline # Can be None if removing/not set
            }

            logger.info(f"Queuing UPDATE_FULL action: {payload}")
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(payload))

            return {
                'statusCode': 202,
                'headers': headers,
                'body': json.dumps({'message': 'Task update queued successfully'})
            }
        except Exception as e:
            logger.error(f"Error queuing task update: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # ==========================================
    # 4) PATCH /taskhandler/{id} - Update deadline only (Queued)
    # ==========================================
    elif '/taskhandler/' in raw_path and method == 'PATCH':
        task_id = path_parameters.get('id')
        deadline = body.get('deadline', None)

        if not task_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId is required'})
            }

        try:
            if deadline:
                try:
                    datetime.fromisoformat(deadline)
                except ValueError:
                    return {
                        'statusCode': 400,
                        'headers': headers,
                        'body': json.dumps({'message': 'Invalid deadline format'})
                    }
                
            payload = {
                'action': 'UPDATE_DEADLINE',
                'userId': user_id,
                'taskId': task_id,
                'deadline': deadline # If None, our consumer removes it
            }

            logger.info(f"Queuing UPDATE_DEADLINE action: {payload}")
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(payload))

            return {
                'statusCode': 202,
                'headers': headers,
                'body': json.dumps({'message': 'Deadline update queued successfully'})
            }
        except Exception as e:
            logger.error(f"Error queuing deadline update: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # ==========================================
    # 5) DELETE /taskhandler/{id} - Delete task (Queued)
    # ==========================================
    elif '/taskhandler/' in raw_path and method == 'DELETE':
        task_id = path_parameters.get('id')

        if not task_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId is required'})
            }

        try:
            payload = {
                'action': 'DELETE',
                'userId': user_id,
                'taskId': task_id
            }

            logger.info(f"Queuing DELETE action: {payload}")
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(payload))

            return {
                'statusCode': 202,
                'headers': headers,
                'body': json.dumps({'message': 'Task deletion queued successfully'})
            }
        except Exception as e:
            logger.error(f"Error queuing deletion: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # Fallback route
    return {
        'statusCode': 404,
        'headers': headers,
        'body': json.dumps({'message': 'Route not found'})
    }