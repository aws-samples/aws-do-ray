import requests

# TODO: Change this to your image path
image_path = "/aws-do-ray/Container-Root/ray/rayservice/mobilenet/lamborghini.png"


url = "http://127.0.0.1:8000"
files = {"image": open(image_path, "rb")}
response = requests.post(url, files=files)
print(response.text)