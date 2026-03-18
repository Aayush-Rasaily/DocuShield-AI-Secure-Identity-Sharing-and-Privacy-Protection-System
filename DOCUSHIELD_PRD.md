# DocuShield AI — Product Requirements Document
**Version:** 1.0.0  
**Date:** 2026-03-16  
**Author:** CMRIT — AI & DS Dept, Project Phase 1 (BAD685)  
**Status:** Draft — Ready for Phase 1 Development

---

## 1. Executive Summary

DocuShield AI is a React Native mobile application that enables citizens of India (and Nepal, future scope) to **upload identity documents, automatically detect and selectively mask sensitive PII fields using AI/OCR, store documents in a secure personal vault, and share controlled versions via time-limited links, QR codes, or one-time downloadable masked PDFs** — without ever exposing raw document data to the recipient.

The core problem: hotels, SIM vendors, printing shops, and KYC counters routinely photocopy or digitally store Aadhaar, PAN, and other ID cards in full. Once a copy leaves the user's hands, there is zero control over how it is stored or reused. DocuShield inverts this dynamic — the user decides exactly what a recipient can see, and for how long.

---

## 2. Problem Statement

### 2.1 Background
In India, over 1.4 billion Aadhaar cards are in circulation. Holders routinely share photocopies or digital images with hotels, SIM vendors, banks, cyber cafés, and other organizations for KYC/verification. These copies are stored insecurely, often indefinitely, with no audit trail and no user consent mechanism.

Key risks identified:
- **Full PII exposure**: Every copy includes the 12-digit Aadhaar number, address, DOB, and the embedded QR code (which contains the full data payload).
- **Unlimited reuse**: Copies can be photocopied again, stored digitally, or used to impersonate the owner.
- **No revocation**: Unlike passwords, Aadhaar numbers cannot be changed if compromised.
- **Document forgery**: Modified documents are increasingly difficult to detect visually.

### 2.2 Research Gap (from literature review)
Existing systems (NetraAadhaar, Mero Nagarikta, Hybrid OCR-Regex PII tool) focus on **extraction and recognition** of identity fields, not on **user-controlled selective masking + secure sharing**. No production mobile product combines all of:
- AI field detection (YOLOv8-class accuracy)
- Selective per-field masking with user control
- Time-bounded shareable output (link + QR + PDF)
- Document forgery detection before masking
- Persistent vault with accounts

---

## 3. Goals & Non-Goals

### 3.1 Goals (v1 — Phase 1 scope)
- [ ] Aadhaar card upload + automatic PII field detection
- [ ] Selective masking UI (user toggles each field on/off)
- [ ] Generate shareable output: time-limited link, QR code, one-time masked PDF
- [ ] User accounts with encrypted document vault
- [ ] Document authenticity check (forgery/deepfake flag) before vault storage
- [ ] Masked Aadhaar number display: show last 4 digits only (XXXX XXXX 1234)

### 3.2 Non-Goals (v1)
- PAN card, Driving License, Passport support (v2 roadmap)
- Nepali Citizenship Certificate (v2 — Mero Nagarikta pipeline exists as reference)
- Biometric verification (face match)
- Government DigiLocker integration
- Offline-only mode (requires internet for vault sync and share links)

---

## 4. Users & Use Cases

### 4.1 Primary User
**Aadhaar Card Holder** — a citizen (18–60 years, smartphone user) who regularly needs to share their Aadhaar for hotel check-in, SIM purchase, bank KYC, or cyber café access.

### 4.2 Primary Use Cases

| # | Actor | Scenario | DocuShield Action |
|---|-------|----------|-------------------|
| UC-01 | User | Hotel check-in requires Aadhaar | Upload → auto-mask address & full Aadhaar → share QR; front desk scans to see name + last 4 digits only |
| UC-02 | User | SIM vendor needs Aadhaar copy | Generate time-limited link (expires in 24h); vendor accesses once and cannot re-access |
| UC-03 | User | Bank KYC requires full Aadhaar | User chooses to unmask all fields → share one-time PDF |
| UC-04 | User | Wants to store Aadhaar securely | Upload → vault stores encrypted original + masked versions |
| UC-05 | User | Suspects a doc shared earlier is being misused | Check share log → see when link was accessed → revoke active links |

---

## 5. Technical Architecture

### 5.1 System Overview

