import os
import torch
from PIL import Image
from torch.utils.data import Dataset, DataLoader, Subset
from torchvision import transforms

CLASSES = ["recyclable", "organic", "e_waste", "hazardous"]
CLASS_INDEX = {c: i for i, c in enumerate(CLASSES)}

CONFIDENCE_HIGH = 0.80
CONFIDENCE_LOW = 0.50
FALLBACK_CLASS = "uncertain"


def get_transforms(train=True):
    if train:
        return transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomVerticalFlip(),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        ])
    return transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])


class FlatWasteDataset(Dataset):
    def __init__(self, root, transform=None):
        self.transform = transform
        self.samples = []
        for cls in sorted(os.listdir(root)):
            cls_dir = os.path.join(root, cls)
            if not os.path.isdir(cls_dir) or cls not in CLASS_INDEX:
                continue
            idx = CLASS_INDEX[cls]
            for fname in sorted(os.listdir(cls_dir)):
                if fname.lower().endswith((".jpg", ".jpeg", ".png", ".bmp", ".webp")):
                    self.samples.append((os.path.join(cls_dir, fname), idx, cls))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path, label, cls_name = self.samples[idx]
        img = Image.open(path).convert("RGB")
        if self.transform:
            img = self.transform(img)
        return img, label, cls_name


def collate_fn(batch):
    images, labels, names = zip(*batch)
    return torch.stack(images), torch.tensor(labels), list(names)


def get_dataloaders(data_root, batch_size=32, val_split=0.20, num_workers=4):
    train_ds = FlatWasteDataset(data_root, transform=get_transforms(train=True))
    val_ds   = FlatWasteDataset(data_root, transform=get_transforms(train=False))
    n_val    = int(len(train_ds) * val_split)
    indices  = torch.randperm(len(train_ds)).tolist()
    train_loader = DataLoader(
        Subset(train_ds, indices[n_val:]),
        batch_size=batch_size, shuffle=True,
        num_workers=num_workers, pin_memory=True, collate_fn=collate_fn,
    )
    val_loader = DataLoader(
        Subset(val_ds, indices[:n_val]),
        batch_size=batch_size, shuffle=False,
        num_workers=num_workers, pin_memory=True, collate_fn=collate_fn,
    )
    return train_loader, val_loader
