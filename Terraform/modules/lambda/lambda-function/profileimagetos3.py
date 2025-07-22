import json
import boto3
import os
from urllib.parse import parse_qs

s3 = boto3.client('s3')
BUCKET = os.environ.get("PROFILE_BUCKET")

def lambda_handler(event, context):
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS, GET, POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }
    
    try:
        http_method = event.get("httpMethod")
        
        if http_method == "POST":
            # Handle both presigned URL generation AND legacy base64 uploads
            path = event.get("path", "")
            if "/generate-presigned-url" in path:
                return handle_generate_presigned_url(event, cors_headers)
            else:
                return handle_legacy_upload(event, cors_headers)
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

def handle_generate_presigned_url(event, headers):
    """Generate presigned URL for direct S3 upload"""
    try:
        # Extract username from Cognito token
        username = event["requestContext"]["authorizer"]["claims"]["cognito:username"]
        
        # Parse request body
        body = json.loads(event.get("body", "{}"))
        file_type = body.get("fileType")
        
        # Validate file type
        if file_type not in ["image/jpeg", "image/png"]:
            return create_response(400, {"error": "Only JPEG/PNG allowed"}, headers)
        
        # Generate S3 key and presigned URL
        key = f"profile-pictures/{username}/avatar.jpg"
        upload_url = s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": BUCKET,
                "Key": key,
                "ContentType": file_type
            },
            ExpiresIn=300  # 5-minute expiry
        )
        
        return create_response(200, {"uploadUrl": upload_url, "key": key}, headers)
        
    except Exception as e:
        print(f"Presigned URL Error: {str(e)}")
        return create_response(500, {"error": "Failed to generate upload URL"}, headers)

def handle_legacy_upload(event, headers):
    """Legacy base64 upload (fallback)"""
    try:
        body = json.loads(event.get("body", "{}"))
        username = body.get("username")
        username_from_token = event["requestContext"]["authorizer"]["claims"]["cognito:username"]
        
        # Validate user
        if username_from_token != username:
            return create_response(403, {"error": "Unauthorized"}, headers)
        
        # Process base64 image
        image_base64 = body.get("image")
        if not image_base64:
            return create_response(400, {"error": "No image data"}, headers)
            
        image_data = base64.b64decode(image_base64)
        key = f"profile-pictures/{username}/avatar.jpg"
        
        # Upload to S3
        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=image_data,
            ContentType="image/jpeg",
            ACL="private"
        )
        
        # Return presigned URL for viewing
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET, "Key": key},
            ExpiresIn=3600
        )
        return create_response(200, {"url": url}, headers)
        
    except Exception as e:
        print(f"Legacy Upload Error: {str(e)}")
        return create_response(500, {"error": "Upload failed"}, headers)


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