```
React Native App
      │
      ├── Camera / Gallery (document capture)
      │
      ▼
AI Processing Pipeline (on-device + server hybrid)
      │
      ├── Pre-processing: grayscale, denoise, skew-correct, edge detect
      ├── Field Detection: YOLOv8 (Aadhaar fields — 5 classes)
      │     Classes: AadhaarNumber, Name, DOB, Gender, Address
      │     Reference accuracy: mAP-50 = 0.925 (NetraAadhaar, IEEE Access 2025)
      ├── OCR: Tesseract (selected over EasyOCR / Google Vision for offline privacy)
      ├── Forgery Detection: CNN + ELA (Error Level Analysis)
      └── QR Code masking: detect + blur QR region
      │
      ▼
Selective Masking UI
      │
      ├── User toggles per-field visibility
      ├── Aadhaar number: always default to "XXXX XXXX 1234" (partial unmask option)
      └── Preview renders masked document image
      │
      ▼
Sharing Engine
      ├── Time-limited link (1h / 6h / 24h / custom)
      ├── QR code (encodes the time-limited link)
      └── One-time downloadable masked PDF
      │
      ▼
Backend (FastAPI + PostgreSQL + S3-compatible storage)
      ├── Auth (JWT + refresh tokens)
      ├── Document Vault (AES-256 encrypted at rest)
      ├── Share token generation + expiry
      └── Access logs (for each share event)
```

### 5.2 AI Pipeline Detail

#### Field Detection — YOLOv8
- Model: YOLOv8-small (fine-tuned on Aadhaar dataset)
- Input: 640×640 preprocessed image
- Output: bounding boxes + class labels for 5 fields
- Reference performance (NetraAadhaar, IEEE Access 2025):

| Field | mAP-50 | Text Recognition Accuracy |
|-------|--------|--------------------------|
| Aadhaar Number | 96.6% | 91.5% |
| Name | 95.2% | 93.5% |
| DOB | 92.1% | 82.2% |
| Gender | 95.3% | 90.3% |
| Address | 83.4% | 76.3% |
| **Overall** | **92.5%** | **87.8%** |

> Note: Address class underperforms due to format variability. Post-processing (regex + RapidFuzz) required for normalization (ref. Mero Nagarikta, IOE Tribhuvan University 2024).

#### OCR — Tesseract
Selected over alternatives based on research comparison (NetraAadhaar Table 5):

| Tool | Offline | Free | Privacy | GPU Needed |
|------|---------|------|---------|------------|
| **Tesseract** ✓ | Yes | Yes | High | No |
| EasyOCR | Yes | Yes | High | Recommended |
| Google Vision | No | No | Cloud | No |
| AWS Textract | No | No | Cloud | No |

Tesseract configured with Aadhaar-specific page segmentation mode (PSM 6 or PSM 11 depending on field region).

#### Forgery Detection — CNN + ELA
- **Error Level Analysis (ELA)**: Identifies manipulated regions via JPEG compression inconsistencies
- **CNN classifier**: Trained on real vs. fake Aadhaar dataset (ref: IJRTI 2025 review — 4,000 image dataset, 88% accuracy with LBP+HOG+LPQ features)
- **QR code validation**: OCR-extracted text compared against QR payload; mismatch flags forgery

#### Pre-processing Pipeline
Based on Mero Nagarikta (IOE, 2024) preprocessing approach:
1. Grayscale conversion (reduces model complexity)
2. Gaussian blur (noise reduction)
3. Canny edge detection (boundary isolation)
4. Perspective transformation / skew correction
5. Normalization (0–1 pixel intensity range)

### 5.3 Tech Stack

| Layer | Technology | Justification |
|-------|-----------|---------------|
| Mobile App | React Native (Expo) | User's choice; cross-platform |
| AI Inference | Python (FastAPI) + ONNX runtime | YOLOv8 exported to ONNX for mobile-compatible inference |
| OCR | Tesseract 5.x (pytesseract wrapper) | Offline, free, proven on Aadhaar |
| Backend API | FastAPI + Uvicorn | Async, fast, Python-native (same language as AI pipeline) |
| Auth | JWT + bcrypt | Standard secure auth |
| Database | PostgreSQL | Relational, ACID, supports encrypted fields |
| File Storage | MinIO (self-hosted S3-compatible) | Full control over document data |
| Encryption | AES-256-GCM (vault), TLS 1.3 (transit) | Industry standard |
| Share Links | UUID v4 tokens + Redis TTL | Expiry-based access control |
| PDF Generation | ReportLab / WeasyPrint | Masked PDF output |
| QR Generation | python-qrcode | Share QR encoding |
| Image Processing | OpenCV | Pre-processing pipeline |

