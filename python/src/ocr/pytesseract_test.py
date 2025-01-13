import os

import cv2
import pytesseract
from PIL import Image


def test_pytesseract():
    image = cv2.imread(
        os.path.join(os.path.dirname(__file__), "testdata/WechatIMG401.jpg")
    )
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    _, thresh_image = cv2.threshold(gray_image, 127, 255, cv2.THRESH_BINARY_INV)
    # 使用Tesseract进行识别
    text = pytesseract.image_to_string(thresh_image, config="--psm 6")
    print(f"识别结果: {text}")
