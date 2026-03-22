# GETSHITDONE.md — DocuShield AI Task Contracts
**Protocol version**: 1.0  
**Read CLAUDE.md → GSD Workflow section before executing any task here.**

> Each task below is an atomic contract. One task = one file = one symbol.
> Status: TODO | IN_PROGRESS | DONE | BLOCKED

---

## Quick Commands (reference only — run after each task gate)

```bash
# Start services
docker-compose up -d

# Backend
cd backend && uvicorn app.main:app --reload --port 8000

# Mobile
cd mobile && npx expo start

# Run specific test (use the exact command from the task's Acceptance Criteria)
cd backend && pytest tests/test_<module>.py::<test_name> -v

# Run all tests
cd backend && pytest && cd ../mobile && npx jest
```

---

## TRACK A — AI / ML Pipeline

---

## TASK A-01: Preprocessing pipeline
**Status**: TODO  
**File**: `backend/app/services/ai/preprocess.py`  
**Symbol**: `preprocess_image(img: np.ndarray) -> np.ndarray`  
**Depends on**: none  
**Estimated scope**: ~40 lines

### 1. Read First
- [ ] Read `backend/app/services/ai/preprocess.py` — confirm it is empty (scaffolded placeholder)
- [ ] Confirm `import cv2` and `import numpy as np` are available in requirements.txt

### 2. Write Exactly This
A single function `preprocess_image` that accepts a BGR numpy array and returns a preprocessed BGR numpy array ready for ONNX inference. Steps in order:
1. Grayscale conversion (`cv2.cvtColor` → `COLOR_BGR2GRAY`)
2. Gaussian blur 5×5 (`cv2.GaussianBlur`)
3. Canny edge detection (low=50, high=150)
4. Perspective correction: find largest quadrilateral contour, apply `cv2.getPerspectiveTransform`
5. Normalize: cast to float32, divide by 255.0
6. Return as 3-channel float array (re-stack grayscale to 3ch if needed for ONNX input)

### 3. Do Not Touch
- Do not modify `field_detector.py` — that is Task A-03
- Do not add any model loading — this is pure image transformation only
- Do not add CLI entrypoint — that is a separate task

### 4. Acceptance Criteria
- [ ] `preprocess_image(cv2.imread("tests/fixtures/sample_aadhaar.jpg"))` returns ndarray with dtype=float32
- [ ] Output shape is `(H, W, 3)` — never 1-channel
- [ ] `pytest tests/test_preprocess.py::test_output_dtype` passes
- [ ] `pytest tests/test_preprocess.py::test_output_shape` passes

### 5. Commit Checkpoint
`feat(ai): add image preprocessing pipeline [A-01]`

---

## TASK A-02: Tesseract OCR extractor
**Status**: TODO  
**File**: `backend/app/services/ai/ocr.py`  
**Symbol**: `extract_field_text(img: np.ndarray, bbox: tuple[int,int,int,int], field_class: int) -> str`  
**Depends on**: A-01  
**Estimated scope**: ~50 lines

### 1. Read First
- [ ] Read `backend/app/services/ai/ocr.py` — confirm it is empty
- [ ] Read `backend/app/services/ai/preprocess.py` — understand what format `img` arrives in
- [ ] Confirm `pytesseract` is in requirements.txt

### 2. Write Exactly This
A single function `extract_field_text` that:
- Crops `img` to `bbox` (x1, y1, x2, y2)
- Selects PSM: `psm = 11 if field_class == 4 else 6` (Address gets sparse text mode)
- Calls `pytesseract.image_to_string(cropped, config=f"--psm {psm} -l hin+eng --oem 3")`
- Strips whitespace and returns raw string (no regex post-processing here — that is Task A-05)

Also define the regex patterns dict as a module-level constant (used by A-05):
```python
FIELD_PATTERNS = {
    0: r'\d{4}\s\d{4}\s\d{4}',
    1: r'\d{2}[/\-]\d{2}[/\-]\d{4}',
    2: r'(?i)(male|female|पुरुष|महिला)',
    3: None,
    4: r'(\d{6})',
}
```

### 3. Do Not Touch
- Do not add regex matching logic — that is Task A-05
- Do not call the YOLOv8 model — that is Task A-03
- Do not import anything from `field_detector.py`

### 4. Acceptance Criteria
- [ ] `extract_field_text(img, (10,10,200,50), 0)` returns a string (may be empty if no text — that is valid)
- [ ] `extract_field_text(img, (10,10,200,50), 4)` uses PSM 11 (assert config string contains `--psm 11`)
- [ ] `pytest tests/test_ocr.py::test_psm_selection` passes
- [ ] `pytest tests/test_ocr.py::test_returns_string` passes

### 5. Commit Checkpoint
`feat(ai): add Tesseract OCR extractor [A-02]`

---

## TASK A-03: YOLOv8 field detector
**Status**: TODO  
**File**: `backend/app/services/ai/field_detector.py`  
**Symbol**: `detect_fields(img: np.ndarray, model_path: str) -> list[dict]`  
**Depends on**: A-01  
**Estimated scope**: ~60 lines

### 1. Read First
- [ ] Read `backend/app/services/ai/field_detector.py` — confirm empty
- [ ] Read `backend/app/services/ai/preprocess.py` to confirm `preprocess_image` signature
- [ ] Confirm `onnxruntime` is in requirements.txt

### 2. Write Exactly This
A single function `detect_fields` that:
- Loads ONNX model with `ort.InferenceSession(model_path)`
- Calls `preprocess_image(img)` first — never raw input
- Runs inference, parses output boxes with confidence ≥ 0.60
- Returns list of dicts: `[{"class_id": int, "class_name": str, "bbox": [x1,y1,x2,y2], "confidence": float}]`

Class names constant (define in this file):
```python
CLASS_NAMES = {0: "AadhaarNumber", 1: "DOB", 2: "Gender", 3: "Name", 4: "Address"}
CONFIDENCE_THRESHOLD = 0.60
```

### 3. Do Not Touch
- Do not call OCR from this function — that is Task A-04 (pipeline orchestrator)
- Do not add model training code
- Do not add any HTTP/FastAPI imports

