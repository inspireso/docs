import os

from PIL import Image

# 加载图像
image_path = os.path.join(os.path.dirname(__file__), "testdata/page_10.png")
print("image_path:", image_path)
image = Image.open(image_path)
from PIL import Image
from surya.model.detection.model import load_model as load_det_model
from surya.model.detection.model import load_processor as load_det_processor
from surya.model.table_rec.model import load_model as load_rec_model
from surya.model.table_rec.processor import load_processor as load_rec_processor
from surya.ocr import run_ocr

image = Image.open(image_path)
langs = ["en", "zh"]  # Replace with your languages - optional but recommended
det_processor, det_model = load_det_processor(), load_det_model()
rec_model, rec_processor = load_rec_model(), load_rec_processor()

predictions = run_ocr(
    [image], [langs], det_model, det_processor, rec_model, rec_processor
)
for prediction in predictions:
    text_lines = prediction["text_lines"]
    for line in text_lines:
        print(line["text"])
