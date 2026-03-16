#!/usr/bin/env bash
# =============================================================================
# scripts/issues_seed.sh — Bulk roadmap issue creation for DocushieldAI
# =============================================================================
#
# USAGE:
#   1. Authenticate once:
#        gh auth login
#      (choose GitHub.com → HTTPS → authenticate in browser as Manzil777)
#
#   2. Run from repo root:
#        bash scripts/issues_seed.sh
#
#   3. Verify results:
#        https://github.com/Manzil777/DocushieldAI/issues
#
# WHAT THIS SCRIPT DOES:
#   - Creates the 34 remaining roadmap issues (skips the already-created
#     "Week 1: Download Aadhaar dataset from Roboflow" issue).
#   - Uses milestone TITLES (not numeric IDs) so no ID-mapping is required.
#   - Checks for duplicate titles (open + closed) before creating each issue.
#   - Prints [skip] / [ok] / [FAIL] for each issue.
#
# REQUIREMENTS:
#   - gh CLI installed (https://cli.github.com/)
#   - Authenticated as a collaborator with write access to Manzil777/DocushieldAI
#   - Both Manzil777 and Aayush-Rasaily must be repo collaborators for
#     assignment to succeed.
#
# MILESTONES (must already exist in the repo):
#   - Week 1 — AI Pipeline Foundation
#   - Week 2 — Backend Core + Model Tuning
#   - Week 3 — Mobile UI + Sharing Engine
#   - Week 4 — Integration, Testing, Demo
#
# DEPENDENCY REFERENCES:
#   Issue bodies reference other tasks by their roadmap task names.
#   These are informational only and will not auto-link as GitHub issue
#   numbers (since actual GitHub issue #N may differ from roadmap task #N).
#
# =============================================================================

set -euo pipefail

REPO="Manzil777/DocushieldAI"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Fetch all existing issue titles (open + closed) once at startup
EXISTING_TITLES=""

refresh_titles() {
  EXISTING_TITLES="$(
    gh issue list \
      --repo "$REPO" \
      --state all \
      --limit 200 \
      --json title \
      --jq '.[].title'
  )"
}

# Returns 0 if title exists, 1 if not
title_exists() {
  echo "$EXISTING_TITLES" | grep -qxF "$1"
}

# create_issue <title> <body> <comma-labels> <milestone> <assignee>
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local milestone="$4"
  local assignee="$5"

  if title_exists "$title"; then
    echo "  [skip] $title"
    return
  fi

  local label_flags=()
  IFS=',' read -ra lbl_array <<< "$labels"
  for lbl in "${lbl_array[@]}"; do
    label_flags+=(--label "$lbl")
  done

  if gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      "${label_flags[@]}" \
      --milestone "$milestone" \
      --assignee "$assignee" \
      > /dev/null 2>&1; then
    echo "  [ok]   $title"
    EXISTING_TITLES="${EXISTING_TITLES}"$'\n'"${title}"
  else
    echo "  [FAIL] $title" >&2
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo "======================================================================"
echo "DocushieldAI — Roadmap Issue Seed"
echo "Repository : $REPO"
echo "======================================================================"
echo ""
echo "Fetching existing issue titles..."
refresh_titles
echo "Starting issue creation..."
echo ""

M1="Week 1 — AI Pipeline Foundation"
M2="Week 2 — Backend Core + Model Tuning"
M3="Week 3 — Mobile UI + Sharing Engine"
M4="Week 4 — Integration, Testing, Demo"
AI="Manzil777"
BM="Aayush-Rasaily"

echo "── Week 1 ──────────────────────────────────────────────────────────"

# Task 1 is already issue #2 in the repo — skip intentionally
echo "  [skip] Week 1: Download Aadhaar dataset from Roboflow (pre-created as issue #2)"

# ── Task 2 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Create a YOLOv8-compatible dataset YAML configuration file and verify all class labels are correctly defined.

## Implementation Details
- Create `data/aadhaar/dataset.yaml` with `train`, `val`, `nc`, and `names` fields
- Verify 5 class labels match dataset annotations (e.g., name, dob, uid, gender, address)
- Validate YAML against YOLOv8 schema
- Run a quick sanity check: load YAML + count labels per class

## Acceptance Criteria
- [ ] `dataset.yaml` created with correct paths
- [ ] `nc` field matches actual class count
- [ ] All class names verified against annotation files
- [ ] YAML loads without errors in Ultralytics CLI

## Dependencies / Blockers
- Depends on: Week 1 — Download Aadhaar dataset from Roboflow
EOF
create_issue "Week 1: Create dataset YAML and verify class labels" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 3 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Train a YOLOv8-small model on the Aadhaar dataset for 100 epochs to establish a baseline mAP-50 score.

## Implementation Details
- Use `ultralytics` Python package
- Model: `yolov8s.pt` (small variant)
- Epochs: 100, Image size: 640
- Save best weights to `models/best.pt`
- Log training metrics (loss, mAP-50) with MLflow or W&B

