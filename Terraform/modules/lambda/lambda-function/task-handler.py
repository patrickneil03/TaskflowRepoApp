import json
import boto3
import logging
import os
sqs = boto3.client('sqs')
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
import uuid
from boto3.dynamodb.conditions import Key
from datetime import datetime
from zoneinfo import ZoneInfo

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Todo')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    method = event.get('httpMethod', '')
    resource = event.get('resource', '')
    body = json.loads(event['body']) if event.get('body') else {}
    path_parameters = event.get('pathParameters', {})

    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
        'Content-Type': 'application/json'
    }

    if method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'CORS preflight successful'})
        }

    # Extract userId from the Cognito JWT token
    user_id = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('cognito:username')
    if not user_id:
        return {
            'statusCode': 401,
            'headers': headers,
            'body': json.dumps({'message': 'Unauthorized'})
        }

    # POST /taskhandler - Create a new task (Now routes to SQS)
    if resource == '/taskhandler' and method == 'POST':
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
            
            # 1. Construct the payload exactly as you did before
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

            # 2. INSTEAD OF table.put_item(), push to SQS!
            logger.info(f"Sending task metadata to SQS: {item}")
            sqs.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps(item)
            )

            # 3. Return an instant success code to API Gateway!
            return {
                'statusCode': 202, # 202 Accepted is standard for async operations
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
    elif resource == '/taskhandler' and method == 'GET':
        try:
            response = table.query(
                KeyConditionExpression=Key('userId').eq(user_id)
            )
            tasks = response.get('Items', [])
            
            # Return tasks as-is without sorting to maintain original order
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
    elif resource == '/taskhandler/{id}' and method == 'PUT':
        task_id = path_parameters.get('id')
        task_text = body.get('taskText', '')
        deadline = body.get('deadline', None)  # Optional deadline update

        if not task_id or not task_text:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId and taskText are required'})
            }

        try:
            # Base update operation
            update_expr = 'SET taskText = :val1'
            expr_attrs = {':val1': task_text}
            
            # Handle deadline update/removal
            if deadline is not None:
                if deadline:  # Update deadline
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
                else:  # Remove deadline if empty string is passed
                    update_expr += ' REMOVE deadline'

            table.update_item(
                Key={
                    'userId': user_id,
                    'taskId': task_id
                },
                UpdateExpression=update_expr,
                ExpressionAttributeValues=expr_attrs
            )
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



    # PATCH /taskhandler/{id} - Update deadline and reset notification flag
    elif resource == '/taskhandler/{id}' and method == 'PATCH':
        task_id = path_parameters.get('id')
        deadline = body.get('deadline')
        notificationSent = body.get('notificationSent', False)

        if not task_id or not deadline:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId and deadline are required'})
            }

        try:
            # Validate deadline format
            try:
                datetime.fromisoformat(deadline)
            except ValueError:
                return {
                    'statusCode': 400,
                    'headers': headers,
                    'body': json.dumps({'message': 'Invalid deadline format'})
                }

            table.update_item(
                Key={
                    'userId': user_id,
                    'taskId': task_id
                },
                UpdateExpression='SET deadline = :d, notificationSent = :n',
                ExpressionAttributeValues={
                    ':d': deadline,
                    ':n': notificationSent
                }
            )

            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'Deadline updated successfully'})
            }
        except Exception as e:
            logger.error(f"Error updating deadline: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    # DELETE /taskhandler/{id} - Delete a task
    elif resource == '/taskhandler/{id}' and method == 'DELETE':
        task_id = path_parameters.get('id')
        if not task_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'taskId is required'})
            }

        try:
            table.delete_item(
                Key={
                    'userId': user_id,
                    'taskId': task_id
                }
            )
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'Task deleted successfully'})
            }
        except Exception as e:
            logger.error(f"Error deleting task: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Internal server error: {str(e)}'})
            }

    return {
        'statusCode': 400,
        'headers': headers,
        'body': json.dumps({'message': 'Unsupported method'})
    }