### 4. Acceptance Criteria
- [ ] Returns `[]` (empty list) when no detections above threshold — never raises
- [ ] Each dict has exactly keys: `class_id`, `class_name`, `bbox`, `confidence`
- [ ] `pytest tests/test_field_detector.py::test_returns_list` passes
- [ ] `pytest tests/test_field_detector.py::test_empty_on_low_confidence` passes

### 5. Commit Checkpoint
`feat(ai): add ONNX field detector [A-03]`

---

## TASK A-04: AI pipeline orchestrator
**Status**: TODO  
**File**: `backend/app/services/ai/pipeline.py`  
**Symbol**: `run_pipeline(image_bytes: bytes, model_path: str) -> dict`  
**Depends on**: A-01, A-02, A-03  
**Estimated scope**: ~45 lines

### 1. Read First
- [ ] Read `field_detector.py` — note exact signature of `detect_fields`
- [ ] Read `ocr.py` — note exact signature of `extract_field_text`
- [ ] Read `preprocess.py` — understand what `img` looks like after preprocessing

### 2. Write Exactly This
A single orchestrator function that:
1. Decodes `image_bytes` to numpy array via `cv2.imdecode`
2. Calls `detect_fields(img, model_path)` → gets bounding boxes
3. For each detected field, calls `extract_field_text(img, bbox, class_id)`
4. Returns a single dict:
```python
{
  "fields": [
    {"class_id": 0, "class_name": "AadhaarNumber", "bbox": [...], "text": "...", "confidence": 0.96}
  ],
  "raw_image_shape": [H, W, C]
}
```

### 3. Do Not Touch
- Do not add forgery detection here — that is Task A-06
- Do not add regex post-processing here — that is Task A-05
- Do not add any FastAPI route logic

### 4. Acceptance Criteria
- [ ] Accepts `bytes` input (not a file path)
- [ ] Returns dict with `"fields"` key containing a list
- [ ] Works when `detect_fields` returns `[]` — returns `{"fields": [], "raw_image_shape": [...]}`
- [ ] `pytest tests/test_pipeline.py::test_returns_dict` passes
- [ ] `pytest tests/test_pipeline.py::test_empty_detections_ok` passes

### 5. Commit Checkpoint
`feat(ai): add pipeline orchestrator [A-04]`

---

## TASK A-05: Regex post-processor
**Status**: TODO  
**File**: `backend/app/services/ai/ocr.py`  
**Symbol**: `post_process_field(raw_text: str, field_class: int) -> str`  
**Depends on**: A-02  
**Estimated scope**: ~35 lines

### 1. Read First
- [ ] Read `backend/app/services/ai/ocr.py` — find `FIELD_PATTERNS` constant defined in A-02
- [ ] Do NOT redefine `FIELD_PATTERNS` — it already exists

### 2. Write Exactly This
Add a second function `post_process_field` to the same file:
- For class 0 (AadhaarNumber): apply `FIELD_PATTERNS[0]` regex, normalize spaces
- For class 1 (DOB): apply `FIELD_PATTERNS[1]`, standardize to DD/MM/YYYY
- For class 2 (Gender): apply `FIELD_PATTERNS[2]`, normalize to "Male"/"Female"
- For class 3 (Name): strip non-alpha chars, title-case
- For class 4 (Address): extract PIN code via `FIELD_PATTERNS[4]`, return `f"{raw_text.strip()} [PIN: {pin}]"` if found

### 3. Do Not Touch
- Do not modify `extract_field_text` — it must remain unchanged
- Do not import RapidFuzz unless you add it to requirements.txt first

### 4. Acceptance Criteria
- [ ] `post_process_field("1234 5678 9012", 0)` returns `"1234 5678 9012"` (valid, unchanged)
- [ ] `post_process_field("abcd efgh ijkl", 0)` returns `""` (no valid Aadhaar pattern)
- [ ] `post_process_field("MALE", 2)` returns `"Male"`
- [ ] `pytest tests/test_ocr.py::test_post_process_aadhaar` passes
- [ ] `pytest tests/test_ocr.py::test_post_process_gender` passes

### 5. Commit Checkpoint
`feat(ai): add regex post-processor [A-05]`

---

## TASK A-06: ELA forgery detector
**Status**: TODO  
**File**: `backend/app/services/forgery/ela.py`  
**Symbol**: `compute_ela_score(image_bytes: bytes, quality: int = 90) -> float`  
**Depends on**: none  
**Estimated scope**: ~30 lines

### 1. Read First
- [ ] Read `backend/app/services/forgery/ela.py` — confirm empty
- [ ] Confirm `Pillow` is in requirements.txt

### 2. Write Exactly This
A single function `compute_ela_score` that:
1. Opens image from bytes via `Image.open(io.BytesIO(image_bytes))`
2. Saves re-compressed copy to a BytesIO buffer at `quality=quality`
3. Loads re-compressed copy
4. Computes mean absolute pixel difference between original and re-compressed
5. Returns the mean as a float

Thresholds (define as module-level constants, do NOT put logic here):
```python
ELA_SUSPICIOUS_THRESHOLD = 15.0
ELA_FORGED_THRESHOLD = 25.0
```

### 3. Do Not Touch
- Do not import the CNN classifier — that is Task A-07
- Do not return a status string — only a float score
- Do not write to disk — use BytesIO only

### 4. Acceptance Criteria
- [ ] Returns `float` type always
- [ ] Returns `0.0` for an image compared to itself
- [ ] `pytest tests/test_forgery.py::test_ela_returns_float` passes
- [ ] `pytest tests/test_forgery.py::test_ela_zero_on_identity` passes

### 5. Commit Checkpoint
`feat(forgery): add ELA scorer [A-06]`

---

## TASK A-07: QR payload validator
**Status**: TODO  
**File**: `backend/app/services/forgery/qr_validator.py`  
**Symbol**: `validate_qr_payload(image_bytes: bytes, ocr_aadhaar: str) -> dict`  
**Depends on**: A-02  
**Estimated scope**: ~40 lines

### 1. Read First
- [ ] Read `backend/app/services/forgery/qr_validator.py` — confirm empty
- [ ] Read `backend/app/services/ai/ocr.py` — understand `FIELD_PATTERNS[0]` format
- [ ] Confirm `pyzbar` is in requirements.txt