## Acceptance Criteria
- [ ] Training completes 100 epochs without error
- [ ] `best.pt` saved to `models/` directory
- [ ] mAP-50 baseline score recorded
- [ ] Training logs available for review

## Dependencies / Blockers
- Depends on: Week 1 — Create dataset YAML and verify class labels
EOF
create_issue "Week 1: Run baseline YOLOv8-small training (100 epochs)" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 4 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement data augmentation techniques to improve model robustness for real-world Aadhaar card scanning conditions.

## Implementation Details
- Augmentations: glare simulation, motion/gaussian blur, perspective skew, random crop
- Use Albumentations or torchvision transforms
- Configure augmentation pipeline in `src/augmentation.py`
- Apply augmentations in YOLOv8 training config (`augment: True`, custom `hyp.yaml`)
- Test augmented batch visually

## Acceptance Criteria
- [ ] All 4 augmentation types implemented
- [ ] Augmentation pipeline tested on sample batch
- [ ] Visual verification of augmented images complete
- [ ] Augmentations integrated with YOLOv8 training

## Dependencies / Blockers
- Depends on: Week 1 — Create dataset YAML and verify class labels
EOF
create_issue "Week 1: Add data augmentation: glare, blur, skew, crop" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 5 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build a robust preprocessing pipeline using OpenCV to normalize Aadhaar card images before model inference and OCR.

## Implementation Details
- Steps: resize to 640x640, grayscale conversion, adaptive thresholding, deskew, contrast enhancement (CLAHE)
- Implement in `src/preprocessing.py`
- Pipeline must handle JPEG, PNG, and PDF (first page)
- Return standardized numpy array

## Acceptance Criteria
- [ ] Pipeline handles JPEG and PNG inputs
- [ ] All preprocessing steps implemented in `src/preprocessing.py`
- [ ] Output image meets YOLOv8 input requirements
- [ ] Pipeline tested on 10+ sample images

## Dependencies / Blockers
- None
EOF
create_issue "Week 1: Implement preprocessing pipeline in OpenCV" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 6 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Integrate Tesseract OCR to extract text from detected Aadhaar card field regions with support for Hindi and English.

## Implementation Details
- Install `pytesseract` + Tesseract binary with `hin` and `eng` language packs
- Crop detected bounding boxes from YOLO output
- Run OCR on each cropped region with `lang='hin+eng'`
- Return structured dict: `{field_class: extracted_text}`
- Implement in `src/ocr.py`

## Acceptance Criteria
- [ ] Tesseract installed with Hindi + English language packs
- [ ] OCR runs on cropped bounding boxes
- [ ] Returns structured dict with field -> text mapping
- [ ] Hindi text extraction verified on sample images
- [ ] English text extraction verified on sample images

## Dependencies / Blockers
- Depends on: Week 1 — Implement preprocessing pipeline in OpenCV
- Depends on: Week 1 — Run baseline YOLOv8-small training (100 epochs)
EOF
create_issue "Week 1: Integrate Tesseract OCR (lang: hin+eng)" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 7 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build a regex-based post-processing module that validates and normalizes OCR output for each Aadhaar card field class.

## Implementation Details
- Fields: UID (12-digit number), DOB (DD/MM/YYYY), Name (Title Case), Gender (Male/Female/Other), Address (multi-line)
- Implement in `src/postprocessor.py`
- Each field has its own regex pattern and normalization function
- Return cleaned, validated values; flag uncertain matches

## Acceptance Criteria
- [ ] Regex patterns defined for all 5 field classes
- [ ] UID validated as 12-digit number
- [ ] DOB normalized to DD/MM/YYYY format
- [ ] Uncertain matches flagged with confidence score
- [ ] Unit tests pass for each field pattern

## Dependencies / Blockers
- Depends on: Week 1 — Integrate Tesseract OCR (lang: hin+eng)
EOF
create_issue "Week 1: Build regex post-processor for each field class" "$BODY" "ai,week-1" "$M1" "$AI"

# ── Task 8 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Initialize the FastAPI backend project with a Docker Compose setup for local development.

## Implementation Details
- Create `backend/` directory with FastAPI project structure
- Services in `docker-compose.yml`: api (FastAPI), db (PostgreSQL), redis (Redis), minio (MinIO)
- FastAPI app with basic health check endpoint: `GET /health`
- Environment variables via `.env` file (template: `.env.example`)
- Hot-reload enabled in development mode

## Acceptance Criteria
- [ ] `docker-compose up` starts all services without errors
- [ ] `GET /health` returns `{"status": "ok"}`
- [ ] PostgreSQL, Redis, MinIO containers start and are accessible
- [ ] `.env.example` documents all required environment variables
- [ ] Hot-reload works for FastAPI code changes

## Dependencies / Blockers
- None
EOF
create_issue "Week 1: Set up FastAPI project scaffold + Docker Compose" "$BODY" "backend,infra,week-1" "$M1" "$BM"

# ── Task 9 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Initialize the React Native mobile app using Expo Router with proper route group structure.

