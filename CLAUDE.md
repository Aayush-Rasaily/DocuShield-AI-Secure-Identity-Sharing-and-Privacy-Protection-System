# CLAUDE.md — DocuShield AI

## Project Identity
- **Name**: DocuShield AI
- **Type**: React Native mobile app + FastAPI backend
- **Stage**: Phase 1 — CMRIT BAD685 Project (AI & DS, 3rd year)
- **Owner**: CMRIT Department of AI & Data Science

## What This Project Does
AI-powered identity document protection and secure sharing. Users upload Aadhaar cards, the system auto-detects PII fields via YOLOv8 + Tesseract OCR, lets the user selectively mask fields, then generates shareable outputs (time-limited link / QR / one-time masked PDF). Documents stored in an encrypted personal vault.

## Stack at a Glance
```
Mobile:    React Native (Expo)
Backend:   FastAPI (Python 3.11+)
AI:        YOLOv8 (Ultralytics) + Tesseract OCR + OpenCV
DB:        PostgreSQL
Storage:   MinIO (S3-compatible, self-hosted)
Cache:     Redis (share token TTL)
Auth:      JWT (access 15min / refresh 7d) + Biometric
```

## Repo Structure
```
docushield-ai/
├── CLAUDE.md                    ← you are here
├── DOCUSHIELD_PRD.md
├── .agent/
│   ├── INDEX.md
│   ├── GETSHITDONE.md           ← GSD workflow + task contracts
│   ├── ROADMAP.md
│   └── skills/
├── mobile/
│   ├── app/
│   │   ├── (auth)/
│   │   ├── (vault)/
│   │   └── share/
│   ├── components/
│   ├── hooks/
│   ├── services/
│   └── utils/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── models/
│   │   ├── schemas/
│   │   └── services/
│   │       ├── ai/
│   │       ├── masking/
│   │       ├── forgery/
│   │       └── sharing/
│   ├── models/
│   └── tests/
└── docker-compose.yml
```

---

## GET-SHIT-DONE (GSD) Workflow — MANDATORY

> This is not optional. Every task in this project must follow the GSD atomic protocol.
> It exists to prevent the #1 cause of AI coding failure: doing too much at once without reading first.

### Why it exists
AI agents hallucinate when tasks are vague, scoped too broadly, or executed without reading existing code first. The GSD workflow enforces:
- **One task = one file = one function/class** at a time
- **Read before write** — always inspect the target file before modifying
- **Explicit acceptance criteria** — every task has a verifiable pass/fail test
- **Hard "do not touch" boundaries** — prevents scope bleed into unrelated files
- **No skipping** — each task gate must pass before the next begins

---

### The GSD Task Contract Format

Every task must be written and executed in this exact structure:

```
## TASK [ID]: [Task Name]
**Status**: TODO | IN_PROGRESS | DONE | BLOCKED
**File**: `path/to/exactly/one/file.py`
**Symbol**: the single function, class, or component being written
**Depends on**: [Task IDs that must be DONE first] | none
**Estimated scope**: ~N lines

### 1. Read First (mandatory — do not skip)
- [ ] Read `[file]` in full before writing anything
- [ ] Read `[dependency file]` to understand the interface you're calling
- [ ] Confirm: does `[symbol]` already exist? If yes — stop and report, do not overwrite

### 2. Write Exactly This
[Precise description of what to implement — function signature, input/output contract,
error cases to handle, and nothing else]

### 3. Do Not Touch
- Do not modify `[other file]` — that's Task [X]
- Do not add new DB columns — schema is locked until Task [Y]
- Do not create new routes — only the function body belongs here

### 4. Acceptance Criteria
- [ ] [Specific assertion: e.g. "returns 'XXXX XXXX 1234' when input is '1234 5678 9012' and mode='partial'"]
- [ ] [Test command: e.g. `pytest tests/test_masking.py::test_partial_mask -v` passes]
- [ ] [No regressions: e.g. "all existing tests in tests/test_masking.py still pass"]

### 5. Commit Checkpoint
- Commit message: `feat(masking): add partial Aadhaar mask [Task-ID]`
- Do NOT bundle with other changes
```