### 2. Write Exactly This
A single function `validate_qr_payload` that:
1. Decodes image bytes, reads QR codes with `pyzbar.decode`
2. If no QR found: returns `{"status": "no_qr", "qr_aadhaar": None}`
3. Extracts Aadhaar number from QR text via `FIELD_PATTERNS[0]`
4. Normalizes both `qr_aadhaar` and `ocr_aadhaar` (strip spaces, digits only)
5. Returns `{"status": "match"|"mismatch"|"qr_unreadable", "qr_aadhaar": str|None}`

Import `FIELD_PATTERNS` from `backend.app.services.ai.ocr` — do not redefine.

### 3. Do Not Touch
- Do not call ELA — that is Task A-06
- Do not return a forgery verdict — only factual match/mismatch
- Do not modify `ocr.py`

### 4. Acceptance Criteria
- [ ] Returns `{"status": "no_qr", ...}` when image has no QR code
- [ ] Returns `{"status": "match", ...}` when QR and OCR Aadhaar numbers match
- [ ] Returns `{"status": "mismatch", ...}` when they differ
- [ ] `pytest tests/test_forgery.py::test_qr_no_qr_code` passes
- [ ] `pytest tests/test_forgery.py::test_qr_match` passes

### 5. Commit Checkpoint
`feat(forgery): add QR payload validator [A-07]`

---

## TASK A-08: Forgery verdict aggregator
**Status**: TODO  
**File**: `backend/app/services/forgery/verdict.py`  
**Symbol**: `get_forgery_verdict(image_bytes: bytes, ocr_aadhaar: str) -> dict`  
**Depends on**: A-06, A-07  
**Estimated scope**: ~35 lines

### 1. Read First
- [ ] Read `ela.py` — note `ELA_SUSPICIOUS_THRESHOLD` and `ELA_FORGED_THRESHOLD` constants
- [ ] Read `qr_validator.py` — note exact return dict shape
- [ ] Read `backend/app/services/forgery/verdict.py` — confirm empty

### 2. Write Exactly This
A single aggregator function that calls both A-06 and A-07, then applies this decision tree:
- QR status = `"mismatch"` → verdict = `"LIKELY_FORGED"`, reason = `"QR payload mismatch"`
- ELA score > `ELA_FORGED_THRESHOLD` → verdict = `"LIKELY_FORGED"`, reason = `"ELA score {score:.1f}"`
- ELA score > `ELA_SUSPICIOUS_THRESHOLD` → verdict = `"SUSPICIOUS"`, reason = `"ELA score {score:.1f}"`
- Otherwise → verdict = `"AUTHENTIC"`

Returns: `{"verdict": str, "ela_score": float, "qr_status": str, "reason": str}`

### 3. Do Not Touch
- Do not add CNN classifier integration in this task (deferred to Phase 2)
- Do not modify `ela.py` or `qr_validator.py`

### 4. Acceptance Criteria
- [ ] QR mismatch always returns `"LIKELY_FORGED"` regardless of ELA score
- [ ] Returns all four keys in every code path
- [ ] `pytest tests/test_forgery.py::test_verdict_qr_mismatch` passes
- [ ] `pytest tests/test_forgery.py::test_verdict_clean` passes

### 5. Commit Checkpoint
`feat(forgery): add verdict aggregator [A-08]`

---

## TRACK B — Backend API

---

## TASK B-01: App config
**Status**: TODO  
**File**: `backend/app/core/config.py`  
**Symbol**: `class Settings(BaseSettings)`  
**Depends on**: none  
**Estimated scope**: ~40 lines

### 1. Read First
- [ ] Read `backend/app/core/config.py` — confirm empty
- [ ] Check `backend/.env.example` for required variable names

### 2. Write Exactly This
A `Settings` class using `pydantic-settings.BaseSettings` with these fields and no others:
```python
DATABASE_URL: str
REDIS_URL: str
MINIO_ENDPOINT: str
MINIO_ACCESS_KEY: str
MINIO_SECRET_KEY: str
JWT_SECRET: str
JWT_ALGORITHM: str = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
REFRESH_TOKEN_EXPIRE_DAYS: int = 7
TESSERACT_PATH: str = "/usr/bin/tesseract"
MODEL_PATH: str = "models/aadhaar_yolov8s.onnx"
```
Plus a module-level singleton: `settings = Settings()`

### 3. Do Not Touch
- Do not add any business logic
- Do not import from any other project module

### 4. Acceptance Criteria
- [ ] `from app.core.config import settings; settings.JWT_ALGORITHM == "HS256"` is True
- [ ] Raises `ValidationError` if `DATABASE_URL` env var is missing
- [ ] `pytest tests/test_config.py::test_defaults` passes

### 5. Commit Checkpoint
`feat(core): add Settings config [B-01]`

---

## TASK B-02: Database session
**Status**: TODO  
**File**: `backend/app/core/database.py`  
**Symbol**: `get_db()` generator + `Base` declarative base  
**Depends on**: B-01  
**Estimated scope**: ~25 lines

### 1. Read First
- [ ] Read `backend/app/core/database.py` — confirm empty
- [ ] Read `backend/app/core/config.py` — confirm `settings.DATABASE_URL` exists

### 2. Write Exactly This
- `engine = create_async_engine(settings.DATABASE_URL, echo=False)`
- `AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)`
- `Base = declarative_base()`
- `async def get_db()` — yields an `AsyncSession`, closes on exit

### 3. Do Not Touch
- Do not define any ORM models here — those are Tasks B-03 to B-05
- Do not add migration logic

### 4. Acceptance Criteria
- [ ] `get_db` is an async generator (use `inspect.isasyncgenfunction`)
- [ ] `pytest tests/test_database.py::test_get_db_yields_session` passes

### 5. Commit Checkpoint
`feat(core): add async DB session [B-02]`

---

## TASK B-03: User ORM model
**Status**: TODO  
**File**: `backend/app/models/user.py`  
**Symbol**: `class User(Base)`  
**Depends on**: B-02  
**Estimated scope**: ~30 lines