## Implementation Details
- Create `mobile/` directory using `npx create-expo-app`
- Configure Expo Router with route groups: `(auth)` for login/register, `(app)` for main app screens
- Set up NativeWind for Tailwind CSS styling
- Configure TypeScript strictly
- Basic tab navigation placeholder screens

## Acceptance Criteria
- [ ] Expo app boots without errors (`npx expo start`)
- [ ] Route groups `(auth)` and `(app)` configured correctly
- [ ] NativeWind / Tailwind CSS working
- [ ] TypeScript configured with strict mode
- [ ] Tab navigation with placeholder screens functional

## Dependencies / Blockers
- None
EOF
create_issue "Week 1: Set up Expo Router project with route groups" "$BODY" "mobile,week-1" "$M1" "$BM"

# ── Task 10 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Write comprehensive unit tests for the preprocessing pipeline and OCR integration to ensure correctness and reliability.

## Implementation Details
- Use pytest framework
- Test `src/preprocessing.py`: resize, grayscale, threshold, deskew with sample images
- Test `src/ocr.py`: mock Tesseract, validate output structure
- Test `src/postprocessor.py`: regex patterns for all 5 field classes with known inputs
- Achieve >= 80% code coverage

## Acceptance Criteria
- [ ] `pytest` runs without errors
- [ ] All preprocessing functions have tests
- [ ] All OCR functions have tests (mocked Tesseract)
- [ ] All postprocessor regex patterns tested
- [ ] Code coverage >= 80% for `src/` module

## Dependencies / Blockers
- Depends on: Week 1 — Implement preprocessing pipeline in OpenCV
- Depends on: Week 1 — Integrate Tesseract OCR (lang: hin+eng)
- Depends on: Week 1 — Build regex post-processor for each field class
EOF
create_issue "Week 1: Write unit tests for preprocessing + OCR pipeline" "$BODY" "test,week-1" "$M1" "$BM"

echo ""
echo "── Week 2 ──────────────────────────────────────────────────────────"

# ── Task 11 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Export the trained YOLOv8 model to ONNX format for optimized cross-platform inference.

## Implementation Details
- Use `model.export(format='onnx')` via Ultralytics API
- Validate ONNX model with `onnxruntime` on 10+ test images
- Compare ONNX inference results vs PyTorch inference (mAP diff < 1%)
- Benchmark inference time: target <= 200ms per image on CPU
- Store model at `models/best.onnx`

## Acceptance Criteria
- [ ] ONNX export completes without errors
- [ ] `best.onnx` passes onnxruntime validation
- [ ] mAP difference between PyTorch and ONNX < 1%
- [ ] CPU inference time <= 200ms per image
- [ ] ONNX model stored at `models/best.onnx`

## Dependencies / Blockers
- Depends on: Week 1 — Run baseline YOLOv8-small training (100 epochs)
EOF
create_issue "Week 2: Export best.pt to ONNX and validate inference" "$BODY" "ai,week-2" "$M2" "$AI"

# ── Task 12 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement Error Level Analysis (ELA) to detect digital forgery or tampering in Aadhaar card images.

## Implementation Details
- Implement ELA in `src/forgery.py`
- Algorithm: save image at known JPEG quality (95%), compute pixel difference, highlight high-error regions
- Threshold-based classification: forgery if max ELA region > threshold
- Return: {"is_forged": bool, "confidence": float, "ela_image": base64}
- Test on genuine and tampered sample images

## Acceptance Criteria
- [ ] ELA algorithm correctly identifies tampered images in test set
- [ ] Returns structured JSON response
- [ ] False positive rate < 10% on genuine document test set
- [ ] ELA visualization image returned as base64
- [ ] Module integrated into AI pipeline

## Dependencies / Blockers
- Depends on: Week 1 — Implement preprocessing pipeline in OpenCV
EOF
create_issue "Week 2: Build ELA forgery detection module" "$BODY" "ai,week-2" "$M2" "$AI"

# ── Task 13 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build a QR code decoder and payload validator for Aadhaar cards to verify authenticity.

## Implementation Details
- Use `pyzbar` or `opencv-python` to decode QR codes from Aadhaar images
- Validate decoded payload against UIDAI QR format (XML/signed data)
- Extract and cross-reference fields: UID, name, DOB against OCR output
- Implement in `src/qr_validator.py`
- Return: {"qr_valid": bool, "fields_match": bool, "payload": dict}

## Acceptance Criteria
- [ ] QR code successfully decoded from sample Aadhaar images
- [ ] Payload parsed and validated against UIDAI format
- [ ] Cross-reference with OCR output implemented
- [ ] Module returns structured validation result
- [ ] Unit tests cover valid and invalid QR scenarios

## Dependencies / Blockers
- Depends on: Week 1 — Integrate Tesseract OCR (lang: hin+eng)
- Depends on: Week 1 — Implement preprocessing pipeline in OpenCV
EOF
create_issue "Week 2: Build QR code payload validator" "$BODY" "ai,week-2" "$M2" "$AI"

