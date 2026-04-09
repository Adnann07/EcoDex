import os
import argparse
import torch
import torch.nn as nn
from torch.optim import Adam
from torch.optim.lr_scheduler import StepLR

from dataset import get_dataloaders
from model import (build_resnet50, unfreeze_resnet_last_block,
                   build_efficientnet_b0, unfreeze_efficientnet_last_block)
from utils import evaluate, export_onnx


MERGED_DIR = "/kaggle/working/merged_dataset"
OUTPUT_DIR = "/kaggle/working"

BATCH_SIZE    = 32
NUM_WORKERS   = 4
PHASE1_LR     = 1e-3
PHASE1_EPOCHS = 8
PHASE2_LR     = 1e-4
PHASE2_EPOCHS = 4

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def run_epoch(model, loader, criterion, optimizer, training):
    model.train() if training else model.eval()
    total_loss, correct, total = 0.0, 0, 0
    with torch.set_grad_enabled(training):
        for images, labels, _ in loader:
            images, labels = images.to(DEVICE), labels.to(DEVICE)
            outputs = model(images)
            loss = criterion(outputs, labels)
            if training:
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
            total_loss += loss.item() * images.size(0)
            correct    += (outputs.argmax(dim=1) == labels).sum().item()
            total      += images.size(0)
    return total_loss / total, correct / total


def train_phase(model, train_loader, val_loader, lr, epochs, tag, save_path):
    criterion = nn.CrossEntropyLoss()
    optimizer = Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=lr)
    scheduler = StepLR(optimizer, step_size=3, gamma=0.5)
    best_val_acc = 0.0
    for epoch in range(1, epochs + 1):
        tr_loss, tr_acc = run_epoch(model, train_loader, criterion, optimizer, True)
        vl_loss, vl_acc = run_epoch(model, val_loader,   criterion, None,      False)
        scheduler.step()
        print(f"[{tag}] {epoch}/{epochs} "
              f"train_loss={tr_loss:.4f} train_acc={tr_acc:.4f} "
              f"val_loss={vl_loss:.4f} val_acc={vl_acc:.4f}")
        if vl_acc > best_val_acc:
            best_val_acc = vl_acc
            torch.save(model.state_dict(), save_path)
            print(f"  checkpoint saved val_acc={vl_acc:.4f}")
    return best_val_acc


def run(arch):
    save_path = os.path.join(OUTPUT_DIR, f"best_{arch}.pth")
    train_loader, val_loader = get_dataloaders(MERGED_DIR, BATCH_SIZE, num_workers=NUM_WORKERS)

    if arch == "resnet50":
        model = build_resnet50(freeze_backbone=True).to(DEVICE)
        print("Phase 1: frozen backbone")
        train_phase(model, train_loader, val_loader, PHASE1_LR, PHASE1_EPOCHS, "P1", save_path)
        model.load_state_dict(torch.load(save_path, map_location=DEVICE))
        print("Phase 2: unfreeze layer4")
        unfreeze_resnet_last_block(model)

    elif arch == "efficientnet_b0":
        model = build_efficientnet_b0(freeze_backbone=True).to(DEVICE)
        print("Phase 1: frozen backbone")
        train_phase(model, train_loader, val_loader, PHASE1_LR, PHASE1_EPOCHS, "P1", save_path)
        model.load_state_dict(torch.load(save_path, map_location=DEVICE))
        print("Phase 2: unfreeze last block")
        unfreeze_efficientnet_last_block(model)

    train_phase(model, train_loader, val_loader, PHASE2_LR, PHASE2_EPOCHS, "P2", save_path)
    model.load_state_dict(torch.load(save_path, map_location=DEVICE))

    print("Evaluation")
    evaluate(model, val_loader, DEVICE, BATCH_SIZE, output_prefix=arch, output_dir=OUTPUT_DIR)

    print("Exporting ONNX")
    export_onnx(
        model,
        save_path_fp32=os.path.join(OUTPUT_DIR, f"{arch}_fp32.onnx"),
        save_path_int8=os.path.join(OUTPUT_DIR, f"{arch}_int8.onnx"),
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--arch", choices=["resnet50", "efficientnet_b0"], default="efficientnet_b0")
    args = parser.parse_args()
    run(args.arch)
