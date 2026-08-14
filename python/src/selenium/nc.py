import random
import time

from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.remote.webdriver import WebDriver
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