# ── Task 14 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement JWT-based authentication with register, login, and token refresh endpoints.

## Implementation Details
- Endpoints: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`
- Use `python-jose` for JWT, `passlib[bcrypt]` for password hashing
- Access token: 15-minute TTL; Refresh token: 7-day TTL (stored in Redis)
- User model: `id`, `email`, `hashed_password`, `created_at`
- Return `access_token`, `refresh_token`, `token_type` on login

## Acceptance Criteria
- [ ] Register endpoint creates user with hashed password
- [ ] Login returns valid access + refresh tokens
- [ ] Refresh endpoint issues new access token
- [ ] Invalid/expired tokens return 401
- [ ] Passwords are bcrypt-hashed (never stored plain)
- [ ] Refresh tokens invalidated on logout

## Dependencies / Blockers
- Depends on: Week 1 — Set up FastAPI project scaffold + Docker Compose
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
EOF
create_issue "Week 2: Implement JWT auth: register, login, refresh" "$BODY" "backend,week-2" "$M2" "$BM"

# ── Task 15 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement the document upload endpoint that processes uploaded Aadhaar cards through the full AI pipeline.

## Implementation Details
- Endpoint: `POST /documents/upload`
- Accepts: multipart/form-data (file: image/PDF)
- Pipeline: preprocess -> YOLO detect -> OCR -> postprocess -> ELA check -> QR validate
- Store original in MinIO; store results in PostgreSQL
- Return: {"document_id": uuid, "fields": {}, "forgery": {}, "qr": {}}
- Auth required (JWT Bearer token)

## Acceptance Criteria
- [ ] Endpoint accepts image and PDF uploads
- [ ] Full AI pipeline executes in <= 8s end-to-end
- [ ] Document stored in MinIO with unique UUID path
- [ ] Extracted fields stored in PostgreSQL
- [ ] Response contains document_id + all AI results
- [ ] Requires valid JWT token

## Dependencies / Blockers
- Depends on: Week 1 — Set up FastAPI project scaffold + Docker Compose
- Depends on: Week 2 — Export best.pt to ONNX and validate inference
- Depends on: Week 2 — Build ELA forgery detection module
- Depends on: Week 2 — Build QR code payload validator
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
EOF
create_issue "Week 2: POST /documents/upload — file + AI pipeline" "$BODY" "backend,ai,week-2" "$M2" "$BM"

# ── Task 16 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement the document masking endpoint that applies configurable field-level masking to Aadhaar card documents.

## Implementation Details
- Endpoint: `POST /documents/{id}/mask`
- Request body: {"mask_fields": ["uid", "dob", "address"]} (configurable per field)
- Apply black rectangle masking over selected field bounding boxes
- Generate masked version of document image + PDF
- Store masked result in MinIO; update document record
- Return: {"masked_document_id": uuid, "preview_url": str}

## Acceptance Criteria
- [ ] Endpoint accepts list of field names to mask
- [ ] Masking applied correctly to each specified field
- [ ] Masked image and PDF generated
- [ ] Masked document stored separately from original
- [ ] Preview URL accessible (time-limited signed URL)
- [ ] Auth required

## Dependencies / Blockers
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
- Depends on: Week 2 — POST /documents/upload — file + AI pipeline
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
EOF
create_issue "Week 2: POST /documents/{id}/mask — apply masking config" "$BODY" "backend,week-2" "$M2" "$BM"

# ── Task 17 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Define all SQLAlchemy ORM models for the backend database layer.

## Implementation Details
- Models to create in `backend/models/`:
  - `User`: id (UUID), email, hashed_password, created_at, updated_at
  - `Document`: id (UUID), user_id (FK), minio_path, fields (JSONB), forgery_result (JSONB), created_at
  - `VaultItem`: id (UUID), user_id (FK), document_id (FK), encrypted_key, minio_path, created_at
  - `ShareToken`: id (UUID), vault_item_id (FK), token (unique), expires_at, view_count, max_views
- Use Alembic for migrations
- Add `__repr__` and relationship definitions

## Acceptance Criteria
- [ ] All 4 models created with correct fields and types
- [ ] Foreign key relationships defined
- [ ] Alembic initial migration runs without errors
- [ ] User -> Document -> VaultItem -> ShareToken relationship chain works
- [ ] UUID primary keys used throughout

## Dependencies / Blockers
- Depends on: Week 1 — Set up FastAPI project scaffold + Docker Compose
EOF
create_issue "Week 2: SQLAlchemy models: User, Document, VaultItem, ShareToken" "$BODY" "backend,week-2" "$M2" "$BM"

# ── Task 18 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the Login and Register screens in the Expo Router `(auth)` route group.

## Implementation Details
- `app/(auth)/login.tsx`: email + password form, submit -> `POST /auth/login`, store tokens in SecureStore
- `app/(auth)/register.tsx`: email + password + confirm form, submit -> `POST /auth/register`
- Form validation with `react-hook-form` + `zod`
- Loading states and error handling
- Redirect to `(app)` on successful auth
- Style with NativeWind

## Acceptance Criteria
- [ ] Login screen submits and receives JWT tokens
- [ ] Tokens stored securely in `expo-secure-store`
- [ ] Register screen creates account and redirects to login
- [ ] Form validation shows inline errors
- [ ] Loading spinner shown during API call
- [ ] Screens styled consistently with NativeWind

## Dependencies / Blockers
- Depends on: Week 1 — Set up Expo Router project with route groups
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
EOF
create_issue "Week 2: Auth screens: Login + Register in Expo Router" "$BODY" "mobile,week-2" "$M2" "$BM"

# ── Task 19 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Write API integration tests covering the full authentication, document upload, and masking flows.

## Implementation Details
- Use pytest + HTTPX (async test client)
- Test scenarios:
  - Auth: register -> login -> access protected route -> refresh -> logout
  - Upload: auth -> upload real Aadhaar image -> verify fields extracted
  - Mask: upload -> mask uid+dob -> verify masked document returned
- Use test database (SQLite in-memory or test PostgreSQL)
- Mock AI pipeline for fast tests; integration flag for full pipeline

## Acceptance Criteria
- [ ] Auth flow test passes (register, login, refresh, logout)
- [ ] Upload endpoint tested with real image + mock AI
- [ ] Mask endpoint tested with valid document ID
- [ ] All tests pass in CI
- [ ] Test database isolated from production

## Dependencies / Blockers
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
- Depends on: Week 2 — POST /documents/upload — file + AI pipeline
- Depends on: Week 2 — POST /documents/{id}/mask — apply masking config
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
EOF
create_issue "Week 2: API integration tests: auth + upload + mask" "$BODY" "test,week-2" "$M2" "$AI"

echo ""
echo "── Week 3 ──────────────────────────────────────────────────────────"

# ── Task 20 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the camera capture screen for scanning Aadhaar cards with real-time image quality validation.

## Implementation Details
- Use `expo-camera` to capture card image
- Real-time quality checks: blur detection (Laplacian variance), glare detection, card boundary detection
- Quality score overlay (green/yellow/red indicator)
- Capture button disabled if quality score < threshold
- Auto-crop to card boundaries using OpenCV.js or native
- Upload captured image directly to `/documents/upload`

## Acceptance Criteria
- [ ] Camera preview renders without errors
- [ ] Blur detection score shown in real-time
- [ ] Capture disabled for low-quality frames
- [ ] Image captured and sent to upload API
- [ ] Works on both iOS and Android

## Dependencies / Blockers
- Depends on: Week 1 — Set up Expo Router project with route groups
- Depends on: Week 2 — POST /documents/upload — file + AI pipeline
EOF
create_issue "Week 3: Camera capture screen with image quality check" "$BODY" "mobile,week-3" "$M3" "$BM"

# ── Task 21 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the AI processing loader screen that displays real-time progress during document analysis.

## Implementation Details
- Animated progress screen shown after capture/upload
- Steps displayed: "Uploading...", "Detecting fields...", "Running OCR...", "Checking authenticity...", "Done!"
- Use `react-native-reanimated` for smooth animations
- WebSocket or polling (`/documents/{id}/status`) for real-time updates
- Auto-navigate to masking screen on completion
- Show error state if processing fails

## Acceptance Criteria
- [ ] Loader screen displays animated progress steps
- [ ] Steps update in real-time (WebSocket or polling)
- [ ] Auto-navigates to masking screen when complete
- [ ] Error state shown if API returns failure
- [ ] Animations smooth at 60fps

## Dependencies / Blockers
- Depends on: Week 1 — Set up Expo Router project with route groups
- Depends on: Week 2 — POST /documents/upload — file + AI pipeline
- Depends on: Week 3 — Camera capture screen with image quality check
EOF
create_issue "Week 3: AI processing loader screen" "$BODY" "mobile,week-3" "$M3" "$BM"

# ── Task 22 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the masking configuration screen with toggles for each Aadhaar field and live document preview.

## Implementation Details
- Display document image with field bounding boxes highlighted
- Toggle switches for each detected field (uid, dob, name, gender, address)
- Live preview: masked fields shown as black rectangles in real-time (client-side rendering)
- "Apply Masking" button calls `POST /documents/{id}/mask` with selected fields
- Confirmation modal before applying permanent mask

## Acceptance Criteria
- [ ] All detected fields shown as toggle switches
- [ ] Live preview updates when toggles change (client-side)
- [ ] "Apply Masking" calls API with correct field list
- [ ] Confirmation modal prevents accidental masking
- [ ] Loading state shown during API call

## Dependencies / Blockers
- Depends on: Week 2 — POST /documents/{id}/mask — apply masking config
- Depends on: Week 3 — Camera capture screen with image quality check
- Depends on: Week 3 — AI processing loader screen
EOF
create_issue "Week 3: Masking toggle UI with live document preview" "$BODY" "mobile,week-3" "$M3" "$BM"

# ── Task 23 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement the secure document vault with AES-256 encryption for stored Aadhaar documents.

## Implementation Details
- Endpoints: `POST /vault/`, `GET /vault/`, `GET /vault/{id}`, `DELETE /vault/{id}`
- Encrypt document with AES-256-GCM using per-document key
- Store encrypted key in `VaultItem.encrypted_key` (encrypted with user's derived key)
- Store encrypted file in MinIO at `vault/{user_id}/{uuid}.enc`
- KDF: PBKDF2 with user's password hash as input
- Implement in `backend/routers/vault.py`

## Acceptance Criteria
- [ ] Documents encrypted with AES-256-GCM before storage
- [ ] Per-document encryption keys used
- [ ] CRUD operations work correctly
- [ ] DELETE removes from both MinIO and PostgreSQL
- [ ] Encryption/decryption round-trip tested

## Dependencies / Blockers
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
- Depends on: Week 2 — POST /documents/upload — file + AI pipeline
EOF
create_issue "Week 3: Vault CRUD: encrypt + store in MinIO" "$BODY" "backend,week-3" "$M3" "$AI"

# ── Task 24 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the share token engine that generates time-limited share links and QR codes using Redis TTL.

## Implementation Details
- Endpoint: `POST /vault/{id}/share` -> generates ShareToken
- Token: UUID stored in Redis with TTL (default: 24h, max: 7d)
- Link format: `https://docushield.app/share/{token}`
- QR code: generated server-side with `qrcode` library
- View count tracking; optional max_views limit
- Token stored in ShareToken model in PostgreSQL

