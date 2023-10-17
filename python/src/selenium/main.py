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

# 获取 webdriver 的地址
executor = os.getenv("WEB_DRIVER_URL")
if executor is not None:
    print(f'###command_executor: {executor}')
else:
    print('###use local webdriver')

# 获取投票数量
votes_string = os.getenv("VOTES", "10000")
votes = int(votes_string) if votes_string.isdigit() else 10
print(f'###votes: {votes}')

implicitly_wait_second_str = os.getenv("IMPLICITLY_WAIT_SECOND", "1")
time_to_wait = (
    int(implicitly_wait_second_str) if implicitly_wait_second_str.isdigit() else 1
)


chrome_options = webdriver.ChromeOptions()
chrome_options.add_experimental_option('excludeSwitches', ['enable-automation'])
chrome_options.add_argument('--disable-blink-features=AutomationControlled')

edge_options = webdriver.EdgeOptions()
edge_options.add_experimental_option('excludeSwitches', ['enable-automation'])
edge_options.add_argument('--disable-blink-features=AutomationControlled')

firefox_options = webdriver.FirefoxOptions()
# firefox_options.add_experimental_option('excludeSwitches', ['enable-automation'])
# firefox_options.add_argument('--disable-blink-features=AutomationControlled')

driver_factorys = [
    # chrome
    lambda: webdriver.Chrome(options=chrome_options)
    if executor is None
    else webdriver.Remote(command_executor=executor, options=chrome_options),
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
ocr = OcrByOnnx()

import random

from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.remote.webelement import WebElement


def mock_nc(driver: WebDriver, div: WebElement):
    # 选择拖动滑块的节点
    # div = find_nc()
    # if div is None:
    #     time.sleep(1)
    #     div = find_nc()
    # ------------鼠标滑动操作------------
    # action = ActionChains(driver)
    # # 第一步：在滑块处按住鼠标左键
    # action.click_and_hold(sli_ele)
    # # 第二步：相对鼠标当前位置进行移动
    # action.move_by_offset(225, 0)
    # # 第三步：释放鼠标
    # action.release()
    # # 执行动作
    # action.perform()·

    sleep_seconds = lambda: random.choice([0.1, 0.2, 0.3])

    # div = driver.find_element(by=By.ID, value="nc_1_n1z")
    ActionChains(driver).click_and_hold(on_element=div).perform()

    time.sleep(sleep_seconds())
    ActionChains(driver).move_to_element_with_offset(
        to_element=div, xoffset=30, yoffset=10
    ).perform()
    time.sleep(sleep_seconds())
    ActionChains(driver).move_to_element_with_offset(
        to_element=div, xoffset=100, yoffset=20
    ).perform()
    time.sleep(sleep_seconds())
    ActionChains(driver).move_to_element_with_offset(
        to_element=div, xoffset=200, yoffset=50
    ).release().perform()


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

    # 先等待复选框加载
    checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")

    if len(checkboxs) == 0:
        try:
            nc = driver.find_elements(by=By.ID, value="nc_1_n1z")
            if len(nc) == 0:
                print('没有找到滑块验证')
                print('-------------')
                print(driver.page_source)
                return False
            # 模拟拖动滑块，避开滑块验证
            mock_nc(driver, nc[0])
            print('>>>模拟滑块验证成功')
        except Exception as e:
            print(e)

    print('-------------')
    while len(checkboxs) == 0 and retry_times < 3:
        print('等待复选框加载...')
        driver.refresh()
        time.sleep(1)
        checkboxs = driver.find_elements(by=By.CLASS_NAME, value="van-checkbox")
        retry_times += 1

    if len(checkboxs) == 0:
        return True

    checkboxs = checkboxs[::-1]
    counter.fetch_increment()

    select = checkboxs[4]
    print(f'选择：{select.text}')
    select.click()

    img_element = driver.find_element(by=By.CLASS_NAME, value="img")
    src = img_element.get_attribute('src')
    # 有时候会出现 src 为空的情况，这里做一个重试
    if len(src) == 0:
        time.sleep(1)
        src = img_element.get_attribute('src')

    if len(src) == 0:
        print('重新获取验证码...')
        img_element.click()
        src = img_element.get_attribute('src')

    base64_code = src[len('data:image/gif;base64,') :]
    if len(base64_code) == 0:
        return False

    # 将 base64 编码的字符串解码为字节数据
    image_data = base64.b64decode(base64_code)
    code = ocr.classification(image_data)
    if len(code) == 0:
        return False

    print(f'验证码：{code}')

    input = driver.find_element(by=By.NAME, value="randomCode")
    input.send_keys(code)

    submits = driver.find_elements(
        by=By.CLASS_NAME,
        value="submit_btn",
    )
    if len(submits) == 0:
        return False

    submit = submits[0]
    submit.click()
    thanks = driver.find_elements(by=By.CLASS_NAME, value="thanks")
    if len(thanks) > 0:
        counter.effected_increment()
        print(f'成功投 {counter.effected_count} 票')
    else:
        counter.error_increment()

    return False


class ThreadDriver(threading.Thread):
    """Call a function after a specified number of seconds:

    t = ThreadDriver(factory)
    t.start()
    t.cancel()     # stop the timer's action if it's still waiting

    """

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
                time.sleep(1)
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
        print('========================')
        print(f'总共：{counter.fetch_count} 票')
        print(f'成功：{counter.effected_count} 票')
        print(f'失败：{counter.error_count} 票')


main()
