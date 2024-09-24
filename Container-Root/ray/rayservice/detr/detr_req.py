from PIL import Image
import requests
from io import BytesIO

# Load the image from the URL
image_url = "http://images.cocodataset.org/val2017/000000039769.jpg"
image = Image.open(requests.get(image_url, stream=True).raw)

# Convert the image to a file-like object in memory
image_io = BytesIO()
image.save(image_io, format='JPEG')  # You can change the format as needed
image_io.seek(0)  # Go back to the start of the BytesIO object

# Prepare the files dictionary
files = {"image": ("image.jpg", image_io, "image/jpeg")}

# Send the POST request with the image
url = "http://127.0.0.1:8000"
response = requests.post(url, files=files)

# Print the response
print(response.text)
