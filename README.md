# DocuShield AI 🛡️

> AI-Based Identity Document Protection and Secure Sharing System

DocuShield AI automatically detects sensitive fields in identity documents (Aadhaar, PAN, Passport, DL), masks confidential data, verifies document authenticity, and enables secure sharing — using OCR, ML, and Computer Vision.

---

## Features

- 📄 **OCR Extraction** — Extract text and fields from identity documents
- 🔍 **PII Detection** — Detect sensitive fields (ID number, DOB, address) using AI
- 🖊️ **Data Masking** — Mask confidential information before sharing
- 🧪 **Forgery / Deepfake Detection** — Verify document authenticity
- 🔗 **Secure Sharing** — Watermark / QR-based verified document sharing

---

## Project Structure

```
DocushieldAI/
├── data/
│   ├── raw/            # Original document samples (never commit real docs)
│   ├── processed/      # Preprocessed images/text
│   └── samples/        # Synthetic/anonymized test samples
├── src/
│   ├── ocr/            # OCR pipeline (extraction)
│   ├── masking/        # PII detection & masking logic
│   ├── detection/      # Forgery & deepfake detection
│   ├── sharing/        # Secure sharing, watermarking, QR
│   └── utils/          # Shared helpers
├── models/             # Trained model weights (gitignored if large)
├── notebooks/          # Jupyter notebooks for experiments
├── tests/              # Unit & integration tests
├── docs/               # Documentation, research references
├── scripts/            # Setup, training, inference scripts
├── .gitignore
├── requirements.txt
├── CONTRIBUTING.md
└── README.md
```

---

## Tech Stack

| Area | Tools |
|---|---|
| OCR | Tesseract, EasyOCR, PaddleOCR |
| ML / CV | PyTorch / TensorFlow, OpenCV |
| PII Detection | spaCy, Regex, custom NER |
| Forgery Detection | CNN-based classifiers, ELA (Error Level Analysis) |
| Backend (planned) | FastAPI |
| Frontend (planned) | React / Streamlit |

---

## Getting Started

```bash
git clone https://github.com/Manzil777/DocushieldAI.git
cd DocushieldAI
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full team workflow, branch strategy, commit conventions, and PR rules.

---

## Contributors

- [@Manzil777](https://github.com/Manzil777)
- [@Aayush-Rasaily](https://github.com/Aayush-Rasaily)

---

## License

MIT
