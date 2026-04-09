import torch.nn as nn
from torchvision import models
import timm

NUM_CLASSES = 4


def build_resnet50(freeze_backbone=True):
    model = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V1)
    if freeze_backbone:
        for param in model.parameters():
            param.requires_grad = False
    model.fc = nn.Linear(model.fc.in_features, NUM_CLASSES)
    return model


def unfreeze_resnet_last_block(model):
    for name, param in model.named_parameters():
        if name.startswith("layer4") or name.startswith("fc"):
            param.requires_grad = True


def build_efficientnet_b0(freeze_backbone=True):
    model = timm.create_model("efficientnet_b0", pretrained=True)
    if freeze_backbone:
        for param in model.parameters():
            param.requires_grad = False
    model.classifier = nn.Linear(model.classifier.in_features, NUM_CLASSES)
    for param in model.classifier.parameters():
        param.requires_grad = True
    return model


def unfreeze_efficientnet_last_block(model):
    for param in model.blocks[-1].parameters():
        param.requires_grad = True
    for param in model.classifier.parameters():
        param.requires_grad = True