### 1. Read First
- [ ] Read `backend/app/core/database.py` — import `Base` from here
- [ ] Read `backend/app/models/user.py` — confirm empty

### 2. Write Exactly This
`User` model with columns: `id (UUID PK)`, `email (str, unique, indexed)`, `hashed_password (str)`, `created_at (datetime, server_default=now)`, `is_active (bool, default=True)`. No other columns.

### 3. Do Not Touch
- Do not add `Document` or `ShareToken` models here — those are B-04, B-05
- Do not create an Alembic migration here — that is B-06

### 4. Acceptance Criteria
- [ ] `User.__tablename__ == "users"`
- [ ] `pytest tests/test_models.py::test_user_columns` passes

### 5. Commit Checkpoint
`feat(models): add User ORM model [B-03]`

---

## TASK B-04: Document ORM model
**Status**: TODO  
**File**: `backend/app/models/document.py`  
**Symbol**: `class Document(Base)`  
**Depends on**: B-03  
**Estimated scope**: ~35 lines

### 1. Read First
- [ ] Read `backend/app/models/user.py` — note `User.id` type (UUID) for FK reference

### 2. Write Exactly This
`Document` model: `id (UUID PK)`, `user_id (UUID FK → users.id, cascade delete)`, `encrypted_path (str)`, `forgery_status (str, default="PENDING")`, `field_detections (JSON, nullable)`, `masking_presets (JSON, nullable)`, `created_at (datetime, server_default=now)`.

### 3. Do Not Touch
- Do not add `ShareToken` model here — that is B-05
- Do not modify `user.py`

### 4. Acceptance Criteria
- [ ] `Document.__tablename__ == "documents"`
- [ ] `Document.user_id` has FK constraint to `users.id`
- [ ] `pytest tests/test_models.py::test_document_columns` passes

### 5. Commit Checkpoint
`feat(models): add Document ORM model [B-04]`

---

## TASK B-05: ShareToken ORM model
**Status**: TODO  
**File**: `backend/app/models/share_token.py`  
**Symbol**: `class ShareToken(Base)`  
**Depends on**: B-04  
**Estimated scope**: ~30 lines

### 1. Read First
- [ ] Read `backend/app/models/document.py` — note `Document.id` for FK

### 2. Write Exactly This
`ShareToken` model: `id (UUID PK)`, `document_id (UUID FK → documents.id, cascade delete)`, `token_hash (str)`, `masking_config (JSON)`, `expires_at (datetime)`, `access_count (int, default=0)`, `max_access (int, nullable — None means unlimited)`, `created_at (datetime, server_default=now)`.

Note: the raw token UUID is **never stored** — only `token_hash = bcrypt(token)`.

### 3. Do Not Touch
- Do not add Redis logic — Redis TTL is the live expiry check; this table is for audit log only
- Do not modify `document.py`

### 4. Acceptance Criteria
- [ ] `ShareToken.__tablename__ == "share_tokens"`
- [ ] No `raw_token` column exists
- [ ] `pytest tests/test_models.py::test_share_token_columns` passes

### 5. Commit Checkpoint
`feat(models): add ShareToken ORM model [B-05]`

---

## TASK B-06: Alembic initial migration
**Status**: TODO  
**File**: `backend/alembic/versions/001_initial_schema.py` (auto-generated)  
**Symbol**: `upgrade()` / `downgrade()`  
**Depends on**: B-03, B-04, B-05  
**Estimated scope**: auto-generated

### 1. Read First
- [ ] Confirm all three models (B-03, B-04, B-05) are imported in `backend/app/models/__init__.py`
- [ ] Confirm `alembic.ini` points to `DATABASE_URL`

### 2. Write Exactly This
Run: `alembic revision --autogenerate -m "initial_schema"`
Then inspect the generated file — verify it creates `users`, `documents`, `share_tokens` tables with correct FKs.

### 3. Do Not Touch
- Do not hand-edit the generated SQL unless there is a type error
- Do not run `alembic upgrade head` here — that is a deployment step

### 4. Acceptance Criteria
- [ ] Generated file creates exactly 3 tables
- [ ] `alembic upgrade head` runs without error on a clean DB
- [ ] `alembic downgrade base` drops all 3 tables cleanly

### 5. Commit Checkpoint
`feat(db): add initial Alembic migration [B-06]`

---

## TASK B-07: JWT security utilities
**Status**: TODO  
**File**: `backend/app/core/security.py`  
**Symbol**: `create_access_token()`, `create_refresh_token()`, `verify_token()`, `hash_password()`, `verify_password()`  
**Depends on**: B-01  
**Estimated scope**: ~60 lines

### 1. Read First
- [ ] Read `backend/app/core/security.py` — confirm empty
- [ ] Read `backend/app/core/config.py` — confirm `settings.JWT_SECRET`, `settings.JWT_ALGORITHM`, token expiry fields

### 2. Write Exactly This
Five pure functions, no side effects:
- `hash_password(plain: str) -> str` — bcrypt hash
- `verify_password(plain: str, hashed: str) -> bool` — bcrypt verify
- `create_access_token(subject: str) -> str` — JWT with `exp = now + ACCESS_TOKEN_EXPIRE_MINUTES`
- `create_refresh_token(subject: str) -> str` — JWT with `exp = now + REFRESH_TOKEN_EXPIRE_DAYS`
- `verify_token(token: str) -> str` — decode JWT, return subject string, raise `HTTPException(401)` if invalid/expired

### 3. Do Not Touch
- Do not add any database calls — these are pure crypto utilities
- Do not add any FastAPI route logic

### 4. Acceptance Criteria
- [ ] `verify_token(create_access_token("user-123")) == "user-123"`
- [ ] `verify_token("garbage")` raises `HTTPException` with status 401
- [ ] `verify_password("secret", hash_password("secret")) is True`
- [ ] `pytest tests/test_security.py::test_token_roundtrip` passes
- [ ] `pytest tests/test_security.py::test_invalid_token_raises` passes

### 5. Commit Checkpoint
`feat(core): add JWT + bcrypt security utils [B-07]`

---

## TASK B-08: Auth dependency (get_current_user)
**Status**: TODO  
**File**: `backend/app/api/deps.py`  
**Symbol**: `async def get_current_user(db, token) -> User`  
**Depends on**: B-02, B-03, B-07  
**Estimated scope**: ~30 lines