---

## 6. Feature Specifications

### 6.1 F-01: Document Upload & Capture
- User can take a photo with camera or upload from gallery
- App validates: file type (JPG/PNG), minimum resolution (300 DPI equivalent), blur score
- If image is rejected: display reason + re-upload prompt
- Support for both physical card (laminated) and e-Aadhaar (PDF screenshot) formats

### 6.2 F-02: AI Field Detection
- On upload, image sent to AI pipeline (server-side in v1)
- YOLOv8 draws bounding boxes over: AadhaarNumber, Name, DOB, Gender, Address
- QR code region detected separately (special handling — full mask by default)
- User sees detected fields highlighted with labels
- If detection fails or confidence < 60%: show manual field marking UI as fallback

### 6.3 F-03: Forgery / Authenticity Check
- ELA scan runs automatically on upload
- CNN classification: Real / Suspicious / Fake
- QR payload vs. printed text cross-validation
- Result shown as: ✅ Authentic / ⚠️ Suspicious / ❌ Likely Forged
- Documents flagged as Fake: vault storage disabled, user warned
- Forgery flag does NOT block user from proceeding (user may have legitimate partial/redacted doc)

### 6.4 F-04: Selective Masking UI
- Screen shows document preview with each detected field overlaid
- Per-field toggle: Show / Mask / Partial
- Aadhaar Number: default = "XXXX XXXX 1234" (partial), options: Full Mask / Show All
- Address: default = Masked, options: Show PIN only / Show Full
- DOB: default = Show year only (e.g., "1995"), option: Show full / Mask
- QR Code: default = Masked (always), option: Show (advanced, with confirmation)
- Preview updates in real-time as toggles change
- "Save Preset" option: save masking configuration for reuse

### 6.5 F-05: Share Output Generation
Three output types, generated from the current masking configuration:

**a) Time-Limited Shareable Link**
- Generates a unique URL: `docushield.app/s/{token}`
- Expiry options: 1 hour / 6 hours / 24 hours / 7 days
- Link displays the masked document image (non-downloadable by default)
- Link access count tracked; user can revoke at any time
- One-time access option: link auto-expires after first view

**b) QR Code**
- Encodes the time-limited link
- Displayed full-screen for front desk / vendor to scan
- Auto-refreshes if link has expired

**c) One-Time Masked PDF**
- ReportLab-generated PDF of the masked document
- Embedded metadata: "Shared via DocuShield AI | Valid for single use | {timestamp}"
- Watermark: "COPY — NOT FOR REUSE" overlaid diagonally
- Single download, then link expires

### 6.6 F-06: Document Vault
- Authenticated users can save documents to vault
- Vault stores: encrypted original + user's masking presets + share history
- AES-256-GCM encryption; key derived from user's password (PBKDF2)
- Max vault size: 50 MB (v1), 500 MB (premium tier)
- Share log: per-document list of all links generated, access timestamps, recipient IP

### 6.7 F-07: User Auth & Accounts
- Email + password registration
- OTP verification on registration (SMS or email)
- JWT access tokens (15 min) + refresh tokens (7 days)
- Biometric login (device FaceID / fingerprint) via React Native Biometrics
- Account deletion: full data purge within 24h (DPDP Act compliance)

---

## 7. Data Privacy & Security Requirements

### 7.1 Regulatory Compliance
- **DPDP Act 2023 (India)**: Explicit consent before vault storage; user can delete all data
- **Aadhaar Act 2016**: No storage of full Aadhaar numbers without UIDAI authorization — DocuShield stores only masked versions in logs; original encrypted in vault accessible only to user
- No third-party sharing of document data
- No analytics on document content

### 7.2 Security Controls
- All API endpoints: HTTPS (TLS 1.3 only)
- Document images: never logged in server logs
- Vault encryption: client-side key derivation (server never holds plaintext)
- Share tokens: cryptographically random UUID v4, stored as bcrypt hash
- Rate limiting on share link generation (10 links/hour per user)
- Document retention: auto-delete from server after PDF download or link expiry

---

## 8. UI/UX Requirements

