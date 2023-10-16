import base64
from io import BytesIO

# import requests
from PIL import Image
from requests_html import HTMLSession


def fetch():
    # 创建一个HTML会话
    session: HTMLSession = HTMLSession()

    # 发送HTTP请求并渲染页面
    response = session.get(
        'https://m.xm.celoan.cn/Service/businessFill?redirect=%252FService%252FbusinessEnvironment&id=3'
    )
    print(response.html.html)
    response.html.render()

    # 提取渲染后的页面内容
    content = response.html.html

    # 打印渲染后的页面内容
    print(content)

    # 关闭会话
    session.close()

    # entry_url = 'https://m.xm.celoan.cn/Service/businessFill?redirect=%252FService%252FbusinessEnvironment&id=3'
    # with HTMLSession() as session:
    #     response = session.get(entry_url)
    #     # print(response.html.html)
    #     response.html.render()
    #     print(response.html.html)

    #     response = session.get(
    #         'https://m.xm.celoan.cn/api/celoan/quesBusiness/client/captchaImageQues',
    #     )
    #     print(response.json())
    # data = response.json()
    # base64_code = data['img']
    # image_data = base64.b64decode(base64_code)
    # image = Image.open(BytesIO(image_data))
    # image.show()


fetch()

# 假设您有一个名为 base64_code 的变量，其中包含 base64 编码的验证码
# base64_code = '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'

# # 将 base64 编码的字符串解码为字节数据
# image_data = base64.b64decode(base64_code)

# # 将字节数据转换为图像
# image = Image.open(BytesIO(image_data))

# # 展示图像（可选）
# # image.show()

# # 保存图像到本地文件（可选）
# image.save("/Users/my/github/inspireso/docs/python/src/tou/captcha.png")

# import pyppeteer.chromium_downloader

# print('默认版本是：{}'.format(pyppeteer.__chromium_revision__))
# print(
#     '可执行文件默认路径：{}'.format(pyppeteer.chromium_downloader.chromiumExecutable.get('win64'))
# )
# print('win64平台下载链接为：{}'.format(pyppeteer.chromium_downloader.downloadURLs.get('win64')))
