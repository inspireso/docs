import os

# 定义输入的PDF文件路径
pdf_path = os.path.join(os.path.dirname(__file__), "testdata/jh.pdf")

output_path = os.path.join(os.path.dirname(__file__), "output.csv")
# 定义输出的Excel文件路径
# excel_path = "output.xlsx"

# # 使用tabula读取PDF中的表格，并指定页面范围和选项
# # 这里假设你想要提取第一页上的所有表格
# dfs = tabula.read_pdf(pdf_path, pages="1", multiple_tables=True)
# # 将所有DataFrame合并成一个（如果有多张表）
# if len(dfs) > 1:
#     combined_df = pd.concat(dfs, ignore_index=True)

# # 检查是否成功读取到了数据
# if combined_df is not None:
#     # 将DataFrame保存为CSV文件
#     combined_df.to_csv(output_path, index=False)
#     print(f"Data has been saved to {output_path}")
# else:
#     print("No tables found in the PDF.")


import pandas as pd
import pdfplumber
import pytesseract
from PIL import Image

# Tesseract 路径（如果需要手动指定）
# pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

# 打开 PDF 文件
data = []  # 用于存储每行银行流水记录

with pdfplumber.open(pdf_path) as pdf:
    for i, page in enumerate(pdf.pages):
        # text = page.extract_text()  # 提取文本
        # images = page.images  # 获取图像信息
        page_image = page.to_image(resolution=600)
        output_path = f"testdata/page_{i+1}.png"
        page_image.save(output_path, format="PNG")
        print(f"Page {i+1} saved as {output_path}")

        # if text:
        #     print(f"Page {i+1} contains text.")
        # elif images:
        #     print(f"Page {i+1} contains images (likely a scanned document).")
        # else:
        #     print(f"Page {i+1} is empty or contains unsupported content.")

        # 获取 PIL 图像对象
        # pil_image = page.to_image().original
        # # 使用 OCR 识别文字
        # text = pytesseract.image_to_string(pil_image, lang="chi_sim")
        # print(text)

#         # 按行分割，并根据实际情况筛选出每行内容
#         lines = text.split("\n")
#         for line in lines:
#             if line.strip():  # 跳过空行
#                 # 处理和提取有效信息
#                 data.append([line.strip()])

# # 转换为 DataFrame 并保存为 CSV 或 Excel
# df = pd.DataFrame(data, columns=["Bank Statement"])
# csv_path = "bank_statement.csv"
# df.to_csv(csv_path, index=False)
