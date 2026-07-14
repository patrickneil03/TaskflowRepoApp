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

def normalize_deadline(deadline):
    """
    Ensures deadline timestamps are always in strict UTC ISO-8601 format (YYYY-MM-DDTHH:MM:SSZ)
    to prevent lexicographical sort mismatches during GSI queries.
    """
    if not deadline:
        return None
        
    # Trim leading/trailing whitespaces
    deadline = deadline.strip()
    
    # If the format lacks seconds and a trailing Z (e.g., YYYY-MM-DDTHH:MM)
    if not deadline.endswith('Z') and '+' not in deadline and '-' not in deadline[10:]:
        if len(deadline) == 16:  # Matches 'YYYY-MM-DDTHH:MM'
            return f"{deadline}:00Z"
        elif len(deadline) == 19:  # Matches 'YYYY-MM-DDTHH:MM:SS'
            return f"{deadline}Z"
            
    return deadline

def lambda_handler(event, context):
    logger.info(f"Received SQS event batch: {json.dumps(event)}")

    batch_item_failures = []
    success_count = 0

    for record in event.get('Records', []):
        message_id = record.get('messageId')
        try:
            payload = json.loads(record['body'])
            action = payload.get('action')
            user_id = payload.get('userId')
            task_id = payload.get('taskId')
            
            # Validate core keys
            if not user_id or not task_id:
                raise ValueError("Missing partition key userId or sort key taskId in message payload")

            # Handle Actions
            if action == 'CREATE':
                task_item = {
                    'userId': user_id,
                    'taskId': task_id,
                    'taskText': payload.get('taskText'),
                    'createdAt': payload.get('createdAt')
                }
                # Normalize deadline before saving 💡
                raw_deadline = payload.get('deadline')
                if raw_deadline:
                    task_item['deadline'] = normalize_deadline(raw_deadline)
                    task_item['taskStatus'] = 'PENDING' # Setup GSI for deadline sweeps
                
                table.put_item(Item=task_item)
                logger.info(f"Successfully executed CREATE for task: {task_id}")

            elif action == 'UPDATE_FULL':
                # Update task details + conditionally handle GSI field injection/removal
                update_expr = 'SET taskText = :text'
                expr_attrs = {':text': payload.get('taskText')}
                
                # Normalize deadline before saving 💡
                deadline = normalize_deadline(payload.get('deadline'))
                if deadline:
                    update_expr += ', deadline = :dl, taskStatus = :status'
                    expr_attrs[':dl'] = deadline
                    expr_attrs[':status'] = 'PENDING'
                else:
                    # If updating details and no deadline exists (or was cleared), drop GSI tracking
                    update_expr += ' REMOVE deadline, taskStatus'

                table.update_item(
                    Key={'userId': user_id, 'taskId': task_id},
                    UpdateExpression=update_expr,
                    ExpressionAttributeValues=expr_attrs if ':dl' in update_expr or ':text' in update_expr else None
                )
                logger.info(f"Successfully executed UPDATE_FULL for task: {task_id}")

            elif action == 'UPDATE_DEADLINE':
                # Normalize deadline before saving 💡
                deadline = normalize_deadline(payload.get('deadline'))
                if deadline:
                    table.update_item(
                        Key={'userId': user_id, 'taskId': task_id},
                        UpdateExpression='SET deadline = :dl, taskStatus = :status',
                        ExpressionAttributeValues={':dl': deadline, ':status': 'PENDING'}
                    )
                else:
                    table.update_item(
                        Key={'userId': user_id, 'taskId': task_id},
                        UpdateExpression='REMOVE deadline, taskStatus'
                    )
                logger.info(f"Successfully executed UPDATE_DEADLINE for task: {task_id}")

            elif action == 'DELETE':
                table.delete_item(
                    Key={'userId': user_id, 'taskId': task_id}
                )
                logger.info(f"Successfully executed DELETE for task: {task_id}")

            else:
                logger.warning(f"Unknown action: {action}. Skipping record.")

            success_count += 1

        except Exception as e:
            logger.error(f"Failed to process SQS record {message_id}. Error: {str(e)}")
            batch_item_failures.append({"itemIdentifier": message_id})

    logger.info(f"Batch processing complete. Successes: {success_count}, Failures: {len(batch_item_failures)}")
    return {
        "batchItemFailures": batch_item_failures
    }