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
        deadline = datetime.fromisoformat(task['deadline']).replace(tzinfo=timezone)
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
                            f"Deadline: {deadline.astimezone(timezone).strftime('%b %d, %Y at %I:%M %p')}\n"
                            f"Task ID: {task['taskId']}"
                        )
                    },
                    'Html': {
                        'Data': f"""<html>
                            <body>
                                <h2>Task Deadline Alert</h2>
                                <p><b>Task:</b> {task['taskText']}</p>
                                <p><b>Due in:</b> {max(0, hours_left):.1f} hours</p>
                                <p><b>Deadline:</b> {deadline.astimezone(timezone).strftime('%b %d, %Y at %I:%M %p')}</p>
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

def get_tasks_nearing_deadline():
    """Scan DynamoDB table for tasks with deadlines in the next 24 hours"""
    now = datetime.now(ZoneInfo(os.getenv('TIMEZONE', 'Asia/Manila')))
    deadline_cutoff = now + timedelta(hours=24)

    scan_kwargs = {
        'FilterExpression': (
            'deadline BETWEEN :now AND :future AND '
            '(attribute_not_exists(notificationSent) OR notificationSent = :false)'
        ),
        'ExpressionAttributeValues': {
            ':now': now.isoformat(),
            ':future': deadline_cutoff.isoformat(),
            ':false': False
        }
    }

    tasks = []
    start_key = None

    while True:
        if start_key:
            scan_kwargs['ExclusiveStartKey'] = start_key

        response = table.scan(**scan_kwargs)
        tasks.extend(response.get('Items', []))

        start_key = response.get('LastEvaluatedKey', None)
        if not start_key:
            break

    return tasks


def lambda_handler(event, context):
    try:
        tasks = get_tasks_nearing_deadline()
        logger.info(f"Processing {len(tasks)} tasks")
        
        results = {'success': 0, 'failed': 0, 'skipped': 0}
        for task in tasks:
            try:
                email = get_user_email(task['userId'])
                if not email:
                    results['skipped'] += 1
                    continue
                
                if send_ses_notification(task, email):
                    table.update_item(
                        Key={'userId': task['userId'], 'taskId': task['taskId']},
                        UpdateExpression='SET notificationSent = :true',
                        ExpressionAttributeValues={':true': True}
                    )
                    results['success'] += 1
                else:
                    results['failed'] += 1
                    
            except Exception as e:
                logger.error(f"Failed processing task {task.get('taskId')}: {str(e)}")
                results['failed'] += 1

        logger.info(f"Completed: {json.dumps(results)}")
        return {
            'statusCode': 200,
            'body': results
        }
        
    except Exception as e:
        logger.error(f"Fatal error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': {'error': 'Internal server error'}
        }