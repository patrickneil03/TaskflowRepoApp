import json
import urllib.parse
import urllib.request
import os


COGNITO_DOMAIN_ENV = os.environ.get("CUSTOM_COGNITO_DOMAIN", "").strip()
COGNITO_DOMAIN = COGNITO_DOMAIN_ENV.replace("https://", "").replace("http://", "")

CLIENT_ID = os.environ.get("CLIENT_ID")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")

def lambda_handler(event, context):
    # Safety Check: Exit early if configuration variables are missing in AWS Console
    if not COGNITO_DOMAIN:
        print("CRITICAL ERROR: CUSTOM_COGNITO_DOMAIN environment variable is missing.")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Backend configuration error: Missing CUSTOM_COGNITO_DOMAIN."})
        }

    try:
        body = json.loads(event["body"])
        code = body["code"]

        # ✅ FIXED: Correctly structures your dedicated token exchange URL
        token_url = f"https://{COGNITO_DOMAIN}/oauth2/token"
        
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        data = {
            "grant_type": "authorization_code",
            "client_id": CLIENT_ID,
            "redirect_uri": "https://baylenwebsite.xyz/dashboard.html",
            "code": code,
        }

        # ✅ FIXED: Only includes the client_secret parameter if it actually exists 
        if CLIENT_SECRET:
            data["client_secret"] = CLIENT_SECRET

        data_encoded = urllib.parse.urlencode(data).encode("utf-8")
        request = urllib.request.Request(token_url, data=data_encoded, headers=headers)
        
        response = urllib.request.urlopen(request)
        response_data = json.loads(response.read().decode("utf-8"))

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps(response_data),
        }

    except Exception as e:
        # Prints runtime crash traces explicitly to AWS CloudWatch Logs for debugging
        print(f"Token Exchange Failure Exception: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)}),
        }