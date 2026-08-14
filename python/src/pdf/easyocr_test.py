import os

import easyocr

# 创建 OCR 识别器
reader = easyocr.Reader(["ch", "en"])  # 支持中文和英文

# 读取并识别图像
image_path = os.path.join(os.path.dirname(__file__), "testdata/page_1.png")
result = reader.readtext(image_path)

# 打印识别结果
for bbox, text, confidence in result:
    print(f"Detected text: {text} (Confidence: {confidence})")
