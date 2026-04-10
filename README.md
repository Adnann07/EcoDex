# 🌿 EcoDex

> A gamified waste classification mobile app powered by on-device machine learning. Scan items, learn how to dispose of them responsibly, earn points, and compete on the leaderboard.

---

## 🔗 Links

| Resource | URL |
|---|---|
| **Live API** | https://ecodex-production.up.railway.app |
| **GitHub Repository** | https://github.com/Adnann07/EcoDex |
| **ML Models & Training Code** | https://github.com/Adnann07/EcoDex/tree/ml-resnet-efficientnet |

---

## 📱 System Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Mobile App                  │
│                                                      │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────┐  │
│  │   Camera /  │   │  ONNX Model  │   │   API    │  │
│  │  Image Pick │──▶│  On-Device   │──▶│ Service  │  │
│  │             │   │  Classifier  │   │          │  │
│  └─────────────┘   └──────────────┘   └────┬─────┘  │
└───────────────────────────────────────────┼─────────┘
                                            │ HTTPS
                                            ▼
┌─────────────────────────────────────────────────────┐
│              Laravel API (Railway)                   │
│                                                      │
│  ┌───────────────┐        ┌──────────────┐           │
│  │ AuthController│        │   Sanctum    │           │
│  │  - register   │        │  Token Auth  │           │
│  │  - login      │        └──────────────┘           │
│  │  - scan       │        ┌──────────────┐           │
│  │  - history    │        │   MySQL DB   │           │
│  │  - leaderboard│        │  (Railway)   │           │
│  └───────────────┘        └──────────────┘           │
└─────────────────────────────────────────────────────┘
```

**On-device classification** — the ML model runs entirely on the user's phone using ONNX Runtime. No image is ever sent to the server. Only the classification result (label, confidence, category) is sent to the API to record the scan.

---

## 🧠 Machine Learning Models

Full training code, notebooks, and model files are available at:
**https://github.com/Adnann07/EcoDex/tree/ml-resnet-efficientnet**

Two deep learning models were fine-tuned on a merged waste dataset of **10,992 images** for 4-class waste classification.

### ResNet-50
- Pre-trained on ImageNet, fine-tuned with two-phase training
- **Validation Accuracy: 98.73%**
- Class-wise performance: Recyclable 99.36% · Organic 99.28% · E-Waste 93.33% · Hazardous 85.29%
- Final model size: 89.8 MB (ONNX, IR v8)

### EfficientNet-B0
- Fine-tuned via the `timm` library with two-phase training
- **Validation Accuracy: 98.00%**
- Class-wise performance: Recyclable 99.14% · E-Waste 96.77% · Organic 92.90% · Hazardous 58.62%
- Final model size: 15.7 MB (ONNX, IR v8)

### Waste Categories
| Label | Category |
|---|---|
| ♻️ Recyclable | Cardboard, glass, metal, paper, plastic |
| 🌿 Organic | Biological / compostable waste |
| 💻 E-Waste | Batteries and electronic components |
| ⚠️ Hazardous | Trash requiring special disposal |

### Training Methodology
- **Dataset:** Two public Kaggle datasets merged and remapped into a unified 4-class label space
- **Augmentation:** Random crop, horizontal/vertical flips, color jitter, random rotation
- **Phase 1:** Frozen backbone — 8 epochs, LR 1e-3, Adam optimizer
- **Phase 2:** Unfrozen last block — 4 epochs, LR 1e-4
- **Confidence routing:** High confidence (>80%) → direct prediction · Medium (50–80%) → flagged uncertain · Low (<50%) → fallback prompt

### ONNX Export
- Exported with opset version 17, dynamic batching support
- IR version downgraded v10 → v8 for ONNX Runtime mobile compatibility
- Input: `float32 [batch, 3, 224, 224]` (ImageNet normalized)
- Output: `float32 [batch, 4]` logits → softmax → argmax

---

## 🗄️ Database Schema

### `users`
| Column | Type | Description |
|---|---|---|
| id | bigint | Primary key |
| name | varchar | User's display name |
| email | varchar | Unique email |
| password | varchar | Hashed password |
| points | integer | Total points earned |
| total_scans | integer | Total items scanned |
| created_at | timestamp | |
| updated_at | timestamp | |

### `scan_history`
| Column | Type | Description |
|---|---|---|
| id | bigint | Primary key |
| user_id | bigint | Foreign key → users |
| item_name | varchar | Classification label |
| category | varchar | Full category string |
| emoji | varchar | Category emoji |
| confidence | integer | Model confidence % |
| points_earned | integer | Points awarded for this scan |
| created_at | timestamp | When scanned |
| updated_at | timestamp | |

### `personal_access_tokens`
Standard Laravel Sanctum token table for API authentication.

---

## 🔌 API Endpoints

**Base URL:** `https://ecodex-production.up.railway.app`

