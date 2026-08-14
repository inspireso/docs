import logging
import re
import time
from pathlib import Path

import pdfplumber
import requests
from bs4 import BeautifulSoup

log = logging.getLogger(__name__)


class XiamenTaxSpider:
    def __init__(self):
        self.base_url = (
            "http://xiamen.chinatax.gov.cn/xmswcms/bsfw/bsfw-sstz/pages/index.html"
        )
        self.session = requests.Session()
        self.headers = {
            "Pragma": "no-cache",
            "Referer": "http://xiamen.chinatax.gov.cn/xmswcms/bsfw/bsfw-sstz/pages/index.html",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-US;q=0.7",
        }
        self.download_dir = Path("downloads")
        self.download_dir.mkdir(exist_ok=True)

    def fetch_page(self, url):
        try:
            response = self.session.get(url, headers=self.headers, timeout=30)
            response.raise_for_status()
            response.encoding = "utf-8"
            return response.text
        except requests.RequestException as e:
            log.error(f"请求失败: {url} - {str(e)}")
            return None

    def parse_announcements(self, html):
        soup = BeautifulSoup(html, "html.parser")
        announcements = []

        for item in soup.select("li.right_content_li"):
            link = item.select_one("a")
            if not link:
                continue

            title = link.get_text(strip=True)

            # 匹配2025年2月的公告
            if re.search(r"欠税公告", title):
                href = link["href"]
                if not href.startswith("http"):
                    href = f"http://xiamen.chinatax.gov.cn{href}"

                pub_date = (
                    item.select_one("span.time").get_text(strip=True)
                    if item.select_one("span.time")
                    else ""
                )
                announcements.append({"title": title, "url": href, "date": pub_date})
        return announcements

    def download_file(self, url, filename):
        try:
            response = self.session.get(url, headers=self.headers, stream=True)
            response.raise_for_status()

            file_path = self.download_dir / filename
            with open(file_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            log.info(f"文件已下载: {file_path}")

            # 验证PDF完整性
            if file_path.suffix.lower() == ".pdf":
                try:
                    with pdfplumber.open(file_path) as pdf:
                        if len(pdf.pages) < 1:
                            raise ValueError("PDF文件损坏")
                except Exception as e:
                    log.error(f"PDF校验失败: {file_path} - {str(e)}")
                    file_path.unlink()
                    return False
            return True
        except Exception as e:
            log.error(f"下载失败: {url} - {str(e)}")
            return False

    def process_announcement(self, announcement):
        html = self.fetch_page(announcement["url"])
        if not html:
            return

        soup = BeautifulSoup(html, "html.parser")
        attachments = []

        # 提取附件链接
        for a in soup.select('a[href$=".xlsx"]'):
            href = a["href"]
            if not href.startswith("http"):
                href = f"http://xiamen.chinatax.gov.cn{href}"
            attachments.append({"title": a["title"], "url": href})

        # 下载附件
        for attach in attachments:
            filename = f"{announcement['date']}_{attach['title']}"
            filename = re.sub(r'[\\/*?:"<>|]', "", filename)  # 清理非法字符
            self.download_file(attach["url"], filename)

    def run(self):
        log.info("开始爬取厦门市税务局欠税公告")
        html = self.fetch_page(self.base_url)
        if not html:
            return

        announcements = self.parse_announcements(html)
        log.info(f"找到{len(announcements)}条符合条件的公告")

        for idx, ann in enumerate(announcements, 1):
            log.info(f"处理公告 {idx}/{len(announcements)}: {ann['title']}")
            self.process_announcement(ann)
            time.sleep(3)  # 礼貌性延迟


def main():
    spider = XiamenTaxSpider()
    spider.run()


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.DEBUG,
    )
    main()
