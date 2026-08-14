#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

import ddddocr

from .ocrlib import OcrByOnnx


def test_OcrByOnnx():
    ocr = OcrByOnnx()

    with open(
        os.path.join(os.path.dirname(__file__), "../ocr/testdata/WechatIMG401.jpg"),
        "rb",
    ) as f:
        img_bytes = f.read()

    # 识别图片中的文字
    res = ocr.classification(img_bytes)

    print(res)


def test_dddl():
    det = ddddocr.DdddOcr(show_ad=False, det=False, ocr=False)

    with open("target.png", "rb") as f:
        target_bytes = f.read()

    with open("background.png", "rb") as f:
        background_bytes = f.read()

    res = det.slide_match(target_bytes, background_bytes, simple_target=True)

    print(res)
