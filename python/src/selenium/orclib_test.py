#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

from ocrlib import OcrByOnnx

def test():
    ocr = OcrByOnnx()

    # 获取当前文件目录
    current_path = os.path.dirname(__file__)

    with open(os.path.join(os.path.dirname(__file__), 'testdata/p1.png'), 'rb') as f:
        img_bytes = f.read()

    # 识别图片中的文字
    res = ocr.classification(img_bytes)

    print(res)