### 1. Read First
- [ ] Read `core/security.py` — note `verify_token` signature
- [ ] Read `models/user.py` — note `User` columns
- [ ] Read `core/database.py` — note `get_db` signature

### 2. Write Exactly This
A single FastAPI dependency function `get_current_user` that:
1. Extracts Bearer token via `OAuth2PasswordBearer(tokenUrl="/auth/login")`
2. Calls `verify_token(token)` to get user ID
3. Queries DB for `User` with matching `id`
4. Raises `HTTPException(401)` if user not found or `is_active=False`
5. Returns the `User` ORM object

### 3. Do Not Touch
- Do not define auth routes here — those are Task B-09
- Do not add any other dependencies to this file

### 4. Acceptance Criteria
- [ ] Returns `User` object for valid token pointing to existing active user
- [ ] Raises 401 for expired token
- [ ] Raises 401 for valid token but deleted user
- [ ] `pytest tests/test_deps.py::test_valid_token_returns_user` passes
- [ ] `pytest tests/test_deps.py::test_inactive_user_raises` passes

### 5. Commit Checkpoint
`feat(api): add get_current_user dependency [B-08]`

---

## TASK B-09: Auth endpoints
**Status**: TODO  
**File**: `backend/app/api/v1/endpoints/auth.py`  
**Symbol**: `router = APIRouter()` with POST `/register`, `/login`, `/refresh`  
**Depends on**: B-02, B-03, B-07, B-08  
**Estimated scope**: ~80 lines

### 1. Read First
- [ ] Read `core/security.py` — all 5 functions
- [ ] Read `models/user.py` — `User` columns
- [ ] Read `api/deps.py` — `get_current_user` signature
- [ ] Confirm `backend/app/schemas/auth.py` exists (create if not — Pydantic models only)

### 2. Write Exactly This
Three routes on `APIRouter(prefix="/auth", tags=["auth"])`:
- `POST /register` — accepts `{email, password}`, hashes password, creates `User`, returns `{access_token, refresh_token, token_type: "bearer"}`
- `POST /login` — accepts `OAuth2PasswordRequestForm`, verifies password, returns same token shape
- `POST /refresh` — accepts `{refresh_token: str}` in body, calls `verify_token`, returns new `{access_token}`

### 3. Do Not Touch
- Do not add `/me` or `/logout` routes — not in v1 scope
- Do not modify `security.py` or `user.py`

### 4. Acceptance Criteria
- [ ] `POST /auth/register` with valid body returns 200 + both tokens
- [ ] `POST /auth/register` with duplicate email returns 409
- [ ] `POST /auth/login` with wrong password returns 401
- [ ] `POST /auth/refresh` with expired refresh token returns 401
- [ ] `pytest tests/test_auth.py` all 4 cases pass

### 5. Commit Checkpoint
`feat(api): add auth endpoints register/login/refresh [B-09]`

---

## TASK B-10: Document upload endpoint
**Status**: TODO  
**File**: `backend/app/api/v1/endpoints/documents.py`  
**Symbol**: `POST /documents/upload`  
**Depends on**: A-04, A-08, B-08, B-09  
**Estimated scope**: ~60 lines

### 1. Read First
- [ ] Read `services/ai/pipeline.py` — exact signature of `run_pipeline`
- [ ] Read `services/forgery/verdict.py` — exact signature of `get_forgery_verdict`
- [ ] Read `models/document.py` — `Document` columns (especially `forgery_status`, `field_detections`)
- [ ] Read `api/deps.py` — `get_current_user`

### 2. Write Exactly This
Route `POST /documents/upload` that:
1. Accepts `UploadFile` — reject if not `image/jpeg` or `image/png`, return 422
2. Reads file bytes (max 10MB — return 413 if exceeded)
3. Calls `get_forgery_verdict(image_bytes, ocr_aadhaar="")` — before AI pipeline
4. Calls `run_pipeline(image_bytes, settings.MODEL_PATH)` via `BackgroundTasks` — return `202 Accepted` immediately with `document_id`
5. Saves new `Document(user_id, forgery_status, field_detections=None)` to DB — field_detections filled in by background task
6. Returns `{"document_id": str, "forgery_status": str, "status": "processing"}`

### 3. Do Not Touch
- Do not add masking logic here — that is B-11
- Do not add vault encryption here — that is B-13
- Do not write to MinIO in this endpoint

### 4. Acceptance Criteria
- [ ] Returns 401 without valid JWT
- [ ] Returns 422 for non-image file type
- [ ] Returns 413 for file > 10MB
- [ ] Returns 202 with `document_id` for valid image
- [ ] `pytest tests/test_documents.py::test_upload_unauthorized` passes
- [ ] `pytest tests/test_documents.py::test_upload_invalid_type` passes
- [ ] `pytest tests/test_documents.py::test_upload_valid` passes

### 5. Commit Checkpoint
`feat(api): add document upload endpoint [B-10]`

---

## TASK B-11: Masking service
**Status**: TODO  
**File**: `backend/app/services/masking/masker.py`  
**Symbol**: `apply_masking(img: np.ndarray, detections: list[dict], config: dict) -> np.ndarray`  
**Depends on**: A-03  
**Estimated scope**: ~70 lines

### 1. Read First
- [ ] Read `services/ai/field_detector.py` — note detection dict shape `{class_id, bbox, ...}`
- [ ] Read `services/masking/masker.py` — confirm empty

### 2. Write Exactly This
A single function `apply_masking` that applies a black filled rectangle over each detected field based on `config`:

Config schema:
```python
{
  "aadhaar_number": "partial" | "full" | "show",  # partial = XXXX XXXX XXXX + overlay last 4 as text
  "name": True | False,       # True = mask
  "dob": "year" | "full" | "hide",
  "gender": True | False,
  "address": True | False,
  "qr": True | False          # default True (always mask QR by default)
}
```

Returns a new numpy array with rectangles drawn. Does not modify the original image.

