import base64
import io
import os

import ollama
from PIL import Image

# pdf_path = os.path.join(os.path.dirname(__file__), "testdata/page_10.png")

# response = ollama.chat(
#     model="llama3.2-vision",
#     messages=[
#         {
#             "role": "user",
#             "content": "What is in this image?",
#             "images": [pdf_path],
#         }
#     ],
# )

# print(response)


def image_to_base64(image_path):
    # Open the image file
    with Image.open(image_path) as img:
        # Create a BytesIO object to hold the image data
        buffered = io.BytesIO()
        # Save the image to the BytesIO object in a specific format (e.g., JPEG)
        img.save(buffered, format="PNG")
        # Get the byte data from the BytesIO object
        img_bytes = buffered.getvalue()
        # Encode the byte data to base64
        img_base64 = base64.b64encode(img_bytes).decode("utf-8")
        return img_base64


# Example usage
image_path = os.path.join(os.path.dirname(__file__), "testdata/page_10.png")
base64_image = image_to_base64(image_path)
import ollama

systemPrompt = """
Convert the provided image into Markdown format. Ensure that all content from the page is included, such as headers, footers, subtexts, images (with alt text if possible), tables, and any other elements.

  Requirements:

  - Output Only Markdown: Return solely the Markdown content without any additional explanations or comments.
  - No Delimiters: Do not use code fences or delimiters like \`\`\`markdown.
  - Complete Content: Do not omit any part of the page, including headers, footers, and subtext.
# Use Ollama to clean and structure the OCR output
"""

response = ollama.chat(
    model="llama3.2-vision",
    messages=[
        {
            "role": "user",
            "content": systemPrompt,
            "images": [base64_image],
        },
    ],
)
# Extract cleaned text
cleaned_text = response["message"]["content"].strip()
print(cleaned_text)
