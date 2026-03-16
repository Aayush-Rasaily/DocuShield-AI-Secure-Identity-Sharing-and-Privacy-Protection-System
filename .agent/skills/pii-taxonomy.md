# PII Taxonomy — DocuShield AI

Defines exactly what counts as PII in this project, their regex patterns, validation rules,
masking strategies, and fraud flags. Always reference this before implementing any
detection, masking, extraction, or validation logic.

---

## Supported Document Types

| Document | Issuer | Key Identifiers |
|----------|--------|-----------------|
| Aadhaar Card | UIDAI / Government of India | 12-digit UID, name, DOB, address, QR code, photo |
| PAN Card | Income Tax Department | 10-char alphanumeric, name, DOB, photo |
| Passport | Ministry of External Affairs | Passport number, MRZ lines, name, DOB, nationality |
| Driving Licence | RTO / State Transport | DL number, name, DOB, address, vehicle class |

---

## PII Fields & Regex Patterns

### 1. Aadhaar Number
- **Format:** 12 digits, typically printed as `XXXX XXXX XXXX` (space-separated groups)
- **Regex:** `\b[2-9]{1}[0-9]{3}\s?[0-9]{4}\s?[0-9]{4}\b`
- **Notes:**
  - First digit is always 2–9 (never 0 or 1)
  - May appear with or without spaces
  - On masked Aadhaar (VID), only last 4 digits shown: `XXXX XXXX 1234`
- **Validation (Verhoeff checksum):** Must pass Verhoeff algorithm — flag if it fails

### 2. PAN Number
- **Format:** 10-character alphanumeric — `AAAAA9999A`
- **Regex:** `\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b`
- **Structure breakdown:**
  - Chars 1–3: Issuing AO code (alpha)
  - Char 4: Entity type (`P`=Person, `C`=Company, `H`=HUF, `F`=Firm, `A`=AOP, `B`=BOI, `G`=Govt, `J`=AJP, `L`=Local, `T`=Trust)
  - Char 5: First letter of surname (for individuals)
  - Chars 6–9: Sequential number
  - Char 10: Check character (alpha)
- **Notes:** Always uppercase; never lowercase in a valid PAN

### 3. Date of Birth (DOB)
- **Formats to match:**
  - `DD/MM/YYYY` → `\b(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}\b`
  - `DD-MM-YYYY` → same with `-`
  - `DD.MM.YYYY` → same with `.`
  - Written: `\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\b`
- **Context trigger:** Preceded by labels like `DOB`, `Date of Birth`, `जन्म तिथि`

### 4. Phone Number
- **Format:** 10-digit Indian mobile, optionally with `+91` or `0` prefix
- **Regex:** `(\+91[\-\s]?)?[6-9]\d{9}\b`
- **Notes:** First digit of 10-digit number must be 6–9 (Indian mobile range)

### 5. Address Block
- **No single regex** — detected via contextual proximity to keywords:
  - Trigger labels: `Address`, `Addr`, `पता`, `निवास`, `House No`, `Village`, `District`, `Pin`, `Pincode`
- **Pincode regex:** `\b[1-9][0-9]{5}\b`
- **Strategy:** Detect label → capture multi-line block until next field boundary

### 6. Name
- **Detection:** Contextual — text following labels `Name`, `नाम`, `S/O`, `D/O`, `W/O`, `C/O`
- **No standalone regex** (too many false positives)
- **On Aadhaar:** Appears twice — English + vernacular script

### 7. QR Code
- **Type:** Aadhaar QR contains encrypted XML with: UID, name, DOB, gender, address, photo
- **Detection:** Pyzbar library scan before OCR
- **Always mask QR** — treat as highest-sensitivity field; it contains ALL demographic data
- **Mismatch flag:** If QR-decoded UID ≠ OCR-extracted UID → flag as forgery

### 8. Photo / Face Region
- **Detection:** Face detection (OpenCV Haar cascade or MTCNN)
- **Bounding box:** Expand detected face bbox by 10px padding before masking
- **Deepfake check:** Run ResNext+LSTM model on photo region before any masking

---

## Sensitivity Tiers

| Tier | Fields | Default Masking Action |
|------|--------|----------------------|
| **Critical** | Aadhaar number, QR code, face photo | Full blur/pixelation |
| **High** | PAN number, DOB, phone number | Full blur/pixelation |
| **Medium** | Full address, pincode | Partial blur (pincode only, or full block) |
| **Low** | Name | Optional — user-configurable |

---

## Fraud / Fake PII Flags

These patterns indicate synthetic or tampered documents. When triggered, **halt processing and alert user** — do not mask.

### Aadhaar Fraud Flags
- Fails Verhoeff checksum
- All digits identical: `1111 1111 1111`
- Sequential digits: `1234 5678 9012`
- First digit is 0 or 1
- Same UID appears on multiple uploaded documents in a session
- QR-decoded UID does not match printed UID

### PAN Fraud Flags
- Does not match regex `[A-Z]{5}[0-9]{4}[A-Z]`
- Contains lowercase letters
- Char 4 (entity type) is not a valid code (not in `PCHABFGJLT`)
- Same PAN on multiple documents

### General Document Fraud Flags (from forgery detection module)
- ELA (Error Level Analysis) shows compression inconsistencies in text regions
- Font metrics differ between fields on same document
- Background texture inconsistent around text fields (indicates splicing)
- PSNR anomaly in specific zones

---

## OCR Pipeline Conventions

- **Engine:** Tesseract OCR
- **Confidence threshold:** 40 (drop extractions below this)
- **Output structure per token:**
  ```python
  {
    "text": str,
    "conf": float,        # 0–100
    "bbox": (x, y, w, h), # pixel coords on source image
    "page": int,
    "line": int
  }
  ```
- **PDF input:** Convert each page to image at ≥300 DPI before OCR
- **Preprocessing:** Grayscale → denoise → contrast enhance → deskew

---

## Masking Techniques

| Method | When to Use |
|--------|-------------|
| Gaussian Blur | Default for all PII regions; intensity user-configurable |
| Pixelation | Alternative to blur; better for QR codes |
| Black rectangle | High-security mode; no recovery possible |
| `XXXX` overlay | Name/partial masking; preserves document readability |

- **Blur intensity:** Exposed as UI slider (low / medium / high)
- **Masking target:** Bounding box from OCR token + 5px padding on each side
- **Never mask the document type label** (e.g., "Aadhaar", "PAN Card" header text)

---

## Metrics to Track per Document

| Metric | Definition |
|--------|------------|
| `compression_ratio` | Output file size / Input file size |
| `blur_ratio` | Average blur kernel size applied |
| `ocr_accuracy_drop` | OCR word count before vs. after masking |
| `psnr` | Peak Signal-to-Noise Ratio of masked image vs. original |
| `pii_fields_detected` | Count per type (aadhaar, pan, dob, phone, address, qr, face) |
| `fraud_flags` | List of triggered fraud conditions |

---

## Out of Scope (for this project)

- Voter ID, CGHS card, ration card — not in current scope
- Foreign passports — not in current scope (Indian documents only)
- Handwritten documents — OCR accuracy not guaranteed; flag and warn user
- Non-Indian phone numbers
