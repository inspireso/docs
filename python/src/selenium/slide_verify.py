import random

from selenium.webdriver.remote.webdriver import WebDriver

sleep_seconds = lambda: random.choice([0.1, 0.2, 0.3])


def mock_verify(driver: WebDriver, canvas):
    driver.execute_script(
        "return this.$nuxt.$children[1].$children[0].$children[0].submitData()"
    )


# def mock_verify(driver: WebDriver, canvas: list[WebElement]):
#     # 获取 blockx ,执行 this.$nuxt.$children[1].$children[0].$children[0].$children[1].$children[0].block_x
#     block_x = driver.execute_script(
#         "return this.$nuxt.$children[1].$children[0].$children[0].$children[1].$children[0].block_x"
#     )

#     target = canvas[1]
#     div = driver.find_element(by=By.CLASS_NAME, value="slide-verify-slider-mask-item")

#     xoffset = block_x  # + random.randint(0, 9)
#     # 设置div 的 left 值为 block_x
#     # driver.execute_script(f"arguments[0].style.left = '{block_x}px'", div)
#     actions = ActionChains(driver)
#     actions.click_and_hold(on_element=div)
#     actions.move_to_element_with_offset(
#         to_element=target, xoffset=xoffset, yoffset=0
#     ).perform()
#     # 强制设置位置
#     driver.execute_script(f"arguments[0].style.left = '{xoffset}px'", target)
#     ActionChains(driver).release().perform()


# det = ddddocr.DdddOcr(show_ad=False, det=False, ocr=False)


# def mock_verify(driver: WebDriver, canvas: list[WebElement]):
#     # canvas 转图片
#     target = canvas[1]
#     # 修改css
#     driver.execute_script("arguments[0].setAttribute('class', '')", target)
#     target_bytes = target.screenshot_as_png

#     background = canvas[0]
#     background_bytes = background.screenshot_as_png
#     # 恢复css
#     driver.execute_script(
#         "arguments[0].setAttribute('class', 'slide-verify-block')", target
#     )
#     res = det.slide_match(target_bytes, background_bytes, simple_target=True)

#     print(res)

#     sleep_seconds = lambda: random.choice([0.1, 0.2, 0.3])

#     # ------------鼠标滑动操作------------
#     # action = ActionChains(driver)
#     # # 第一步：在滑块处按住鼠标左键
#     # action.click_and_hold(sli_ele)
#     # # 第二步：相对鼠标当前位置进行移动
#     # action.move_by_offset(225, 0)
#     # # 第三步：释放鼠标
#     # action.release()
#     # # 执行动作
#     # action.perform()·
#     time.sleep(sleep_seconds())
#     xoffset = res["target"][0]
#     div = driver.find_element(by=By.CLASS_NAME, value="slide-verify-slider-mask-item")
#     # target_size = target.size
#     # xoffset = xoffset + target_size["width"] / 2

#     # action = ActionChains(driver)
#     ActionChains(driver).click_and_hold(on_element=div).perform()
#     time.sleep(sleep_seconds())
#     ActionChains(driver).move_to_element_with_offset(
#         to_element=target, xoffset=xoffset, yoffset=10
#     ).release().perform()
