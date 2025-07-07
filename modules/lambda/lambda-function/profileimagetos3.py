import json
import boto3
import base64
import os

s3 = boto3.client('s3')
BUCKET = os.environ.get("PROFILE_BUCKET")

def lambda_handler(event, context):
    # Common headers for CORS
  
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS, GET, POST",
        "Access-Control-Allow-Headers": "Content-Type"
    }
    
    try:
        http_method = event.get("httpMethod", "GET")
        
        if http_method == "POST":
            return handle_upload(event, cors_headers)
        elif http_method == "GET":
            return handle_get_presigned_url(event, cors_headers)
        else:
            return create_response(405, {"error": "Method not allowed"}, cors_headers)
            
    except Exception as e:
        print(f"Unhandled Error: {str(e)}")
        return create_response(500, {"error": "Internal server error"}, cors_headers)

def create_response(status_code, body, headers):
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body, default=str)
    }

def handle_upload(event, headers):
    try:
        raw_body = event.get("body")
        print("Received raw body:", raw_body)
        body = json.loads(event.get("body", "{}"))
        username = body.get("username")
        image_base64 = body.get("image")
        print("Parsed username:", username, "Parsed image snippet:", image_base64[:30] if image_base64 else None)
        
        # Validate input
        if not username or not image_base64:
            return create_response(400, {"error": "Missing required parameters"}, headers)
            
        # Validate base64 data
        try:
            image_data = base64.b64decode(image_base64)
        except base64.binascii.Error:
            return create_response(400, {"error": "Invalid base64 encoding"}, headers)
            
        key = f"profile-pictures/{username}/avatar.jpg"
        
        # Upload to S3 with proper error handling
        try:
            s3.put_object(
                Bucket=BUCKET,
                Key=key,
                Body=image_data,
                ContentType="image/jpeg",
                ACL="private"
            )
        except s3.exceptions.ClientError as e:
            print(f"S3 Upload Error: {str(e)}")
            return create_response(500, {"error": "Failed to upload image"}, headers)
            
        # Generate presigned URL for immediate access
        try:
            url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": BUCKET, "Key": key},
                ExpiresIn=3600
            )
            return create_response(200, {"url": url}, headers)
        except s3.exceptions.ClientError as e:
            print(f"URL Generation Error: {str(e)}")
            return create_response(500, {"error": "Failed to generate access URL"}, headers)

    except json.JSONDecodeError:
        return create_response(400, {"error": "Invalid JSON format"}, headers)
    except Exception as e:
        print(f"Upload Processing Error: {str(e)}")
        return create_response(500, {"error": "Internal server error"}, headers)

def handle_get_presigned_url(event, headers):
    try:
        query_params = event.get("queryStringParameters", {})
        username = query_params.get("username")
        
        if not username:
            return create_response(400, {"error": "Username parameter is required"}, headers)
            
        key = f"profile-pictures/{username}/avatar.jpg"
        
        # Check object existence with error handling
        try:
            s3.head_object(Bucket=BUCKET, Key=key)
        except s3.exceptions.ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code in ("404", "NoSuchKey", "NotFound", "403", "AccessDenied"):
                # Return a 200 with the default image URL so the client doesn't get an error
                return create_response(200, {"url": "default-profile.png"}, headers)
            print(f"S3 Head Error ({error_code}): {str(e)}")
            return create_response(500, {"error": "Failed to verify image existence"}, headers)
            
        # Generate presigned URL with error handling
        try:
            url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": BUCKET, "Key": key},
                ExpiresIn=3600
            )
            return create_response(200, {"url": url}, headers)
        except s3.exceptions.ClientError as e:
            print(f"Presigned URL Error: {str(e)}")
            return create_response(500, {"error": "Failed to generate access URL"}, headers)

    except Exception as e:
        print(f"URL Handling Error: {str(e)}")
        return create_response(500, {"error": "Internal server error"}, headers)