🔒 = Requires `Authorization: Bearer {token}` header

---

### POST `/api/register`
Register a new user.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**cURL:**
```bash
curl -X POST https://ecodex-production.up.railway.app/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123","password_confirmation":"password123"}'
```

---

### POST `/api/login`
Login and receive an auth token.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**cURL:**
```bash
curl -X POST https://ecodex-production.up.railway.app/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

---

### POST `/api/scan` 🔒
Record a scan and award points to the user.

**Request:**
```json
{
  "item_name": "Recyclable",
  "category": "♻️ Recyclable Waste",
  "emoji": "♻️",
  "confidence": 94
}
```

**Response:**
```json
{
  "success": true,
  "points": 130
}
```

**cURL:**
```bash
curl -X POST https://ecodex-production.up.railway.app/api/scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"item_name":"Recyclable","category":"♻️ Recyclable Waste","emoji":"♻️","confidence":94}'
```

---

### GET `/api/scan/history` 🔒
Get the authenticated user's scan history (latest 50).

**Response:**
```json
{
  "success": true,
  "history": [
    {
      "id": 1,
      "item_name": "Recyclable",
      "category": "♻️ Recyclable Waste",
      "emoji": "♻️",
      "confidence": 94,
      "points_earned": 10,
      "created_at": "2026-04-11T10:23:00.000000Z"
    }
  ]
}
```

**cURL:**
```bash
curl -X GET https://ecodex-production.up.railway.app/api/scan/history \
  -H "Authorization: Bearer {token}"
```

---

### GET `/api/leaderboard`
Get the top 50 users ranked by points. Public, no auth required.

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": 1,
      "name": "John Doe",
      "points": 250,
      "total_scans": 25
    }
  ]
}
```

**cURL:**
```bash
curl -X GET https://ecodex-production.up.railway.app/api/leaderboard
```

---

## 🏗️ Project Structure

```
EcoDex/
├── backend/                          # Laravel API
│   ├── app/
│   │   ├── Http/Controllers/Api/
│   │   │   └── AuthController.php    # All API logic
│   │   └── Models/
│   │       ├── User.php
│   │       └── ScanHistory.php
│   ├── database/migrations/
│   ├── routes/
│   │   └── api.php
│   └── Dockerfile
├── lib/                              # Flutter app
│   ├── main.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── ecodex_screen.dart            # Main scanner UI
│   ├── waste_classifier.dart         # ONNX inference
│   └── api_service.dart              # API calls
└── assets/
    └── models/
        ├── waste_classifier_v8.onnx  # ResNet-50 (89.8 MB)
        └── efficientnet_v8.onnx      # EfficientNet-B0 (15.7 MB)
```

> ML training notebooks and model export scripts are in the
> [`ml-resnet-efficientnet`](https://github.com/Adnann07/EcoDex/tree/ml-resnet-efficientnet) branch.

---

## 🚀 Deployment

Deployed on **Railway** with automatic migrations on every push.

- **Runtime:** Docker (PHP + Laravel)
- **Database:** MySQL (Railway managed)
- **Start command:** `php artisan config:clear && php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8080`

---

## 💡 Strategy

EcoDex addresses improper waste disposal by making recycling education engaging through gamification:

1. **On-device machine learning** — classification runs on the phone using ONNX Runtime, making it fast, private, and offline-capable. No images leave the device.
2. **Gamification** — users earn points per scan and compete on a live leaderboard, driving repeat engagement.
3. **Education** — every scan result includes a contextual eco tip explaining how to properly dispose of the identified item.
4. **History tracking** — users can review all past scans with confidence scores, building awareness over time.
