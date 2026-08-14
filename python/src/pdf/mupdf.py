import os
import pathlib

import pymupdf4llm

pdf_path = os.path.join(os.path.dirname(__file__), "testdata/jh.pdf")
md_text = pymupdf4llm.to_markdown(pdf_path)
# print(md_text)
output_file = pathlib.Path("output.md")
output_file.write_bytes(md_text.encode())
