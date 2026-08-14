#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

import cv2
from ppocronnx.predict_system import TextSystem


def test1():
    image = cv2.imread(os.path.join(os.path.dirname(__file__), "testdata/p1.png"))
    text_sys = TextSystem()

    res = text_sys.ocr_single_line(image)
    print("ocr_single_line", res)

    # 批量识别单行文本
    res = text_sys.ocr_lines([image])
    print("ocr_lines", res)

    # 检测并识别文本
    res = text_sys.detect_and_ocr(image)
    print("detect_and_ocr", res)
    for boxed_result in res:
        print(
            "detect_and_ocr,{}, {:.3f}".format(
                boxed_result.ocr_text, boxed_result.score
            )
        )
