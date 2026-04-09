import os
import torch
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import torch.nn.functional as F

from dataset import CLASSES, CONFIDENCE_HIGH, CONFIDENCE_LOW, FALLBACK_CLASS


def route(conf, pred_idx):
    if conf >= CONFIDENCE_HIGH:
        return CLASSES[pred_idx], "high"
    elif conf >= CONFIDENCE_LOW:
        return CLASSES[pred_idx], "uncertain"
    return FALLBACK_CLASS, "fallback"


def save_uncertain_image(tensor, idx, tier, uncertain_dir):
    os.makedirs(uncertain_dir, exist_ok=True)
    mean = torch.tensor([0.485, 0.456, 0.406]).view(3, 1, 1)
    std  = torch.tensor([0.229, 0.224, 0.225]).view(3, 1, 1)
    img  = (tensor.cpu() * std + mean).clamp(0, 1).permute(1, 2, 0).numpy()
    plt.imsave(os.path.join(uncertain_dir, f"{tier}_{idx:05d}.png"), img)


def evaluate(model, val_loader, device, batch_size, output_prefix="model", output_dir="."):
    model.eval()
    all_preds, all_labels, all_confs = [], [], []
    routed = {"high": 0, "uncertain": 0, "fallback": 0}
    subclass_stats = defaultdict(lambda: {"correct": 0, "total": 0})
    uncertain_dir = os.path.join(output_dir, f"uncertain_{output_prefix}")
    n_saved = 0

    with torch.no_grad():
        for b_idx, (images, labels, cls_names) in enumerate(val_loader):
            images = images.to(device)
            probs  = F.softmax(model(images), dim=1)
            confs, preds = probs.max(dim=1)
            for i in range(images.size(0)):
                conf, pred, label = confs[i].item(), preds[i].item(), labels[i].item()
                _, tier = route(conf, pred)
                if tier in ("uncertain", "fallback"):
                    save_uncertain_image(images[i], b_idx * batch_size + i, tier, uncertain_dir)
                    n_saved += 1
                routed[tier] += 1
                subclass_stats[cls_names[i]]["total"]   += 1
                subclass_stats[cls_names[i]]["correct"] += int(pred == label)
                all_preds.append(pred)
                all_labels.append(label)
                all_confs.append(conf)

    acc = sum(p == l for p, l in zip(all_preds, all_labels)) / len(all_labels)
    print(f"val accuracy: {acc:.4f}")
    print(f"routing: {routed}")
    print(f"uncertain saved: {n_saved}")

    print(f"\n{'class':<16} {'correct':>8} {'total':>8} {'acc':>8}")
    print("-" * 44)
    for name in sorted(subclass_stats):
        s = subclass_stats[name]
        a = s["correct"] / s["total"] if s["total"] else 0.0
        print(f"{name:<16} {s['correct']:>8} {s['total']:>8} {a:>8.4f}")

    cm   = confusion_matrix(all_labels, all_preds)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=CLASSES)
    fig, ax = plt.subplots(figsize=(7, 7))
    disp.plot(ax=ax, colorbar=False)
    plt.title(f"{output_prefix} confusion matrix")
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f"{output_prefix}_confusion_matrix.png"), dpi=150)
    plt.close()

    plt.figure(figsize=(8, 4))
    plt.hist(all_confs, bins=40, edgecolor="black")
    plt.axvline(CONFIDENCE_HIGH, color="green", linestyle="--", label=f"high ({CONFIDENCE_HIGH})")
    plt.axvline(CONFIDENCE_LOW,  color="red",   linestyle="--", label=f"fallback ({CONFIDENCE_LOW})")
    plt.xlabel("Confidence")
    plt.ylabel("Count")
    plt.title(f"{output_prefix} confidence distribution")
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f"{output_prefix}_confidence_dist.png"), dpi=150)
    plt.close()

    class_accs = []
    for cls in CLASSES:
        s = subclass_stats[cls]
        class_accs.append(s["correct"] / s["total"] if s["total"] else 0.0)
    plt.figure(figsize=(7, 4))
    plt.bar(CLASSES, class_accs, edgecolor="black")
    plt.ylim(0, 1)
    plt.ylabel("Accuracy")
    plt.title(f"{output_prefix} per-class accuracy")
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f"{output_prefix}_per_class_acc.png"), dpi=150)
    plt.close()


def export_onnx(model, save_path_fp32, save_path_int8):
    import onnx
    from onnxruntime.quantization import quantize_dynamic, QuantType
    from onnxruntime.quantization import shape_inference as ort_shape

    model.eval().cpu()
    dummy = torch.zeros(1, 3, 224, 224)
    torch.onnx.export(
        model, dummy, save_path_fp32,
        opset_version=17,
        input_names=["image"],
        output_names=["logits"],
        dynamic_axes={"image": {0: "batch_size"}, "logits": {0: "batch_size"}},
    )
    print(f"FP32: {save_path_fp32} ({os.path.getsize(save_path_fp32)/1e6:.1f} MB)")

    inferred = save_path_fp32.replace(".onnx", "_inferred.onnx")
    try:
        ort_shape.quant_pre_process(save_path_fp32, inferred, skip_optimization=False)
        quantize_dynamic(model_input=inferred, model_output=save_path_int8, weight_type=QuantType.QInt8)
        os.remove(inferred)
        print(f"INT8: {save_path_int8} ({os.path.getsize(save_path_int8)/1e6:.1f} MB)")
    except Exception as e:
        print(f"INT8 quantization failed: {e}")