Also define `mask_aadhaar_number(raw: str, mode: str) -> str` as a pure helper:
```python
def mask_aadhaar_number(raw: str, mode: str = "partial") -> str:
    digits = raw.replace(" ", "")
    if mode == "full":   return "XXXX XXXX XXXX"
    if mode == "partial": return f"XXXX XXXX {digits[-4:]}"
    return raw  # "show"
```

### 3. Do Not Touch
- Do not add PDF generation here — that is B-12
- Do not make any DB calls

### 4. Acceptance Criteria
- [ ] `mask_aadhaar_number("123456789012", "partial") == "XXXX XXXX 9012"`
- [ ] `mask_aadhaar_number("123456789012", "full") == "XXXX XXXX XXXX"`
- [ ] `apply_masking` returns ndarray of same shape as input
- [ ] `pytest tests/test_masking.py::test_partial_mask` passes
- [ ] `pytest tests/test_masking.py::test_full_mask` passes
- [ ] `pytest tests/test_masking.py::test_output_shape` passes

### 5. Commit Checkpoint
`feat(masking): add field masking service [B-11]`

---

## TASK B-12: Masked PDF generator
**Status**: TODO  
**File**: `backend/app/services/masking/pdf_gen.py`  
**Symbol**: `generate_masked_pdf(masked_img: np.ndarray, timestamp: str) -> bytes`  
**Depends on**: B-11  
**Estimated scope**: ~50 lines

### 1. Read First
- [ ] Read `services/masking/masker.py` — confirm `apply_masking` output is ndarray
- [ ] Confirm `reportlab` is in requirements.txt

### 2. Write Exactly This
Returns PDF as `bytes` (do not write to disk). Must include:
- Masked document image fitted to A4 page (595×842 pt)
- Diagonal watermark text: `"COPY — NOT FOR REUSE"` at 30% opacity, font size 36, rotated 45°
- Footer text at y=30: `f"Shared via DocuShield AI | Single use | {timestamp}"`

### 3. Do Not Touch
- Do not write to disk — caller handles storage
- Do not add QR code generation here — that is B-13

### 4. Acceptance Criteria
- [ ] Returns `bytes` starting with `b'%PDF'`
- [ ] Output file size > 5KB (sanity check that image was embedded)
- [ ] `pytest tests/test_masking.py::test_pdf_returns_bytes` passes
- [ ] `pytest tests/test_masking.py::test_pdf_header` passes

### 5. Commit Checkpoint
`feat(masking): add masked PDF generator [B-12]`

---

## TASK B-13: Share token manager
**Status**: TODO  
**File**: `backend/app/services/sharing/token_manager.py`  
**Symbol**: `create_share_token()`, `get_share_token()`, `revoke_share_token()`, `increment_access()`  
**Depends on**: B-01  
**Estimated scope**: ~70 lines

### 1. Read First
- [ ] Read `backend/app/core/config.py` — confirm `settings.REDIS_URL`
- [ ] Read `backend/app/services/sharing/token_manager.py` — confirm empty

### 2. Write Exactly This
Four functions operating on Redis only (no DB calls in this file):

```python
# Key pattern: share:{uuid4_token}
# Value: JSON { doc_id, user_id, masking_config, access_count, max_access, created_at }

def create_share_token(doc_id, user_id, masking_config, ttl_seconds, one_time=False) -> str
    # generates uuid4 token, sets Redis key with TTL, returns token string

def get_share_token(token: str) -> dict | None
    # returns parsed payload dict, or None if key not found/expired

def revoke_share_token(token: str) -> bool
    # DELetes Redis key, returns True if existed

def increment_access(token: str) -> int
    # atomically increments access_count, returns new count
    # use Redis HINCRBY or JSON patch — do not GET→modify→SET (race condition)
```

### 3. Do Not Touch
- Do not touch the `ShareToken` DB model in this file — audit logging is a separate task
- Do not add any FastAPI route logic

### 4. Acceptance Criteria
- [ ] `get_share_token(create_share_token(...))` returns the original payload
- [ ] `get_share_token("nonexistent")` returns `None`
- [ ] Token expires after TTL (test with `ttl_seconds=1`, sleep 2s)
- [ ] `pytest tests/test_sharing.py::test_create_and_retrieve` passes
- [ ] `pytest tests/test_sharing.py::test_token_expiry` passes
- [ ] `pytest tests/test_sharing.py::test_revoke` passes

### 5. Commit Checkpoint
`feat(sharing): add Redis share token manager [B-13]`

---

## TASK B-14: Public share endpoint
**Status**: TODO  
**File**: `backend/app/api/v1/endpoints/share.py`  
**Symbol**: `GET /share/{token}`  
**Depends on**: B-11, B-12, B-13  
**Estimated scope**: ~50 lines

### 1. Read First
- [ ] Read `services/sharing/token_manager.py` — all 4 functions
- [ ] Read `services/masking/masker.py` — `apply_masking` signature
- [ ] Read `services/masking/pdf_gen.py` — `generate_masked_pdf` signature

### 2. Write Exactly This
Route `GET /share/{token}` (NO auth dependency — this is a public endpoint):
1. Call `get_share_token(token)` — if None → 404
2. Check `max_access`: if `access_count >= max_access` and `max_access is not None` → 410 Gone
3. Retrieve encrypted document from MinIO, decrypt with user's key
4. Apply masking from `payload["masking_config"]`
5. Call `increment_access(token)` atomically
6. Return `{"masked_image_base64": str, "forgery_status": str, "expires_at": str}`

Log: write `ShareAccessLog` to DB (IP, timestamp, token_id) as a background task.

### 3. Do Not Touch
- Do not add JWT auth to this route — it must be publicly accessible
- Do not return the raw (unmasked) document under any circumstance

### 4. Acceptance Criteria
- [ ] Returns 404 for unknown token
- [ ] Returns 410 after one-time token is used once
- [ ] Returns 200 with `masked_image_base64` for valid token
- [ ] Does NOT require Authorization header
- [ ] `pytest tests/test_share.py::test_unknown_token_404` passes
- [ ] `pytest tests/test_share.py::test_one_time_expires` passes
- [ ] `pytest tests/test_share.py::test_no_auth_required` passes

### 5. Commit Checkpoint
`feat(api): add public share endpoint [B-14]`

---

