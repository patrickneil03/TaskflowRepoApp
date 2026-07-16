import json
import boto3
import os

s3 = boto3.client('s3')
BUCKET = os.environ.get("PROFILE_BUCKET")
ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN")

def lambda_handler(event, context):
    cors_headers = {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN if ALLOWED_ORIGIN else "*",
        "Access-Control-Allow-Methods": "OPTIONS, POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }

    try:
        # 🎯 FIXED: Read HTTP Method safely from HTTP API v2 payload format
        http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
        
        if http_method == "OPTIONS":
            return {
                "statusCode": 200,
                "headers": cors_headers,
                "body": json.dumps({"message": "CORS preflight passed"})
            }

        if http_method == "POST":
            return handle_presigned_upload_url(event, cors_headers)
        else:
            return create_response(405, {"error": "Method not allowed"}, cors_headers)
            
    except Exception as e:
        print(f"Error in handler: {str(e)}")
        return create_response(500, {"error": f"Internal Server Error: {str(e)}"}, cors_headers)

def create_response(status_code, body, headers):
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body)
    }

def handle_presigned_upload_url(event, headers):
    try:
        body = json.loads(event.get("body", "{}"))
        username = body.get("username")

        # 🎯 FIXED: Access authorizer claims safely from HTTP API v2 format (nested under 'jwt')
        authorizer = event.get("requestContext", {}).get("authorizer", {})
        jwt_claims = authorizer.get("jwt", {}).get("claims", {})
        username_from_token = jwt_claims.get("cognito:username")

        # Fallback to older v1 structure just in case of formatting adjustments
        if not username_from_token:
            username_from_token = authorizer.get("claims", {}).get("cognito:username")

        if not username_from_token or username_from_token != username:
            return create_response(403, {"error": "Unauthorized. Username mismatch."}, headers)

        # 🎯 ALIGNED PATH: Matches your CloudFront route pattern precisely
        key = f"profiles/{username}.jpg"
        
        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET,
                'Key': key,
                'ContentType': "image/jpeg"
            },
            ExpiresIn=300  # 5 minutes
        )
        return create_response(200, {"uploadUrl": presigned_url}, headers)
        
    except Exception as e:
        print(f"Presigned Upload URL Error: {str(e)}")
        return create_response(500, {"error": f"Failed to generate upload URL: {str(e)}"}, headers)