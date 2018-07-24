import sys

print(sys.path)

import onnxruntime

print(onnxruntime.get_device())
print(onnxruntime.get_available_providers())
