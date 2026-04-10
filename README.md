
# EcoDex

# EcoDex ML — Waste Classification

ResNet50 and EfficientNet-B0 fine-tuned on a merged waste dataset for 4-class classification.


# Waste Classification ML Models: Training, Optimization & Deployment

This repository documents the complete pipeline for training and deploying a high-performance waste classification system. The project involved training two state-of-the-art deep learning models (ResNet50 and EfficientNet-B0) to classify waste into four categories: **Recyclable**, **Organic**, **E-Waste**, and **Hazardous**.

The models were then exported to **ONNX format**, optimized for mobile and web deployment, and prepared for integration into a Flutter application.

---

## 🧠 Models Overview

### ResNet50 Model
- **Architecture**: ResNet50 pre-trained on ImageNet
- **Training Strategy**: Two-phase fine-tuning (frozen backbone → unfreeze layer4)
- **Final Validation Accuracy**: **98.73%**
- **Confidence Routing**: 2,158 high-confidence, 40 uncertain, 0 fallback
- **Class-wise Performance**:
  - E-Waste: 93.33%
  - Hazardous: 85.29%
  - Organic: 99.28%
  - Recyclable: 99.36%

### EfficientNet-B0 Model
- **Architecture**: EfficientNet-B0 via `timm` library
- **Training Strategy**: Two-phase fine-tuning (frozen backbone → unfreeze last block)
- **Final Validation Accuracy**: **98.00%**
- **Confidence Routing**: 2,107 high-confidence, 88 uncertain, 3 fallback
- **Class-wise Performance**:
  - E-Waste: 96.77%
  - Hazardous: 58.62%
  - Organic: 92.90%
  - Recyclable: 99.14%

---

## 📁 Dataset Sources & Preprocessing

Two public datasets were merged and remapped into a unified label space:

| Dataset | Source | Classes Remapped |
|--------|--------|------------------|
| Trash Type Image Dataset | Farzad Nekouei | cardboard, glass, metal, paper, plastic, trash |
| Garbage Classification v2 | Sumn2u | metal, glass, paper, cardboard, plastic, biological, battery |

**Remapping Logic**:
- Recyclable ← cardboard, glass, metal, paper, plastic
- Organic ← biological
- E-Waste ← battery
- Hazardous ← trash

**Final Dataset**: 10,992 total images after merging and deduplication.

---

## 🏋️ Training Methodology

### Data Augmentation (Training)
- Random resized crop (224×224)
- Random horizontal & vertical flips
- Color jitter (brightness, contrast, saturation)
- Random rotation (EfficientNet only)

### Two-Phase Training Strategy

**Phase 1 (Frozen Backbone)**
- Epochs: 8
- Learning rate: 1e-3
- Optimizer: Adam
- LR Scheduler: StepLR (step=3, gamma=0.5)

**Phase 2 (Unfreeze Last Block)**
- Epochs: 4
- Learning rate: 1e-4 (ResNet) / 1e-4 (EfficientNet)

### Confidence-Based Routing
- High confidence (>80%): Direct prediction
- Medium confidence (50–80%): Flagged as uncertain
- Low confidence (<50%): Fallback to user input

---

## 🔄 ONNX Export & Optimization

### Export Process

Both models were exported to ONNX format with:
- Opset version: 17 (fallback to 18 when needed)
- Dynamic batching support
- ImageNet normalization (mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225])

### File Sizes After Export

| Model | ONNX File | External Data | Merged Size |
|-------|-----------|---------------|-------------|
| ResNet50 | 223 KB | 91.8 MB | 89.8 MB |
| EfficientNet | 505 KB | 15.7 MB | 15.7 MB |

### IR Version Downgrade

To ensure compatibility with ONNX Runtime for mobile deployment, external data was merged into a single file and IR version was downgraded from **v10 → v8**.

### Quantization Attempt

Dynamic INT8 quantization was attempted using `onnxruntime.quantization`, but was skipped due to incomplete symbolic shape inference. FP32 models remain fully functional for both Flutter and web deployment.

---

## 📦 Deployment Artifacts

Final models are ready for integration:


assets/models/
├── waste_classifier_v8.onnx # 89.8 MB (ResNet50, IRv8)
├── efficientnet_v8.onnx # 15.7 MB (EfficientNet, IRv8)



### Input / Output Specification
- **Input**: float32 [batch, 3, 224, 224] (ImageNet normalized)
- **Output**: float32 [batch, 4] logits → softmax → argmax
- **Classes**: ["recyclable", "organic", "e_waste", "hazardous"]

---

## 📊 Evaluation Metrics

### Confusion Matrices & Confidence Distributions

Both notebooks generate comprehensive evaluation visualizations:
- Confusion matrices (per class)
- Confidence score histograms
- Per-class accuracy bar charts
- Uncertainty sample exports (for manual review)

Uncertain samples are saved locally for dataset improvement.

---

## 🛠️ Notebooks Included

### 1. `resnet50-and-efficientnet-b0-train-for-datasets.ipynb`
- Full training pipeline for both models
- Dataset merging and preprocessing
- Two-phase fine-tuning
- Evaluation with routing logic
- ONNX export and INT8 quantization attempts
- ZIP creation for external data files

### 2. `merging_models.ipynb`
- Upload external ONNX `.data` files
- Merge external data into single ONNX files
- Downgrade IR version to 8 for Flutter compatibility
- Download final merged models

---

## ✅ Key Achievements

- **98.73%** validation accuracy with ResNet50
- **98.00%** validation accuracy with EfficientNet-B0
- **89.8 MB** and **15.7 MB** final model sizes
- Confidence-based routing reduces user friction
- Both models ready for Flutter `google_ml_kit` or `onnxruntime` integration
- Complete evaluation suite (confusion matrices, confidence histograms, per-class accuracy)

---

## 🚀 Next Steps

- Implement INT8 quantization successfully for mobile optimization
- Deploy models in Flutter using `onnxruntime` or `tflite`
- Collect and retrain on uncertainty samples
- Explore Core ML export for iOS native deployment
- Add more waste categories (e.g., "Textiles", "Construction Waste")

---

## 📄 License

This project is for educational and research purposes. Datasets used are sourced from Kaggle and are subject to their original licenses.

---

## 🙏 Acknowledgments

- Farzad Nekouei – Trash Type Image Dataset
- Sumn2u – Garbage Classification v2
- ONNX Runtime team
- PyTorch & Hugging Face `timm` libraries
