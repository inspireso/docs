import os

import easyocr
import numpy as np
from PIL import Image


def test_easyocr():
    image_path = os.path.join(os.path.dirname(__file__), "testdata/p2.png")
    # 创建一个 Reader 对象，指定要识别的语言
    reader = easyocr.Reader(
        lang_list=["en"],  # 'en' 表示英文，可以根据需要添加其他语言
    )

    # 使用 PIL 加载图片
    image = Image.open(image_path).convert("L")  # 转换为灰度图
    image = image.point(lambda x: 0 if x < 150 else 255, "1")  # 二值化处理
    image_np = np.array(image)  # 转换为 numpy 数组
    # 读取图片并进行 OCR 识别
    results = reader.readtext(image_path)

    # 打印出识别结果
    for bbox, text, prob in results:
        print(f"Detected text: {text} with probability: {prob:.2f}")
