import json
import urllib.parse
import urllib.request
import os

# Use your correct Cognito domain
COGNITO_DOMAIN = "https://zeref-todolist-auth.auth.ap-southeast-1.amazoncognito.com"
CLIENT_ID = os.environ.get("CLIENT_ID")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")

def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])
        code = body["code"]

        token_url = f"{COGNITO_DOMAIN}/oauth2/token"
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        data = {
            "grant_type": "authorization_code",
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "redirect_uri": "http://localhost:8000/dashboard.html",
            "code": code,
        }

        data_encoded = urllib.parse.urlencode(data).encode("utf-8")
        request = urllib.request.Request(token_url, data=data_encoded, headers=headers)
        response = urllib.request.urlopen(request)
        response_data = json.loads(response.read().decode("utf-8"))

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(response_data),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)}),
        }