---

### GSD Rules for Claude — Non-Negotiable

**Before every task:**
1. Read `.agent/INDEX.md` to confirm current project state
2. Read `.agent/GETSHITDONE.md` to find the next `TODO` task
3. Confirm all `Depends on` tasks are marked `DONE`
4. Read the target file before writing a single line

**During every task:**
5. Touch **one file only** per task — if a second file needs changing, that is a new task
6. Write **only the symbol specified** — do not refactor surrounding code
7. If the file doesn't exist yet, create it with only the required imports + the one symbol
8. If you discover the task requires changing the contract (different signature, new import), **stop and report** — do not silently adapt

**After every task:**
9. Run the exact acceptance test command — do not mark DONE without running it
10. Update task status in `.agent/INDEX.md` to `DONE`
11. Write one commit with the exact message format from the task contract

**Never:**
- Never implement more than what the task contract specifies
- Never skip the "Read First" step
- Never assume a function exists without reading the file
- Never mark a task DONE without running its acceptance test
- Never combine two tasks into one commit

---

## Critical Domain Rules (Always Active)

These apply to every task in this project, regardless of what the task contract says:

1. **Never store plaintext Aadhaar numbers** in logs, DB fields, or response bodies — masked versions only
2. **All `/documents/*` and `/vault/*` endpoints must be auth-gated** — `Depends(get_current_user)` on every handler
3. **Share tokens live in Redis only** — do not add a `share_tokens` DB table or poll the DB for expiry
4. **YOLOv8 inference is server-side only** in v1 — never send model weights to the mobile client
5. **Tesseract must be called with** `lang='hin+eng'` — bare `lang='eng'` will silently drop Hindi text
6. **Preprocessing pipeline is mandatory** before ONNX inference — raw image input to YOLOv8 will degrade accuracy below acceptable threshold
7. **Address class (id=4) always needs regex post-processing** — raw OCR output is unreliable for this class

---

## Skills

Load these before starting any task. Full bodies at:

| Skill | Path | Load for |
|-------|------|----------|
| `python-fastapi-development` | `~/.gemini/antigravity/skills/python-fastapi-development/SKILL.md` | All Track B tasks |
| `async-python-patterns` | `~/.gemini/antigravity/skills/async-python-patterns/SKILL.md` | Track B alongside FastAPI |
| `react-native-architecture` | `~/.gemini/antigravity/skills/react-native-architecture/SKILL.md` | All Track C tasks |
| `python-testing-patterns` | `~/.gemini/antigravity/skills/python-testing-patterns/SKILL.md` | All Track D tasks |
| `fastapi-pro` | `~/.gemini/antigravity/skills/fastapi-pro/SKILL.md` | FastAPI backend, JWT auth, middleware |
| `api-security-best-practices` | `~/.gemini/antigravity/skills/api-security-best-practices/SKILL.md` | Security headers, input validation, rate limiting |
| `auth-implementation-patterns` | `~/.gemini/antigravity/skills/auth-implementation-patterns/SKILL.md` | OAuth2, JWT, RBAC implementation |
| `postgres-best-practices` | `~/.gemini/antigravity/skills/postgres-best-practices/SKILL.md` | RLS policies, database security |
| `nextjs-supabase-auth` | `~/.gemini/antigravity/skills/nextjs-supabase-auth/SKILL.md` | Frontend auth integration |
| `api-documentation-generator` | ` ~/.gemini/antigravity/skills/api-documentation-generator/SKILL.md` | OpenAPI/Swagger documentation |

**Do NOT load:**

- `ai-ml` skill — LLM-focused, wrong paradigm for Track A (CV/OCR work)

**Track A has no skill coverage.** For tasks A-01 through A-08, follow the
contracts in `.agent/GETSHITDONE.md` literally. Do not infer CV/OCR patterns
from LLM experience. When uncertain, ask rather than guess.

---

## Key Files
- PRD + GSD workflow: `DOCUSHIELD_PRD.md` → Section 13
- Task contracts: `.agent/GETSHITDONE.md`
- Agent state tracker: `.agent/INDEX.md`
- 4-week roadmap: `.agent/ROADMAP.md`
