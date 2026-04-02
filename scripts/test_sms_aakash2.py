import urllib.request
import urllib.parse
import json

url = "https://sms.aakashsms.com/sms/v3/send/"
data = {
    "auth_token": "4823710a171f9794f32fe5568f795407bcf46492bf5d2b14533f0ab9a0573b3e",
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
        r = response.read().decode('utf-8')
        print(f"Status Code: {response.getcode()}")
        print(f"Response Body: {r}")
except urllib.error.HTTPError as e:
    print(f"Status Code: {e.code}")
    print(f"Response Body: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
