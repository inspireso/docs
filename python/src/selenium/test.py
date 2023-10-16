import time

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

chrome_options = Options()
chrome_options.add_argument('--headless')


def connect_remote_chrome(url_str):
    print(f'Conencting to {url_str} ...')
    options = webdriver.ChromeOptions()

    driver = webdriver.Remote(
        command_executor="http://localhost:4444/wd/hub",
        options=options,
    )

    driver.get(url_str)
    content = driver.title.split("_")[0]
    print(content)
    driver.close()


connect_remote_chrome("https://www.baidu.com")
