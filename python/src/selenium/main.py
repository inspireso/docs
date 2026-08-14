import base64
import os
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.remote.webdriver import WebDriver

# 指定投票页面
mock_url = os.getenv(
    "MOCK_URL",
    "https://m.xm.celoan.cn/service/businessEnvironment/businessFill?redirect=%252F&id=10002",
)
# mock_url = os.getenv(
#     "MOCK_URL",
#     "https://m.xm.celoan.cn/service/businessEnvironment/businessFill?redirect=%252F&id=10001",
# )


check_other = bool(os.getenv("CHECK_OTHER", False))
check_index = int(os.getenv("CHECK_INDEX", -3))
# check_index = int(os.getenv("CHECK_INDEX", 45))
print(f"###mock_url: {mock_url}")
print(f"###check_other: {check_other}")
print(f"###check_index: {check_index}")

# 获取 webdriver 的地址
executor = os.getenv("WEB_DRIVER_URL")
if executor is not None:
    print(f"###command_executor: {executor}")
else:
    print("###use local webdriver")

# 获取投票数量
votes_string = os.getenv("VOTES", "10000")
votes = int(votes_string) if votes_string.isdigit() else 10
print(f"###votes: {votes}")

implicitly_wait_second_str = os.getenv("IMPLICITLY_WAIT_SECOND", "3")
time_to_wait = (
    int(implicitly_wait_second_str) if implicitly_wait_second_str.isdigit() else 3
)


chrome_options = webdriver.ChromeOptions()
chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
chrome_options.add_argument("--disable-blink-features=AutomationControlled")

edge_options = webdriver.EdgeOptions()
edge_options.add_experimental_option("excludeSwitches", ["enable-automation"])
edge_options.add_argument("--disable-blink-features=AutomationControlled")

firefox_options = webdriver.FirefoxOptions()
# firefox_options.add_experimental_option('excludeSwitches', ['enable-automation'])
# firefox_options.add_argument('--disable-blink-features=AutomationControlled')

driver_factorys = [
    # chrome
    lambda: (
        webdriver.Chrome(options=chrome_options)
        if executor is None
        else webdriver.Remote(command_executor=executor, options=chrome_options)
    ),
    # edge
    # lambda: webdriver.Edge(options=edge_options)
    # if executor is None
    # else webdriver.Remote(command_executor=executor, options=edge_options),
    # firefox
    # lambda: webdriver.Firefox(options=firefox_options)
    # if executor is None
    # else webdriver.Remote(command_executor=executor, options=firefox_options),
]

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
import ddddocr

ocr = ddddocr.DdddOcr(ocr=True, det=False, show_ad=False)

import random

from slide_verify import mock_verify

sleep_seconds = lambda: random.choice([0.1, 0.2, 0.3])


def run(driver: WebDriver) -> bool:
    """运行测试用例
    Args:
        driver (WebDriver): 运行的 driver

    Returns:
        bool: 返回是否需要重新创建 driver
    """

    retry_times = 0

    driver.get(mock_url)
    # 隐式等待
    driver.implicitly_wait(time_to_wait)

    print("-------------")
    checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")
    while len(checkboxs) == 0 and retry_times < 3:
        print("等待复选框加载...")
        driver.refresh()
        time.sleep(1)
        checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")
        retry_times += 1

    if len(checkboxs) == 0:
        print(driver.page_source)
        return True

    # 其他区
    if check_other:
        checked = [8, 10, 6, 6, 14]
        last = 0
        for i in checked:
            select = checkboxs[random.randint(last, last + i - 1)]
            last += i
            # print(f"选择：{select.text}")
            select.click()

    counter.fetch_increment()

    select = checkboxs[check_index]
    print(f"选择：{select.text}")
    select.click()

    def fill_code(refresh: bool = False):
        img_element = driver.find_element(by=By.CLASS_NAME, value="img")
        if refresh:
            print("重新获取验证码...")
            img_element.click()
            time.sleep(1)

        src = img_element.get_attribute("src")
        # 有时候会出现 src 为空的情况，这里做一个重试
        if len(src) == 0:
            time.sleep(1)
            src = img_element.get_attribute("src")

        if len(src) == 0:
            print("重新获取验证码...")
            img_element.click()
            src = img_element.get_attribute("src")

        base64_code = src[len("data:image/gif;base64,") :]
        if len(base64_code) == 0:
            return False

        # 将 base64 编码的字符串解码为字节数据
        image_data = base64.b64decode(base64_code)
        code = ocr.classification(image_data)
        if len(code) == 0:
            return False
        print(f"验证码：{code}")
        result = calculate_code(code)

        input = driver.find_element(by=By.NAME, value="randomCode")
        input.send_keys(result)
        # submits = driver.find_elements(
        #     by=By.CLASS_NAME,
        #     value="submit_btn",
        # )
        # if len(submits) == 0:
        #     return False
        # submit = submits[0]
        # submit.click()

    try:
        fill_code()
        while True:
            mock_verify(driver, "")

            thanks = driver.find_elements(by=By.CLASS_NAME, value="thanks")
            if len(thanks) > 0:
                counter.effected_increment()
                print(f"成功投 {counter.effected_count} 票")
                return True

            dlgs = driver.find_elements(
                by=By.CLASS_NAME, value="van-dialog__message--has-title"
            )
            if len(dlgs) > 0:
                title = dlgs[0].text
                if title == "验证码错误":
                    print(">>>验证码错误")
                    btn = driver.find_element(
                        by=By.CLASS_NAME, value="van-dialog__confirm"
                    )
                    btn.click()
                    fill_code(refresh=True)

            time.sleep(sleep_seconds())

    except Exception as e:
        print(e)
        counter.error_increment()
        return False


# 验证码计算
def calculate_code(code: str) -> str:
    a, b, c = code[0], code[1], code[2]
    if b == "+":
        return str(int(a) + int(c))
    elif b in {"-", "i", "7"}:
        return str(int(a) - int(c))
    elif b == "x":
        return str(int(a) * int(c))
    elif b in {"/", "l"}:
        return str(int(a) / int(c))
    else:
        return str(int(a) + int(c))


class ThreadDriver(threading.Thread):
    def __init__(self, factory):
        threading.Thread.__init__(self)
        self.factory = factory
        self.finished = threading.Event()

    def cancel(self):
        """Stop the timer if it hasn't finished yet."""
        self.finished.set()

    def run(self):
        if not self.finished.is_set():
            self.run_internal()

        self.finished.set()

    def create_driver(self):
        retry_times = 0
        error = None
        while retry_times < 3:
            try:
                return self.factory()
            except Exception as e:
                error = e
                retry_times += 1
        if error is not None:
            raise error

    def run_internal(self):
        driver: WebDriver = self.create_driver()
        try:
            for _ in range(votes):
                if run(driver):
                    driver.quit()
                    driver = self.factory()
                time.sleep(sleep_seconds())
        finally:
            driver.quit()


# 创建多个线程并启动

threads = []

num_threads = len(driver_factorys)  # 设置线程数量


def run_with_thread():
    for i in range(num_threads):
        factory = driver_factorys[i % len(driver_factorys)]
        t = ThreadDriver(factory)
        threads.append(t)
        t.start()

    # 等待所有线程完成
    for t in threads:
        t.join()

    print("所有线程执行完毕")


def main():
    try:
        run_with_thread()
    finally:
        print("========================")
        print(f"总共：{counter.fetch_count} 票")
        print(f"成功：{counter.effected_count} 票")
        print(f"失败：{counter.error_count} 票")


main()