## TRACK C — Mobile (Expo + React Native)

---

## TASK C-01: Session context provider
**Status**: TODO  
**File**: `mobile/ctx.tsx`  
**Symbol**: `SessionProvider`, `useSession()`  
**Depends on**: none  
**Estimated scope**: ~60 lines

### 1. Read First
- [ ] Confirm `expo-secure-store` is in package.json
- [ ] Read `mobile/app/(vault)/_layout.tsx` — it will import `useSession` from this file

### 2. Write Exactly This
React context with `useSession()` hook that exposes `{ session: string|null, signIn(token), signOut(), isLoading: bool }`. Store JWT in `SecureStore.setItemAsync("jwt", token)`. Load on mount.

### 3. Do Not Touch
- Do not add biometric logic here — that is C-02
- Do not add API calls — this is state management only

### 4. Acceptance Criteria
- [ ] `useSession()` returns `null` session before sign-in
- [ ] `signIn("token")` persists to SecureStore
- [ ] `signOut()` clears SecureStore + sets session to null
- [ ] `npx jest mobile/tests/useSession.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add session context provider [C-01]`

---

## TASK C-02: Protected vault layout
**Status**: TODO  
**File**: `mobile/app/(vault)/_layout.tsx`  
**Symbol**: `VaultLayout` default export  
**Depends on**: C-01  
**Estimated scope**: ~25 lines

### 1. Read First
- [ ] Read `mobile/ctx.tsx` — confirm `useSession` exports `session`, `isLoading`
- [ ] Read Expo Router docs pattern: `<Redirect href="/login">` inside layout

### 2. Write Exactly This
Layout component that: shows loading indicator if `isLoading`, redirects to `"/login"` if `!session`, renders `<Stack />` otherwise. Exactly as per Expo Router protected routes pattern.

### 3. Do Not Touch
- Do not add any UI chrome here — just the auth gate
- Do not modify `ctx.tsx`

### 4. Acceptance Criteria
- [ ] Unauthenticated render returns `<Redirect href="/login" />`
- [ ] Authenticated render returns `<Stack />`
- [ ] `npx jest mobile/tests/VaultLayout.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add protected vault layout [C-02]`

---

## TASK C-03: API service client
**Status**: TODO  
**File**: `mobile/services/api.ts`  
**Symbol**: `apiClient` (axios instance with interceptors)  
**Depends on**: C-01  
**Estimated scope**: ~50 lines

### 1. Read First
- [ ] Confirm `axios` is in package.json
- [ ] Read `mobile/ctx.tsx` — understand how to get current token

### 2. Write Exactly This
An axios instance with:
- `baseURL = process.env.EXPO_PUBLIC_API_URL`
- Request interceptor: attach `Authorization: Bearer {token}` from SecureStore
- Response interceptor: on 401 → call `POST /auth/refresh` → retry original request once → if refresh fails, call `signOut()`

### 3. Do Not Touch
- Do not add specific endpoint functions here — those are in `mobile/services/documents.ts` and `mobile/services/auth.ts`
- Do not hardcode any URLs

### 4. Acceptance Criteria
- [ ] Requests include `Authorization` header when token exists
- [ ] 401 triggers a refresh attempt before failing
- [ ] `npx jest mobile/tests/apiClient.test.ts` passes

### 5. Commit Checkpoint
`feat(mobile): add axios API client with refresh interceptor [C-03]`

---

## TASK C-04: Document capture screen
**Status**: TODO  
**File**: `mobile/app/(vault)/capture.tsx`  
**Symbol**: `CaptureScreen` default export  
**Depends on**: C-02, C-03  
**Estimated scope**: ~80 lines

### 1. Read First
- [ ] Read `mobile/services/api.ts` — confirm `apiClient` is importable
- [ ] Confirm `expo-image-picker` is in package.json

### 2. Write Exactly This
Screen with two buttons: "Take photo" (`launchCameraAsync`) and "Choose from gallery" (`launchImageLibraryAsync`). On selection:
1. Show image preview
2. Blur quality check: if image width × height < 300×190px equivalent → show "Image too blurry, retake" toast
3. On confirm: POST to `/documents/upload` via `apiClient`, navigate to `/processing/{document_id}`

### 3. Do Not Touch
- Do not add AI processing UI here — that is C-05
- Do not add masking UI — that is C-06

### 4. Acceptance Criteria
- [ ] "Take photo" button triggers camera permission request
- [ ] Low-quality image shows error message, does not proceed
- [ ] Successful upload navigates to `/processing/{id}`
- [ ] `npx jest mobile/tests/CaptureScreen.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add document capture screen [C-04]`

---

## TASK C-05: AI processing screen
**Status**: TODO  
**File**: `mobile/app/(vault)/processing/[id].tsx`  
**Symbol**: `ProcessingScreen` default export  
**Depends on**: C-04  
**Estimated scope**: ~70 lines

### 1. Read First
- [ ] Read `mobile/services/api.ts`
- [ ] Note: backend returns `202` immediately on upload; this screen polls `GET /documents/{id}` until `field_detections != null`

### 2. Write Exactly This
Screen that polls `GET /documents/{id}` every 2 seconds. Shows step indicator:
- "Checking authenticity…" (while polling)
- "Detecting fields…" (while polling)
- "Ready to customize" (when detections arrive)
Shows forgery badge: ✅ Authentic / ⚠️ Suspicious / ❌ Likely Forged. On ready: navigate to `/masking/{id}`.

### 3. Do Not Touch
- Do not add masking logic — that is C-06
- Stop polling on unmount (cleanup interval)

### 4. Acceptance Criteria
- [ ] Stops polling after 30 seconds (timeout → show error)
- [ ] Clears interval on component unmount
- [ ] Shows correct forgery badge for each status string
- [ ] `npx jest mobile/tests/ProcessingScreen.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add AI processing screen [C-05]`

---

## TASK C-06: Masking UI screen
**Status**: TODO  
**File**: `mobile/app/(vault)/masking/[id].tsx`  
**Symbol**: `MaskingScreen` default export  
**Depends on**: C-05  
**Estimated scope**: ~120 lines

