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
table = dynamodb.Table('Todo')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    # 🎯 HTTP API v2.0 payload format mappings parse fields clean and lowercase
    request_context = event.get('requestContext', {})
    http_context = request_context.get('http', {})
    
    method = http_context.get('method', '')
    # Payload v2 passes path string straight through raw parameter keys
    raw_path = event.get('rawPath', '') 
    body = json.loads(event['body']) if event.get('body') else {}
    path_parameters = event.get('pathParameters', {})

    # 🎯 NOTICE: Standard headers can be completely clean of manual OPTIONS preflights!
    headers = {
        'Content-Type': 'application/json'
    }

    # 🎯 UPDATED identity claim parsing matching the API Gateway v2 key structure
    authorizer_claims = request_context.get('authorizer', {}).get('jwt', {}).get('claims', {})
    user_id = authorizer_claims.get('cognito:username') or authorizer_claims.get('sub')
    
    if not user_id:
        return {
            'statusCode': 401,
            'headers': headers,
            'body': json.dumps({'message': 'Unauthorized'})
        }

    # Determine route based on rawPath signatures matching your endpoint routes
    # POST /taskhandler - Create a new task
    if raw_path == '/taskhandler' and method == 'POST':
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
            
            item = {
                'userId': user_id,
                'taskId': task_id,
                'taskText': task_text,
                'createdAt': created_at
            }
            
            if deadline:
                try:
                    datetime.fromisoformat(deadline)
                    item['deadline'] = deadline
                except ValueError:
                    return {
                        'statusCode': 400,
                        'headers': headers,
                        'body': json.dumps({'message': 'Invalid deadline format.'})
                    }

            logger.info(f"Sending task metadata to SQS: {item}")
            sqs.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps(item)
            )

            return {
                'statusCode': 202,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Task submitted to queue successfully',
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

    # GET /taskhandler - Fetch tasks for the user
    elif raw_path == '/taskhandler' and method == 'GET':
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

    # PUT /taskhandler/{id} - Update an existing task
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
            update_expr = 'SET taskText = :val1'
            expr_attrs = {':val1': task_text}
            
            if deadline is not None:
                if deadline:
                    try:
                        datetime.fromisoformat(deadline)
                        update_expr += ', deadline = :val2'
                        expr_attrs[':val2'] = deadline
                    except ValueError:
                        return {
                            'statusCode': 400,
                            'headers': headers,
                            'body': json.dumps({'message': 'Invalid deadline format'})
                        }
            
            # (Your continuing database update processing execution goes below...)
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'Task updated successfully'})
            }
        except Exception as e:
            logger.error(f"Error updating task: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    return {
        'statusCode': 404,
        'headers': headers,
        'body': json.dumps({'message': 'Route not found'})
    }