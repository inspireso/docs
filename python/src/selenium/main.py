import base64
import os
import time

from ocrlib import OcrByOnnx

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.remote.webdriver import WebDriver

# 指定投票页面
mock_url = os.getenv(
    'MOCK_URL',
    'https://m.xm.celoan.cn/Service/businessFill?redirect=%252FService%252FbusinessEnvironment&id=3',
)
executor = os.getenv("WEB_DRIVER_URL", "http://localhost:4444/wd/hub")
votes_string = os.getenv("VOTES", "10")
votes = int(votes_string) if votes_string.isdigit() else 1000

print(f'use command_executor: {executor}')

import threading


class Counter(object):
    def __init__(self):
        self.lock = threading.Lock()
        self.fetch_count = 0
        self.effected_count = 0
        self.error_count = 0

    def fetch_increment(self, count=1):
        self.lock.acquire()
        try:
            self.fetch_count += count
        finally:
            self.lock.release()

    def effected_increment(self, count=1):
        self.lock.acquire()
        try:
            self.effected_count += count
        finally:
            self.lock.release()

    def error_increment(self, count=1):
        self.lock.acquire()
        try:
            self.error_count += count
        finally:
            self.lock.release()


counter = Counter()

# 创建一个基于 ONNX 的模型的 OCR 识别器
ocr = OcrByOnnx()


def run(driver):
    driver.get(mock_url)
    counter.fetch_increment()
    checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")
    while len(checkboxs) == 0:
        print('等待复选框加载...')
        driver.refresh()
        time.sleep(1)
        checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")
    checkboxs = checkboxs[::-1]

    select = checkboxs[4]
    print(f'选择：{select.text}')
    select.click()

    imgs = driver.find_elements(by=By.CLASS_NAME, value="img")
    while len(imgs) == 0:
        print('等待图片加载...')
        imgs = driver.find_elements(by=By.CLASS_NAME, value="img")

    element = imgs[0]
    src = element.get_attribute('src')
    if len(src) == 0:
        element.click()

    base64_code = src[len('data:image/gif;base64,') :]
    # 将 base64 编码的字符串解码为字节数据
    image_data = base64.b64decode(base64_code)
    code = ocr.classification(image_data)
    if len(code) == 0:
        return

    print(F'验证码：{code}')

    input = driver.find_element(by=By.NAME, value="randomCode")
    input.send_keys(code)

    submits = driver.find_elements(
        by=By.CLASS_NAME,
        value="submit_btn",
    )
    if len(submits) == 0:
        return

    submit = submits[0]
    submit.click()
    thanks = driver.find_elements(by=By.CLASS_NAME, value="thanks")
    if len(thanks) == 0:
        print('等待成功返回...')
        time.sleep(1)
        thanks = driver.find_elements(by=By.CLASS_NAME, value="thanks")
    if len(thanks) > 0:
        counter.effected_increment()
        print(f'成功投 {counter.effected_count} 票')
    else:
        counter.error_increment()


class ThreadDriver(threading.Thread):
    """Call a function after a specified number of seconds:

    t = Timer(30.0, f, args=None, kwargs=None)
    t.start()
    t.cancel()     # stop the timer's action if it's still waiting

    """

    def __init__(self, driver):
        threading.Thread.__init__(self)
        self.driver = driver
        self.finished = threading.Event()

    def cancel(self):
        """Stop the timer if it hasn't finished yet."""
        self.finished.set()

    def run(self):
        if not self.finished.is_set():
            for _ in range(votes):
                time.sleep(1)
                run(self.driver)
        self.finished.set()


# 创建多个线程并启动

threads = []
drivers = [
    webdriver.Remote(command_executor=executor, options=webdriver.ChromeOptions()),
    # webdriver.Remote(command_executor=executor, options=webdriver.FirefoxOptions()),
    # webdriver.Remote(command_executor=executor, options=webdriver.EdgeOptions()),
    # webdriver.Chrome(options=chrome_options),
    # webdriver.Edge(),
    # webdriver.Firefox(),
]
num_threads = len(drivers)  # 设置线程数量


def run_with_thread():
    try:
        for i in range(num_threads):
            driver = drivers[i % len(drivers)]
            t = ThreadDriver(driver)
            threads.append(t)
            t.start()

        # 等待所有线程完成
        for t in threads:
            t.join()

        print("所有线程执行完毕")

    finally:
        for driver in drivers:
            driver.quit()


def main():
    try:
        run_with_thread()
    finally:
        print('--------------------')
        print(f'总共：{counter.fetch_count} 票')
        print(f'成功：{counter.effected_count} 票')
        print(f'失败：{counter.error_count} 票')


main()
