import os

import ocrmypdf

input_pdf = "testdata/jh.pdf"
output_pdf = "processed_bank_statement.pdf"

# 直接处理PDF并生成包含文本的PDF
ocrmypdf.ocr(input_pdf, output_pdf, deskew=True)