## Acceptance Criteria
- [ ] Share link generated with configurable TTL
- [ ] Token stored in Redis with correct TTL
- [ ] QR code image returned as base64
- [ ] View count incremented on each access
- [ ] Token expires correctly after TTL
- [ ] max_views limit enforced when set

## Dependencies / Blockers
- Depends on: Week 3 — Vault CRUD: encrypt + store in MinIO
- Depends on: Week 2 — SQLAlchemy models: User, Document, VaultItem, ShareToken
EOF
create_issue "Week 3: Share token engine: Redis TTL + link + QR" "$BODY" "backend,week-3" "$M3" "$AI"

# ── Task 25 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Generate a watermarked, masked PDF version of the Aadhaar document for sharing.

## Implementation Details
- Use `reportlab` or `pypdf2` to generate PDF from masked image
- Add watermark: "SHARED VIA DOCUSHIELD AI — {date} — FOR VERIFICATION ONLY"
- Embed metadata: document_id, share_token, timestamp
- PDF stored in MinIO at `shares/{share_token}.pdf`
- Endpoint: `GET /documents/{id}/masked-pdf`

## Acceptance Criteria
- [ ] PDF generated from masked document image
- [ ] Watermark visible and correctly formatted
- [ ] Metadata embedded in PDF properties
- [ ] PDF stored in MinIO and accessible via signed URL
- [ ] PDF generation time <= 2s

