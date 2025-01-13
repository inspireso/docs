#!/usr/bin/env python3

# -*- coding: utf-8 -*-


import os

import cv2
import ddddocr

ocr = ddddocr.DdddOcr(show_ad=False)
ocr.set_ranges("0123456789+-x/=")


def test1():
    # image = cv2.imread(
    #     os.path.join(os.path.dirname(__file__), "testdata/WechatIMG402.jpg")
    # )
    # # gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # # _, thresh_image = cv2.threshold(
    # #     gray_image, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
    # # )
    # # thresh_image 转换为bytes
    # img_bytes = cv2.imencode(".jpg", image)[1].tobytes()

    # # 识别图片中的文字
    # res = ocr.classification(img_bytes)
    # print(res)
    # s = ""
    # for i in res["probability"]:
    #     s += res["charsets"][i.index(max(i))]

    # print(s)

    # with open(os.path.join(os.path.dirname(__file__), "testdata/p1.png"), "rb") as f:
    with open(
        os.path.join(os.path.dirname(__file__), "testdata/image2.png"), "rb"
    ) as f:
        img_bytes = f.read()

        res = ocr.classification(img_bytes, png_fix=True, probability=False)
        print(res)

        # 识别图片中的文字
        res = ocr.classification(img_bytes, png_fix=True, probability=True)
        s = ""
        for i in res["probability"]:
            s += res["charsets"][i.index(max(i))]

        print(s)