### 8.1 Screen Map
```
Onboarding
  └── Auth (Login / Register / Biometric)
        │
        ├── Home (Vault)
        │     ├── Upload New Document
        │     └── Saved Documents list
        │
        ├── Upload Flow
        │     ├── Camera / Gallery picker
        │     ├── Image quality check
        │     ├── AI Processing (loader: "Detecting fields…")
        │     ├── Forgery check result
        │     └── Masking UI → Share options
        │
        ├── Share Screen
        │     ├── Time-limited link + copy
        │     ├── QR Code (fullscreen)
        │     └── Download masked PDF
        │
        └── Document Detail
              ├── Masking presets
              └── Share log (access history)
```

### 8.2 Design Principles
- Minimal friction: upload to share in ≤ 4 taps
- Trust indicators: always show authenticity badge and masking status
- Hindi/English bilingual (v1); regional language support in v2
- Dark mode support
- Accessible: minimum touch target 44×44 pt, screen reader labels

---

## 9. Non-Functional Requirements

| NFR | Requirement | Target |
|-----|-------------|--------|
| Performance | End-to-end upload → masked preview | < 8 seconds on 4G |
| AI Inference | YOLOv8 field detection | < 3 seconds server-side |
| Uptime | Backend availability | 99.5% (v1) |
| Scalability | Concurrent users | 1,000 (v1), horizontally scalable |
| Storage | Document retention post-share expiry | Delete within 1 hour of expiry |
| Offline | Core vault browsing | Yes (cached, read-only) |

---

## 10. Milestones & Phase Plan

### Phase 1 (Current — BAD685 Project)
| Milestone | Deliverable | Target |
|-----------|-------------|--------|
| M1 | YOLOv8 model fine-tuned on Aadhaar dataset | Week 4 |
| M2 | OCR + masking pipeline (Python) | Week 6 |
| M3 | FastAPI backend: auth + vault + share tokens | Week 8 |
| M4 | React Native app: upload + masking UI | Week 10 |
| M5 | Share output: link + QR + PDF | Week 12 |
| M6 | Forgery detection integrated | Week 14 |
| M7 | End-to-end integration + testing | Week 16 |

### Phase 2 (Future)
- PAN card, Driving License support
- Nepali Citizenship Certificate (YOLOv8 pipeline from Mero Nagarikta as base)
- DigiLocker integration
- On-device inference (ONNX + Core ML / TFLite)
- Multilingual OCR (Hindi, Tamil, Telugu, Nepali)

---

## 11. Research Foundation

This PRD is grounded in the following papers reviewed for Phase 1:

1. **NetraAadhaar** — Patil, Khan, Mollah (VIT-AP / Aliah University, IEEE Access 2025). YOLOv8 + Tesseract pipeline achieving mAP-50 of 92.5% on 5 Aadhaar field classes. Validated YOLOv8 as the detection backbone and Tesseract as OCR engine.

2. **Mero Nagarikta** — Dhakal et al. (IOE Tribhuvan University, 2024). YOLOv8 + PyTesseract on Nepali citizenship cards; 99.1% mAP front model. Flutter + Django REST Framework architecture validated. Informs v2 Nepal scope.

3. **Hybrid OCR and Regex-based PII Detection and Masking Tool** — Dharamveer et al. (GECA Ajmer, IJARIIE 2025). Tesseract + Regex for PII detection, deepfake detection integration, PSNR-based quality metrics. Informs masking quality measurement and GUI design.

4. **A Review: Fake Aadhaar Card Detection Using Machine Learning** — Devane et al. (JSPM RSCE Pune, IJRTI 2025). CNN + ELA + Histogram method for forgery detection. 4,000-image dataset methodology. Informs F-03 forgery detection module design.

---

## 12. Open Questions / Risks

| # | Risk | Mitigation |
|---|------|------------|
| R1 | Aadhaar dataset privacy — cannot use real Aadhaar images for training | Use synthetic/generated Aadhaar templates + augmentation (ref: Roboflow dataset used by NetraAadhaar) |
| R2 | Address field detection accuracy (76.3%) may be insufficient | Post-processing with regex + RapidFuzz fuzzy matching; manual fallback UI |
| R3 | On-device inference too slow for React Native in v1 | Server-side inference in v1; ONNX on-device in v2 |
| R4 | UIDAI legal concerns around Aadhaar number storage | Store only masked versions; original encrypted with user-controlled key |
| R5 | Share link screenshot bypass (recipient screenshots the masked doc) | Watermarking + usage logging; cannot prevent screenshots (known limitation) |
| R6 | Multi-language Aadhaar cards (Hindi + English + regional) | Tesseract multi-language model (hin+eng); tested in NetraAadhaar |

