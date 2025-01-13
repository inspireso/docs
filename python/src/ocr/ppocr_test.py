#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

import cv2
from ppocronnx.predict_system import TextSystem


def test1():
    image = cv2.imread(
        os.path.join(os.path.dirname(__file__), "testdata/WechatIMG401.jpg")
    )
    text_sys = TextSystem()

    res = text_sys.ocr_single_line(image)
    print(res)

    # 批量识别单行文本
    res = text_sys.ocr_lines([image])
    print(res[0])

    # 检测并识别文本
    res = text_sys.detect_and_ocr(image)
    for boxed_result in res:
        print("{}, {:.3f}".format(boxed_result.ocr_text, boxed_result.score))
