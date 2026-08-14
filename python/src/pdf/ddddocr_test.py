#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

import ddddocr

ocr = ddddocr.DdddOcr(ocr=True, det=False, show_ad=False)


def test1():
    with open(
        os.path.join(os.path.dirname(__file__), "testdata/page_1.png"), "rb"
    ) as f:
        img_bytes = f.read()

        res = ocr.classification(img_bytes, png_fix=True, probability=False)
        print(res)