## Dependencies / Blockers
- Depends on: Week 2 — POST /documents/{id}/mask — apply masking config
- Depends on: Week 3 — Share token engine: Redis TTL + link + QR
EOF
create_issue "Week 3: Masked PDF generator with watermark" "$BODY" "backend,week-3" "$M3" "$AI"

# ── Task 26 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the share screen that displays the share link, QR code fullscreen, and PDF download button.

## Implementation Details
- `app/(app)/share/[id].tsx`
- Display: large QR code (fullscreen-capable), copy-to-clipboard share link, PDF download button
- TTL countdown timer showing link expiry
- Share via native share sheet (`expo-sharing`)
- Regenerate link button (invalidates old token)
- QR code rendered client-side with `react-native-qrcode-svg`

## Acceptance Criteria
- [ ] QR code renders correctly from share token
- [ ] Copy-to-clipboard works on both platforms
- [ ] PDF download opens in native PDF viewer
- [ ] TTL countdown accurate
- [ ] Native share sheet opens with share link
- [ ] Regenerate link invalidates previous token

## Dependencies / Blockers
- Depends on: Week 3 — Share token engine: Redis TTL + link + QR
- Depends on: Week 3 — Masked PDF generator with watermark
- Depends on: Week 3 — Masking toggle UI with live document preview
EOF
create_issue "Week 3: Share screen: link + QR fullscreen + PDF button" "$BODY" "mobile,week-3" "$M3" "$BM"

# ── Task 27 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Build the vault list screen, document detail view, and share activity log in the mobile app.

## Implementation Details
- `app/(app)/vault/index.tsx`: paginated list of vault items with thumbnail + date
- `app/(app)/vault/[id].tsx`: document detail with field values, masking status, share history
- Share log: list of active/expired share links with view counts
- Pull-to-refresh, swipe-to-delete (with confirmation)
- Empty state illustration

## Acceptance Criteria
- [ ] Vault list loads and paginates correctly
- [ ] Document detail shows all extracted fields
- [ ] Share log shows active and expired tokens
- [ ] Delete removes document from vault (with confirmation)
- [ ] Pull-to-refresh works
- [ ] Empty state shown when vault is empty

