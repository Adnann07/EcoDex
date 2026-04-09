
# EcoDex

# EcoDex ML — Waste Classification

ResNet50 and EfficientNet-B0 fine-tuned on a merged waste dataset for 4-class classification.

## Classes
- recyclable
- organic
- e_waste
- hazardous

## Results

| Model | Val Accuracy |
|---|---|
| ResNet50 | 98.73% |
| EfficientNet-B0 | TBD |

## Project structure

```
src/
  dataset.py   dataset, transforms, dataloaders
  model.py     ResNet50 and EfficientNet-B0 builders
  utils.py     evaluation, plots, ONNX export
  train.py     training entry point
models/        saved .pth and .onnx files (via GitHub Releases)
```

## Training (Kaggle GPU)

Paste the contents of `src/train.py` into a Kaggle notebook cell and run.
The merged dataset must exist at `/kaggle/working/merged_dataset`.

To select architecture:
```python
run("resnet50")
# or
run("efficientnet_b0")
```

## Model files

ONNX models are attached to [GitHub Releases](../../releases).

| File | Use |
|---|---|
| `resnet50_fp32.onnx` | web (ONNX.js / onnxruntime-web) |
| `efficientnet_fp32.onnx` | web |
| `efficientnet_int8.onnx` | Flutter (onnxruntime_flutter) |

## Input / Output contract

- Input: `float32 [1, 3, 224, 224]` ImageNet normalised
- Output: `float32 [1, 4]` raw logits → softmax → argmax
- Confidence thresholds: high ≥ 0.80, fallback < 0.50

