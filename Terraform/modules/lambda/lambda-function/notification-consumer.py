import json
import boto3
import os
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import logging
from botocore.exceptions import ClientError

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses')
cognito = boto3.client('cognito-idp')
table = dynamodb.Table(os.getenv('DYNAMODB_TABLE', 'Todo'))

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_user_email(user_id):
    """Fetch verified email from Cognito User Pool"""
    try:
        response = cognito.admin_get_user(
            UserPoolId=os.getenv('COGNITO_USER_POOL_ID'),
            Username=user_id
        )
        return next(
            (attr['Value'] for attr in response['UserAttributes'] 
             if attr['Name'] == 'email'),
            None
        )
    except cognito.exceptions.UserNotFoundException:
        logger.warning(f"User {user_id} not found in Cognito")
        return None
    except ClientError as e:
        logger.error(f"Cognito API error for {user_id}: {e.response['Error']['Message']}")
        return None

def send_ses_notification(task, recipient_email):
    """Send deadline alert via SES"""
    try:
        timezone = ZoneInfo(os.getenv('TIMEZONE', 'Asia/Manila'))
        # Parse UTC ISO string from frontend (ending in 'Z')
        deadline = datetime.fromisoformat(task['deadline'].replace('Z', '+00:00')).astimezone(timezone)
        hours_left = (deadline - datetime.now(timezone)).total_seconds() / 3600
        
        if hours_left <= 0:
            logger.info(f"Skipping expired task {task['taskId']}")
            return False

        response = ses.send_email(
            Source=os.getenv('SES_SENDER_EMAIL'),
            Destination={'ToAddresses': [recipient_email]},
            Message={
                'Subject': {'Data': f"⏰ Deadline: {task['taskText']}"},
                'Body': {
                    'Text': {
                        'Data': (
                            f"Task: {task['taskText']}\n"
                            f"Due in: {max(0, hours_left):.1f} hours\n"
                            f"Deadline: {deadline.strftime('%b %d, %Y at %I:%M %p')}\n"
                            f"Task ID: {task['taskId']}"
                        )
                    },
                    'Html': {
                        'Data': f"""<html>
                            <body>
                                <h2>Task Deadline Alert</h2>
                                <p><b>Task:</b> {task['taskText']}</p>
                                <p><b>Due in:</b> {max(0, hours_left):.1f} hours</p>
                                <p><b>Deadline:</b> {deadline.strftime('%b %d, %Y at %I:%M %p')}</p>
                                <p><small>Task ID: {task['taskId']}</small></p>
                            </body>
                        </html>"""
                    }
                }
            }
        )
        logger.info(f"Sent email to {recipient_email}, SES MessageID: {response['MessageId']}")
        return True
    except ses.exceptions.MessageRejected as e:
        logger.error(f"SES rejected email to {recipient_email}: {str(e)}")
        return False
    except ClientError as e:
        logger.error(f"SES API error: {e.response['Error']['Message']}")
        return False

def lambda_handler(event, context):
    logger.info(f"Processing SQS batch: {len(event.get('Records', []))} items.")
    
    batch_item_failures = []
    success_count = 0
    
    # ⚡ OPTIMIZATION: Cache emails during this execution batch
    email_cache = {}

    for record in event.get('Records', []):
        message_id = record.get('messageId')
        try:
            task = json.loads(record['body'])
            user_id = task['userId']
            
            # Use local cache to skip redundant Cognito API calls
            if user_id not in email_cache:
                email_cache[user_id] = get_user_email(user_id)
                
            email = email_cache[user_id]
            if not email:
                logger.warning(f"Skipping task {task['taskId']} - No email found for user {user_id}")
                continue

            # Send email
            if send_ses_notification(task, email):
                # 🔄 Remove taskStatus to drop it from GSI, and flag notificationSent
                table.update_item(
                    Key={'userId': task['userId'], 'taskId': task['taskId']},
                    UpdateExpression='SET notificationSent = :true REMOVE taskStatus',
                    ExpressionAttributeValues={':true': True}
                )
                success_count += 1
            else:
                # If SES fails, report it to allow SQS retry
                batch_item_failures.append({"itemIdentifier": message_id})

        except Exception as e:
            logger.error(f"Failed to process record {message_id}. Error: {str(e)}")
            batch_item_failures.append({"itemIdentifier": message_id})

    logger.info(f"Batch completed. Success: {success_count}, Failures: {len(batch_item_failures)}")
    return {
        "batchItemFailures": batch_item_failures
    }