import os
import re

import pandas as pd
import pytesseract
from PIL import Image

pattern = r"(\d{4}-\d{2}-\d{2})\s+([A-Za-z\s]+)\s+([\d,]+\.\d{2})"


def test_pytesseract():
    image_path = os.path.join(os.path.dirname(__file__), "testdata/page_1.png")
    image = Image.open(image_path)

    # 使用 OCR 提取文本
    text = pytesseract.image_to_string(image, lang="chi_sim")
    # 按照 \n 分割文本
    lines = text.split("\n")
    for line in lines:
        print(line)

    # 使用正则表达式解析银行流水的日期、描述和金额
    # 假设每行格式类似于：2023-01-01 Description 1000.00

    # matches = re.findall(pattern, text)

    # # 处理提取的匹配结果
    # data = []
    # for match in matches:
    #     date, description, amount = match
    #     amount = amount.replace(",", "")  # 去除金额中的逗号
    #     data.append([date, description.strip(), float(amount)])

    # print(data)
