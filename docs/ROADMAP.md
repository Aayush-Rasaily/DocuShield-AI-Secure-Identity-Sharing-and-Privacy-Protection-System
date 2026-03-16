# DocushieldAI — 4-Week Development Roadmap

> **Collaborators:** @Manzil777 (AI lead) · @Aayush-Rasaily (Backend / Mobile)
>
> All tasks below are tracked as GitHub Issues.  
> Run the **Setup Project Management Artifacts** workflow once to create all
> milestones, labels, and issues automatically.

---

## Milestone Summary

| Milestone | Due date | Description |
|-----------|----------|-------------|
| Week 1 — AI Pipeline Foundation | 2026-03-22 | Dataset, YOLOv8 training, OCR, backend & mobile scaffold |
| Week 2 — Backend Core + Model Tuning | 2026-03-29 | ONNX export, forgery/QR modules, JWT auth, REST endpoints |
| Week 3 — Mobile UI + Sharing Engine | 2026-04-06 | Camera, masking UI, vault, share tokens, masked PDF |
| Week 4 — Integration, Testing, Demo | 2026-04-13 | E2E tests, benchmarks, AI eval, security audit, submission |

---

## Label Reference

| Label | Colour | Meaning |
|-------|--------|---------|
| `ai` | blue | AI / ML tasks |
| `backend` | yellow | FastAPI + database |
| `mobile` | red | Expo / React Native |
| `infra` | green | Docker, CI/CD, tooling |
| `test` | grey | Tests, QA, benchmarks |
| `week-1` | dark-red | Due Week 1 |
| `week-2` | red-orange | Due Week 2 |
| `week-3` | amber | Due Week 3 |
| `week-4` | green | Due Week 4 |

---

## Week 1 — AI Pipeline Foundation (due 2026-03-22)

| # | Task | Assignee | Labels |
|---|------|----------|--------|
| 1 | Download Aadhaar dataset from Roboflow | @Manzil777 | `ai` `week-1` |
| 2 | Create dataset YAML and verify class labels | @Manzil777 | `ai` `week-1` |
| 3 | Run baseline YOLOv8-small training (100 epochs) | @Manzil777 | `ai` `week-1` |
| 4 | Add data augmentation: glare, blur, skew, crop | @Manzil777 | `ai` `week-1` |
| 5 | Implement preprocessing pipeline in OpenCV | @Manzil777 | `ai` `week-1` |
| 6 | Integrate Tesseract OCR (lang: hin+eng) | @Manzil777 | `ai` `week-1` |
| 7 | Build regex post-processor for each field class | @Manzil777 | `ai` `week-1` |
| 8 | Set up FastAPI project scaffold + Docker Compose | @Aayush-Rasaily | `backend` `infra` `week-1` |
| 9 | Set up Expo Router project with route groups | @Aayush-Rasaily | `mobile` `week-1` |
| 10 | Write unit tests for preprocessing + OCR pipeline | @Aayush-Rasaily | `test` `week-1` |

---

## Week 2 — Backend Core + Model Tuning (due 2026-03-29)

| # | Task | Assignee | Labels |
|---|------|----------|--------|
| 11 | Export best.pt to ONNX and validate inference | @Manzil777 | `ai` `week-2` |
| 12 | Build ELA forgery detection module | @Manzil777 | `ai` `week-2` |
| 13 | Build QR code payload validator | @Manzil777 | `ai` `week-2` |
| 14 | Implement JWT auth: register, login, refresh | @Aayush-Rasaily | `backend` `week-2` |
| 15 | POST /documents/upload — file + AI pipeline | @Aayush-Rasaily | `backend` `ai` `week-2` |
| 16 | POST /documents/{id}/mask — apply masking config | @Aayush-Rasaily | `backend` `week-2` |
| 17 | SQLAlchemy models: User, Document, VaultItem, ShareToken | @Aayush-Rasaily | `backend` `week-2` |
| 18 | Auth screens: Login + Register in Expo Router | @Aayush-Rasaily | `mobile` `week-2` |
| 19 | API integration tests: auth + upload + mask | @Manzil777 | `test` `week-2` |

---

## Week 3 — Mobile UI + Sharing Engine (due 2026-04-06)

| # | Task | Assignee | Labels |
|---|------|----------|--------|
| 20 | Camera capture screen with image quality check | @Aayush-Rasaily | `mobile` `week-3` |
| 21 | AI processing loader screen | @Aayush-Rasaily | `mobile` `week-3` |
| 22 | Masking toggle UI with live document preview | @Aayush-Rasaily | `mobile` `week-3` |
| 23 | Vault CRUD: encrypt + store in MinIO | @Manzil777 | `backend` `week-3` |
| 24 | Share token engine: Redis TTL + link + QR | @Manzil777 | `backend` `week-3` |
| 25 | Masked PDF generator with watermark | @Manzil777 | `backend` `week-3` |
| 26 | Share screen: link + QR fullscreen + PDF button | @Aayush-Rasaily | `mobile` `week-3` |
| 27 | Vault list screen + document detail + share log | @Aayush-Rasaily | `mobile` `week-3` |
| 28 | GET /share/{token} — public share endpoint | @Manzil777 | `backend` `week-3` |

---

## Week 4 — Integration, Testing, Demo (due 2026-04-13)

| # | Task | Assignee | Labels |
|---|------|----------|--------|
| 29 | Full E2E smoke test: upload → mask → share → view | @Aayush-Rasaily | `test` `week-4` |
| 30 | Performance benchmarks: end-to-end ≤ 8s on 4G | @Manzil777 | `test` `week-4` |
| 31 | AI evaluation report: mAP-50, TRA per class | @Manzil777 | `ai` `week-4` |
| 32 | Security audit: auth, token expiry, encryption | @Aayush-Rasaily | `test` `infra` `week-4` |
| 33 | Update .agent/INDEX.md with final state + decisions | @Manzil777 | `infra` `week-4` |
| 34 | BAD685 submission: report + demo video | @Manzil777 | `infra` `week-4` |
| 35 | Phase 2 kickoff: PAN card dataset research | @Aayush-Rasaily | `ai` `week-4` |

---

## Assignment Distribution

| Collaborator | Count | Primary focus |
|---|---|---|
| @Manzil777 | 19 tasks | AI/ML (issues 1–7, 11–13, 19, 23–25, 28, 30–31, 33–34) |
| @Aayush-Rasaily | 16 tasks | Backend + Mobile (issues 8–10, 14–18, 20–22, 26–27, 29, 32, 35) |

---

## Quick Start

### Trigger the setup workflow (recommended)

1. Open **Actions** → **Setup Project Management Artifacts**
2. Click **Run workflow** → **Run workflow**
3. All 4 milestones, 9 labels, and 35 issues will be created automatically.

### Run locally

```bash
gh auth login          # authenticate once
python3 .github/scripts/setup_project.py
```

Set `DRY_RUN=true` to preview without making changes:

```bash
DRY_RUN=true python3 .github/scripts/setup_project.py
```

---

*Generated for BAD685 — DocushieldAI Phase 1*
