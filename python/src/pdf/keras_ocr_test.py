import os

import keras_ocr

# 初始化 OCR 模型
pipeline = keras_ocr.pipeline.Pipeline()

# 读取图像并识别
image_path = os.path.join(os.path.dirname(__file__), "testdata/page_1.png")
image = keras_ocr.tools.read(image_path)

# 识别文字
prediction_groups = pipeline.recognize([image])

# 打印识别结果
for prediction in prediction_groups[0]:
    print("Detected text:", prediction[0], "Bounding box:", prediction[1])