## Dependencies / Blockers
- Depends on: Week 3 — Vault CRUD: encrypt + store in MinIO
- Depends on: Week 3 — Share token engine: Redis TTL + link + QR
- Depends on: Week 3 — Share screen: link + QR fullscreen + PDF button
EOF
create_issue "Week 3: Vault list screen + document detail + share log" "$BODY" "mobile,week-3" "$M3" "$BM"

# ── Task 28 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Implement the public share endpoint that allows unauthenticated viewers to access shared Aadhaar documents.

## Implementation Details
- Endpoint: `GET /share/{token}` — no auth required
- Validate token against Redis (exists + not expired + view count < max_views)
- Retrieve masked document from MinIO
- Increment view count in Redis and PostgreSQL
- Return: {"document": base64_image, "fields": masked_fields, "pdf_url": str, "expires_at": datetime}
- Rate limiting: 10 requests/minute per IP

## Acceptance Criteria
- [ ] Valid token returns masked document
- [ ] Expired token returns 410 Gone
- [ ] Exceeded max_views returns 403 Forbidden
- [ ] View count incremented correctly
- [ ] Rate limiting enforced (10 req/min per IP)
- [ ] No authentication required

## Dependencies / Blockers
- Depends on: Week 3 — Share token engine: Redis TTL + link + QR
- Depends on: Week 3 — Masked PDF generator with watermark
- Depends on: Week 3 — Vault CRUD: encrypt + store in MinIO
EOF
create_issue "Week 3: GET /share/{token} — public share endpoint" "$BODY" "backend,week-3" "$M3" "$AI"

echo ""
echo "── Week 4 ──────────────────────────────────────────────────────────"

# ── Task 29 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Write and pass a full end-to-end smoke test covering the complete user journey from upload to share to view.

## Implementation Details
- E2E test flow: register user -> login -> capture/upload Aadhaar image -> check AI results -> apply masking -> add to vault -> generate share link -> access via share endpoint
- Use Detox (React Native) for mobile E2E or Playwright for web-based test
- Run against staging environment (Docker Compose)
- Record test run as video artifact

## Acceptance Criteria
- [ ] Full E2E flow completes without errors
- [ ] Each step validated with assertions
- [ ] Test runs in CI pipeline
- [ ] Test video artifact saved
- [ ] All critical paths covered

## Dependencies / Blockers
- Depends on all Week 1-3 issues
EOF
create_issue "Week 4: Full E2E smoke test: upload → mask → share → view" "$BODY" "test,week-4" "$M4" "$BM"

# ── Task 30 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Benchmark the end-to-end system performance to ensure the full pipeline completes within 8 seconds on a 4G network.

## Implementation Details
- Measure: image capture -> upload -> AI processing -> response received
- Network simulation: 4G (50 Mbps down, 20 Mbps up, 30ms latency)
- Tool: k6 for API load testing, Flipper for mobile network profiling
- Targets: upload + AI pipeline <= 6s; UI render <= 2s; total <= 8s
- Run 100 iterations; report p50, p95, p99

## Acceptance Criteria
- [ ] p50 end-to-end latency <= 8s on simulated 4G
- [ ] p95 end-to-end latency <= 12s on simulated 4G
- [ ] AI pipeline alone <= 6s
- [ ] Benchmark report generated (JSON + chart)
- [ ] Bottlenecks identified and documented

## Dependencies / Blockers
- Depends on all Week 1-3 issues
EOF
create_issue "Week 4: Performance benchmarks: end-to-end ≤ 8s on 4G" "$BODY" "test,week-4" "$M4" "$AI"

# ── Task 31 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Generate a comprehensive AI evaluation report with mAP-50, Text Recognition Accuracy (TRA), and per-class metrics.

## Implementation Details
- Run YOLOv8 evaluation on held-out test set
- Metrics: mAP-50, mAP-50-95, precision, recall per class
- OCR TRA: character accuracy, word accuracy per field class
- Forgery detection: precision/recall/F1 on tampered vs genuine test set
- QR validation: success rate on QR-bearing Aadhaar samples
- Report format: Markdown + CSV + confusion matrix plots

## Acceptance Criteria
- [ ] mAP-50 >= 0.85 on test set
- [ ] TRA per class documented (target >= 90% character accuracy)
- [ ] Forgery detection F1 >= 0.80
- [ ] Confusion matrix generated for all classes
- [ ] Final report saved to `reports/ai_evaluation.md`

## Dependencies / Blockers
- Depends on: Week 1 — Run baseline YOLOv8-small training (100 epochs)
- Depends on: Week 1 — Integrate Tesseract OCR (lang: hin+eng)
- Depends on: Week 1 — Build regex post-processor for each field class
- Depends on: Week 2 — Export best.pt to ONNX and validate inference
- Depends on: Week 2 — Build ELA forgery detection module
- Depends on: Week 2 — Build QR code payload validator
EOF
create_issue "Week 4: AI evaluation report: mAP-50, TRA per class" "$BODY" "ai,week-4" "$M4" "$AI"