---

## 13. GSD Workflow — AI Agent Execution Protocol

> This section governs how any AI agent (Claude or otherwise) must implement features in this codebase. It exists to prevent hallucination, scope bleed, and untestable changes.

### 13.1 Why This Exists

AI agents fail on coding tasks in predictable ways:
- They implement more than asked (scope bleed into adjacent files)
- They invent function signatures without reading what already exists
- They write code that "looks right" but can't be verified (no acceptance test)
- They bundle multiple concerns into one change (impossible to debug)

The GSD protocol enforces one simple rule: **one task = one file = one function, with a read-before-write gate and a runnable acceptance test before marking done.**

### 13.2 Task Contract Template

Every implementation task in this project must be expressed as a Task Contract before any code is written. The canonical template lives in `.agent/GETSHITDONE.md`. The structure is:

```
TASK [ID]: [Name]
├── Status:          TODO | IN_PROGRESS | DONE | BLOCKED
├── File:            exactly one file path
├── Symbol:          exactly one function or class name
├── Depends on:      [IDs of prerequisite tasks]
│
├── 1. READ FIRST    ← mandatory, never skipped
│   └── List every file that must be read before writing
│
├── 2. WRITE EXACTLY THIS
│   └── Precise input/output contract, error cases, nothing else
│
├── 3. DO NOT TOUCH
│   └── Explicit list of files/functions that are out of scope
│
├── 4. ACCEPTANCE CRITERIA
│   └── Runnable test command that must pass before marking DONE
│
└── 5. COMMIT CHECKPOINT
    └── Exact commit message, one commit per task
```

### 13.3 Atomic Scope Rules

These rules apply to every task, no exceptions:

| Rule | What it prevents |
|------|-----------------|
| One task touches exactly one file | Scope bleed into unrelated modules |
| Always read the target file before writing | Inventing signatures that conflict with existing code |
| Never implement beyond the symbol specified | "While I'm here" refactors that break other things |
| Every task has a runnable test command | Silent failures that look done but aren't |
| One commit per task | Entangled changes that are impossible to revert |
| Never mark DONE without running the acceptance test | False completion signals |

### 13.4 Task Execution Sequence (Phase 1)

The full task list with contracts is in `.agent/GETSHITDONE.md`. Tracks:

```
Track A — AI/ML Pipeline:
  A-01 preprocess_image
  A-02 extract_field_text + FIELD_PATTERNS
  A-03 detect_fields (ONNX)
  A-04 run_pipeline (orchestrator)
  A-05 post_process_field (regex)
  A-06 compute_ela_score
  A-07 validate_qr_payload
  A-08 get_forgery_verdict

Track B — Backend API:
  B-01 Settings config
  B-02 DB session
  B-03 User model
  B-04 Document model
  B-05 ShareToken model
  B-06 Alembic migration
  B-07 JWT + bcrypt utils
  B-08 get_current_user dep
  B-09 Auth endpoints
  B-10 Upload endpoint
  B-11 apply_masking
  B-12 generate_masked_pdf
  B-13 Share token manager
  B-14 Public share endpoint

Track C — Mobile:
  C-01 SessionProvider
  C-02 Protected vault layout
  C-03 API client (axios)
  C-04 Capture screen
  C-05 Processing screen
  C-06 Masking UI screen
  C-07 Share output screen
  C-08 Vault list screen

Track D — Integration:
  D-01 E2E smoke test
  D-02 Performance benchmark
```

### 13.5 Parallelism Rules

Tracks A and B (foundation tasks B-01 to B-06) can start in parallel from day 1.
Track C cannot start until B-09 (auth endpoints) is DONE.
Track D cannot start until all A, B, C tasks are DONE.

Within each track, tasks are strictly sequential — do not begin task N+1 until task N passes its acceptance test.

### 13.6 What "DONE" Means

A task is DONE when and only when:
1. The acceptance test command from Step 4 was run and passed
2. The status in `.agent/INDEX.md` is updated to `DONE`
3. The commit from Step 5 is in git history
4. No other files were modified beyond the one specified in the contract

If any of these four conditions is not met, the task is `IN_PROGRESS`, not `DONE`.
