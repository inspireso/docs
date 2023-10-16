import base64
from io import BytesIO

import cv2
import numpy as np
import pytesseract
from PIL import Image


# 灰度处理和二值处理
# lookup_table = [0 if i < 200 else 1 for i in range(256)]
def gray_processing(img, threshold=127):
    # 转为灰度模式
    img = img.convert('L')
    # 转为二值模式，阈值默认是 127，大于为白色，否则黑色。
    # 为什么127呢，256/2=128， 2^8=256, 一个字节byte是8个比特bit
    # image.convert('1')  # 即 threshold = 127
    # threshold = 125
    lookup_table = [0 if i < threshold else 1 for i in range(256)]
    img = img.point(lookup_table, '1')
    return img


def erode_dilate(im, threshold=2):
    # im = cv2.imread('xxx.jpg', 0)
    # cv2.imshow('xxx.jpg', im)

    # (threshold, threshold) 腐蚀矩阵大小
    kernel = np.ones((threshold, threshold), np.uint8)
    # 膨胀
    erosion = cv2.erode(im, kernel, iterations=1)
    cv2.imwrite('imgCode_erosion.jpg', erosion)
    Image.open('imgCode_erosion.jpg').show()
    # # 腐蚀
    eroded = cv2.dilate(erosion, kernel, iterations=1)
    cv2.imwrite('imgCode_eroded.jpg', eroded)
    Image.open('imgCode_eroded.jpg').show()
    return erosion


def get_result_by_imgCode_recognition(img):
    # 进行验证码识别
    result = pytesseract.image_to_string(img)  # 接口默认返回的是字符串
    # ''.join(result.split())  # 去掉全部空格和\n\t等
    result = ''.join(list(filter(str.isalnum, result)))  # 只保留字母和数字
    return result


def pass_counter(img, img_value):
    # 辨别是否识别正确
    rst = get_result_by_imgCode_recognition(img)
    if rst == img_value:
        return 1
    else:
        return 0


def most_frequent(lst):
    # 获取列表最频繁的元素，可用于集成投票获得识别结果
    # return max(lst, key=lst.count)
    return max(set(lst), key=lst.count)


# 假设您有一个名为 base64_code 的变量，其中包含 base64 编码的验证码
# base64_code = "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"

# 将 base64 编码的字符串解码为字节数据
# image_data = base64.b64decode(base64_code)

# 将字节数据转换为图像
# image = Image.open(BytesIO(image_data))

# 展示图像（可选）
# image.show()

# 保存图像到本地文件（可选）
# image.save("/Users/my/github/inspireso/docs/python/src/tou/captcha.png")

# 进行验证码识别（根据您的具体需求和使用的验证码识别方法进行实现）
# ...
# 打开图像
image = Image.open("/Users/my/github/inspireso/docs/python/src/tou/captcha.png")

img_gray = gray_processing(image, threshold=200)

img_gray.save("/Users/my/github/inspireso/docs/python/src/tou/captcha_gray.png")

im = np.asarray(img_gray, np.uint8)  # gray之后变成array，值变为0和1，有效去噪点
erosion = erode_dilate(im, threshold=2)
img1 = Image.fromarray(erosion * 255)  # 值为0到1，整个图片都是黑色的。
img1.save("/Users/my/github/inspireso/docs/python/src/tou/captcha_erosion.png")
result = get_result_by_imgCode_recognition(img1)

# 输出识别的验证码
print("识别的验证码:", result)

# 使用 OCR 进行验证码识别
captcha_text = pytesseract.image_to_string(img_gray, lang="eng")

# # 输出识别的验证码
print("识别的验证码:", captcha_text)
