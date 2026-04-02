import urllib.request
import urllib.parse
import json

url = "http://aakashsms.com/admin/public/sms/v3/send/"
data = {
    "auth_token": "aakash_dummy_token",
    "to": "9863590097",
    "text": "Your Khozna OTP code is: 123456. Do not share this with anyone."
}
data_encoded = urllib.parse.urlencode(data).encode('utf-8')
headers = {
    "Content-Type": "application/x-www-form-urlencoded"
}

req = urllib.request.Request(url, data=data_encoded, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.getcode()}")
        print(f"Content-Type: {response.headers.get('Content-Type')}")
        print(f"Response Body: {response.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"Status Code: {e.code}")
    print(f"Content-Type: {e.headers.get('Content-Type')}")
    print(f"Response Body: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
