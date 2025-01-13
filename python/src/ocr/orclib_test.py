#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

from .ocrlib import OcrByOnnx


def test_ocr():
    ocr = OcrByOnnx()

    with open(
        os.path.join(os.path.dirname(__file__), "testdata/image5.png"), "rb"
    ) as f:
        img_bytes = f.read()

        # 识别图片中的文字
        res = ocr.classification(img_bytes)
        print(res)
        # s = ""
        # for i in res["probability"]:
        #     s += res["charsets"][i.index(max(i))]

        # print(s)
