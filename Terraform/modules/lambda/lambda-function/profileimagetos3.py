import json
import boto3
import os

s3 = boto3.client('s3')
BUCKET = os.environ.get("PROFILE_BUCKET")

def lambda_handler(event, context):
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS, GET, POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }

    try:
        http_method = event.get("httpMethod", "GET")
        if http_method == "OPTIONS":
            return {
                "statusCode": 200,
                "headers": cors_headers,
                "body": json.dumps({"message": "CORS preflight passed"})
            }

        if http_method == "POST":
            return handle_presigned_upload_url(event, cors_headers)
        elif http_method == "GET":
            return handle_get_presigned_url(event, cors_headers)
        else:
            return create_response(405, {"error": "Method not allowed"}, cors_headers)
    except Exception as e:
        print(f"Error: {str(e)}")
        return create_response(500, {"error": "Internal Server Error"}, cors_headers)

def create_response(status_code, body, headers):
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body)
    }

def handle_presigned_upload_url(event, headers):
    try:
        body = json.loads(event.get("body", "{}"))
        username_from_token = event["requestContext"]["authorizer"]["claims"]["cognito:username"]
        username = body.get("username")

        if username_from_token != username:
            return create_response(403, {"error": "Unauthorized. Username mismatch."}, headers)

        key = f"profile-pictures/{username}/avatar.jpg"
        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET,
                'Key': key,
                'ContentType': "image/jpeg",
                'ACL': "private"
            },
            ExpiresIn=300  # 5 minutes
        )
        return create_response(200, {"uploadUrl": presigned_url}, headers)
    except Exception as e:
        print(f"Presigned Upload URL Error: {str(e)}")
        return create_response(500, {"error": "Failed to generate upload URL"}, headers)

def handle_get_presigned_url(event, headers):
    try:
        query_params = event.get("queryStringParameters", {})
        username = query_params.get("username")

        if not username:
            return create_response(400, {"error": "Username is required"}, headers)

        key = f"profile-pictures/{username}/avatar.jpg"

        try:
            s3.head_object(Bucket=BUCKET, Key=key)
        except s3.exceptions.ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code in ("404", "NoSuchKey", "NotFound", "403", "AccessDenied"):
                return create_response(200, {"url": "default-profile.png"}, headers)
            raise

        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET, 'Key': key},
            ExpiresIn=3600
        )
        return create_response(200, {"url": url}, headers)
    except Exception as e:
        print(f"Presigned GET URL Error: {str(e)}")
        return create_response(500, {"error": "Failed to generate get URL"}, headers)