# ── Task 32 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Conduct a security audit covering authentication flows, token management, and data encryption implementation.

## Implementation Details
- Auth audit: brute-force protection, password strength enforcement, token replay prevention
- Token audit: verify access token TTL (15 min), refresh token rotation, Redis TTL accuracy
- Encryption audit: verify AES-256-GCM implementation, key derivation correctness, no key leakage in logs
- Input validation: SQL injection, path traversal, file upload bypass
- Tools: bandit (Python static analysis), OWASP ZAP (API scan)

## Acceptance Criteria
- [ ] No critical/high findings from bandit
- [ ] OWASP ZAP scan passes with no high-risk alerts
- [ ] Token TTL verified with automated tests
- [ ] Encryption round-trip audit complete
- [ ] Security findings documented in `reports/security_audit.md`

## Dependencies / Blockers
- Depends on: Week 2 — Implement JWT auth: register, login, refresh
- Depends on: Week 3 — Vault CRUD: encrypt + store in MinIO
- Depends on: Week 3 — Share token engine: Redis TTL + link + QR
EOF
create_issue "Week 4: Security audit: auth, token expiry, encryption" "$BODY" "test,infra,week-4" "$M4" "$BM"

# ── Task 33 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Update the `.agent/INDEX.md` file with the final system state, architectural decisions, and implementation notes.

## Implementation Details
- Document all final architecture decisions (model choice, DB schema, encryption approach)
- Update component inventory with actual files/modules created
- Record key metrics (mAP-50, benchmark results)
- Document known limitations and future work (Phase 2 scope)
- Include setup instructions for new contributors

## Acceptance Criteria
- [ ] `.agent/INDEX.md` updated with current system state
- [ ] All architectural decisions documented with rationale
- [ ] Component inventory accurate and complete
- [ ] Setup instructions verified by a team member
- [ ] Phase 2 scope documented

## Dependencies / Blockers
- Depends on: Week 4 — AI evaluation report: mAP-50, TRA per class
- Depends on: Week 4 — Security audit: auth, token expiry, encryption
EOF
create_issue "Week 4: Update .agent/INDEX.md with final state + decisions" "$BODY" "infra,week-4" "$M4" "$AI"

# ── Task 34 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Prepare and submit the BAD685 project deliverables: final report and demo video.

## Implementation Details
- Written report: architecture overview, AI methodology, results (mAP, TRA, benchmarks), security measures
- Demo video: 5-min walkthrough — capture Aadhaar -> AI processing -> masking -> share -> view via link
- Submission format: PDF report + MP4 video + GitHub repo link
- Ensure all code is committed, README updated, and repo is public/accessible

## Acceptance Criteria
- [ ] Written report complete (architecture, methods, results, security)
- [ ] Demo video recorded (>= 5 minutes, covers full flow)
- [ ] Report exported as PDF
- [ ] Submission uploaded to BAD685 portal
- [ ] GitHub repo link shared with evaluators

## Dependencies / Blockers
- Depends on: Week 4 — Full E2E smoke test: upload -> mask -> share -> view
- Depends on: Week 4 — Performance benchmarks: end-to-end <= 8s on 4G
- Depends on: Week 4 — AI evaluation report: mAP-50, TRA per class
- Depends on: Week 4 — Security audit: auth, token expiry, encryption
- Depends on: Week 4 — Update .agent/INDEX.md with final state + decisions
EOF
create_issue "Week 4: BAD685 submission: report + demo video" "$BODY" "infra,week-4" "$M4" "$AI"

# ── Task 35 ──
read -r -d '' BODY <<'EOF' || true
## Objective
Research and prepare for Phase 2 by identifying suitable PAN card datasets and defining the next iteration scope.

## Implementation Details
- Survey available PAN card datasets on Roboflow, Kaggle, and UIDAI open data
- Document dataset size, class labels, quality, and licensing
- Evaluate transfer learning potential from Aadhaar model
- Draft Phase 2 milestones: PAN card detection, multi-document vault, biometric verification
- Create Phase 2 roadmap document: `docs/phase2_roadmap.md`

## Acceptance Criteria
- [ ] At least 2 PAN card datasets identified and evaluated
- [ ] Dataset licensing confirmed
- [ ] Transfer learning feasibility documented
- [ ] Phase 2 roadmap drafted in `docs/phase2_roadmap.md`
- [ ] Phase 2 kickoff meeting notes recorded

## Dependencies / Blockers
- Depends on: Week 4 — AI evaluation report: mAP-50, TRA per class (understanding model capabilities for transfer learning)
EOF
create_issue "Week 4: Phase 2 kickoff: PAN card dataset research" "$BODY" "ai,week-4" "$M4" "$BM"

echo ""
echo "======================================================================"
echo "Issue seed complete."
echo "Verify at: https://github.com/${REPO}/issues"
echo "======================================================================"
