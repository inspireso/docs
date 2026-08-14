# -*- coding: utf-8 -*-
"""
滑动验证码相关
"""
import cv2
import numpy as np

from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.remote.webdriver import WebDriver
from selenium.webdriver.remote.webelement import WebElement


def wait_for_destroy_windows():
    cv2.waitKey(0)
    cv2.destroyAllWindows()


def show_image(name, image):
    """
    展示图片
    :param name: window name
    :param image:  image mat
    """
    cv2.namedWindow(name, cv2.WINDOW_NORMAL | cv2.WINDOW_GUI_EXPANDED)
    cv2.imshow(name, image)


def _process_image(image, blur=False):
    """
    预处理; 部分网站的图片先模糊再求边缘的匹配效果 不如直接求边缘的匹配效果好
    <pre>
        模糊
        求边界
    <pre>
    :param image: image mat
    :param blur 是否模糊
    :return: handle image mat
    """
    if blur:
        image = cv2.GaussianBlur(image, (5, 5), 0)
    return cv2.Canny(image, 50, 150)


def _read_image_from_local_file(image_path, image_scale=cv2.IMREAD_GRAYSCALE):
    with open(image_path, "rb") as fd:
        content = fd.read()
    return cv2.imdecode(np.frombuffer(content, dtype=np.uint8), image_scale)


def _read_image_from_bytes(image_bytes, image_scale=cv2.IMREAD_GRAYSCALE):
    if not isinstance(image_bytes, bytes):
        raise RuntimeError("image bytes must be bytes type")
    return cv2.imdecode(np.frombuffer(image_bytes, np.uint8), image_scale)


def detect_displacement(
    image_slider, image_background, blur=False, display_image=False
):
    """
    探测缺口偏移量
    :param image_slider: 缺口图 numpy.ndarray or image file path
    :param image_background: 底图 numpy.ndarray or image file path
    :param blur: 预处理时是否模糊图片
    :param display_image: 展示图片
    :return: top_left_x, top_left_y, width, height
    """
    if isinstance(image_slider, str):
        image_slider = _read_image_from_local_file(image_slider)
    elif isinstance(image_slider, bytes):
        image_slider = _read_image_from_bytes(image_slider)
    if isinstance(image_background, str):
        image_background = _read_image_from_local_file(image_background)
    elif isinstance(image_background, bytes):
        image_background = _read_image_from_bytes(image_background)
    processed_image_slider = _process_image(image_slider, blur=blur)
    processed_image_background = _process_image(image_background, blur=blur)
    # match
    res = cv2.matchTemplate(
        processed_image_slider, processed_image_background, cv2.TM_CCOEFF_NORMED
    )
    _, _, _, max_location = cv2.minMaxLoc(res)
    # pos
    x, y = max_location
    # height width
    h, w = image_slider.shape
    # draw match
    cv2.rectangle(image_background, (x, y), (x + w, y + h), (255, 255, 255), 2)
    if display_image:
        show_image("processed_image_slider", processed_image_slider)
        show_image("processed_image_background", processed_image_background)
        show_image("match", image_background)
        wait_for_destroy_windows()
    return x, y, w, h


def mock_verify(driver: WebDriver, canvas: list[WebElement]):
    # canvas 转图片
    target = canvas[1]
    # 修改css
    driver.execute_script("arguments[0].setAttribute('class', '')", target)
    target_bytes = target.screenshot_as_png

    background = canvas[0]
    background_bytes = background.screenshot_as_png
    # 恢复css
    driver.execute_script(
        "arguments[0].setAttribute('class', 'slide-verify-block')", target
    )
    x, y, w, h = detect_displacement(
        target_bytes, background_bytes, display_image=False
    )
    print(x, y, w, h)

    sleep_seconds = lambda: random.choice([0.1, 0.2, 0.3])

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
    time.sleep(sleep_seconds())
    div = driver.find_element(by=By.CLASS_NAME, value="slide-verify-slider-mask-item")
    # target_size = target.size
    # xoffset = xoffset + target_size["width"] / 2

    # action = ActionChains(driver)
    # ActionChains(driver).click_and_hold(on_element=div).perform()
    # time.sleep(sleep_seconds())
    # ActionChains(driver).move_to_element_with_offset(
    #     to_element=target, xoffset=x, yoffset=y
    # ).release().perform()

    action = ActionChains(driver)
    # 第一步：在滑块处按住鼠标左键
    action.click_and_hold(div).perform()
    action.reset_actions()
    # 第二步：相对鼠标当前位置进行移动
    # action.move_by_offset(x, y)
    action.pause(0.01).move_by_offset(x, y).perform()
    # 第三步：释放鼠标
    action.release().perform()


if __name__ == "__main__":
    # test
    # 1. 使用cv2.matchTemplate方法
    x, y, w, h = detect_displacement("target.png", "background.png")
    print("x: %s, y: %s, w: %s, h: %s" % (x, y, w, h))
