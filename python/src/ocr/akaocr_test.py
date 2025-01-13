import cv2
from akaocr import BoxEngine

# def test_akaocr():
#     img_path = "path/to/image.jpg"
#     image = cv2.imread(img_path)

#     # side_len: minimum inference image size
#     box_engine = BoxEngine(model_path: Any | None = None,
#                             side_len: int | None = None,
#                             conf_thres: float = 0.5
#                             mask_thes: float = 0.4,
#                             unclip_ratio: float = 2.0,
#                             max_candidates: int = 1000,
#                             device: str = 'cpu | gpu')

#     # inference for one image
#     results = box_engine(image) # [np.array([4 points], dtype=np.float32),...]