### 1. Read First
- [ ] Read `services/masking/masker.py` — understand config schema shape
- [ ] This screen must match the masking config schema exactly: `{aadhaar_number, name, dob, gender, address, qr}`

### 2. Write Exactly This
Screen with toggle rows per field. Default state: `aadhaar_number="partial"`, `address=true` (masked), `qr=true` (masked), others `false`. On toggle change: POST `PATCH /documents/{id}/mask` with current config, update preview image from response URL. "Share" button navigates to `/share/{id}`.

### 3. Do Not Touch
- Do not add share link generation here — that is C-07
- Do not build the QR display here

### 4. Acceptance Criteria
- [ ] Default state has QR masked on load
- [ ] Toggling a field PATCHes the backend and updates preview
- [ ] "Share" button is disabled until at least one detection exists
- [ ] `npx jest mobile/tests/MaskingScreen.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add masking UI screen [C-06]`

---

## TASK C-07: Share output screen
**Status**: TODO  
**File**: `mobile/app/share/index.tsx`  
**Symbol**: `ShareScreen` default export  
**Depends on**: C-06, B-13, B-14  
**Estimated scope**: ~100 lines

### 1. Read First
- [ ] Read `services/sharing/token_manager.py` — understand token payload shape
- [ ] Confirm `react-native-qrcode-svg` is in package.json

### 2. Write Exactly This
Three-tab screen (TabView): 
- **Link tab**: share URL with copy button, expiry picker (1h/6h/24h/7d), one-time toggle, access count badge, revoke button
- **QR tab**: `<QRCode>` component full-screen, auto-refresh if expired
- **PDF tab**: single "Download PDF" button, shows "Already downloaded" after first use

### 3. Do Not Touch
- Do not add vault list here — that is C-08
- Do not add navigation back to masking (one-way flow)

### 4. Acceptance Criteria
- [ ] Copy button copies the correct share URL to clipboard
- [ ] QR renders the same URL as the Link tab
- [ ] PDF button disabled after first download
- [ ] `npx jest mobile/tests/ShareScreen.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add share output screen [C-07]`

---

## TASK C-08: Vault list screen
**Status**: TODO  
**File**: `mobile/app/(vault)/index.tsx`  
**Symbol**: `VaultScreen` default export  
**Depends on**: C-02  
**Estimated scope**: ~70 lines

### 1. Read First
- [ ] Read `mobile/app/(vault)/_layout.tsx` — confirm auth gate is in place
- [ ] `GET /vault/` returns `[{id, forgery_status, created_at, thumbnail_url}]`

### 2. Write Exactly This
FlatList of document cards. Each card: thumbnail, forgery badge, date, chevron. Pull-to-refresh. Tap → navigate to `/(vault)/[id]`. FAB "+" → navigate to `/capture`.

### 3. Do Not Touch
- Do not add document detail here — that is C-09

### 4. Acceptance Criteria
- [ ] Empty state shows "No documents saved yet" message
- [ ] Pull-to-refresh triggers GET /vault/
- [ ] `npx jest mobile/tests/VaultScreen.test.tsx` passes

### 5. Commit Checkpoint
`feat(mobile): add vault list screen [C-08]`

---

## TRACK D — Integration & QA

---

## TASK D-01: E2E smoke test script
**Status**: TODO  
**File**: `backend/tests/e2e/test_full_flow.py`  
**Symbol**: `test_upload_mask_share_flow()`  
**Depends on**: all A, B, C tasks  
**Estimated scope**: ~80 lines

### 1. Read First
- [ ] Read all endpoint signatures in `api/v1/endpoints/`
- [ ] Confirm test fixture image exists at `tests/fixtures/sample_aadhaar.jpg`

### 2. Write Exactly This
One pytest async test function covering the full happy path:
1. Register user → get tokens
2. Upload test image → get `document_id`
3. Poll until `field_detections != null` (max 30s)
4. Apply masking config (partial Aadhaar, hide address, hide QR)
5. Generate share token (24h, one-time=False)
6. GET `/share/{token}` → assert 200 + `masked_image_base64` in response
7. Assert access count incremented to 1

### 3. Do Not Touch
- Do not add performance benchmarks here — that is D-02
- Do not test error paths here — those are in per-module tests

### 4. Acceptance Criteria
- [ ] Full flow completes under 15s on localhost
- [ ] `pytest tests/e2e/test_full_flow.py::test_upload_mask_share_flow -v` passes

### 5. Commit Checkpoint
`test(e2e): add full upload-mask-share smoke test [D-01]`

---

## TASK D-02: Performance benchmark
**Status**: TODO  
**File**: `backend/tests/e2e/test_performance.py`  
**Symbol**: `test_pipeline_latency()`  
**Depends on**: D-01  
**Estimated scope**: ~40 lines

### 1. Read First
- [ ] Read `test_full_flow.py` — reuse upload fixture

### 2. Write Exactly This
Measure and assert per-stage latencies: forgery check (< 2s), YOLOv8 inference (< 3s), OCR (< 2s), total upload→detections (< 8s). Use `time.perf_counter()` around each backend call. If any assertion fails, print actual timings and suggest optimization.

### 4. Acceptance Criteria
- [ ] Total pipeline (upload → detections ready) < 8 seconds
- [ ] `pytest tests/e2e/test_performance.py -v -s` passes

### 5. Commit Checkpoint
`test(e2e): add pipeline latency benchmark [D-02]`

---

## Execution Order (strict)

```
A-01 → A-02 → A-03 → A-04 → A-05   (AI pipeline, sequential)
A-06 → A-07 → A-08                  (Forgery, sequential)
B-01 → B-02 → B-03 → B-04 → B-05 → B-06 → B-07 → B-08 → B-09  (Backend foundation)
B-10 (needs A-04, A-08, B-08)
B-11 → B-12                          (Masking)
B-13 → B-14 (needs B-11, B-12)
C-01 → C-02 → C-03 → C-04 → C-05 → C-06 → C-07 → C-08  (Mobile, sequential)
D-01 → D-02                          (QA, last)
```

Parallel tracks allowed once foundations are done:
- AI track (A-01 onwards) can run in parallel with Backend foundation (B-01 to B-06)
- Mobile track (C-01) can start once B-09 is DONE
