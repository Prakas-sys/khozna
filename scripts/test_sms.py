import urllib.request
import json

url = "https://qjpeablwokiuhfaopdbi.supabase.co/functions/v1/send-sms"
payload = {
    "phone": "+9779801234567",
    "metadata": {
        "otp": "123456"
    }
}
headers = {
    "Content-Type": "application/json"
}

req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.getcode()}")
        print(f"Response Body: {response.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"Status Code: {e.code}")
    print(f"Response Body: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
