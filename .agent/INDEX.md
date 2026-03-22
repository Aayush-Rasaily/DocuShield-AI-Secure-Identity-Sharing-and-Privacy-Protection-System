# .agent/INDEX.md — DocuShield AI Agent Index

## What is this?
This folder is the agent operating context for DocuShield AI. Any Claude agent working in this repo should read this file before anything else.

## Current State (Phase 1 — Kickoff)
- [ ] YOLOv8 model: not yet trained (needs Aadhaar dataset)
- [ ] OCR pipeline: scaffolded, not integrated
- [ ] FastAPI backend: not started
- [ ] React Native app: not started
- [ ] Vault encryption: not started
- [ ] Share engine: not started

## Active Work Streams
| Stream | Owner | Status |
|--------|-------|--------|
| AI pipeline (YOLOv8 + Tesseract) | TBD | Not started |
| Backend (FastAPI) | TBD | Not started |
| Mobile app (RN/Expo) | TBD | Not started |
| Forgery detection | TBD | Not started |

## Decision Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-16 | YOLOv8 as detection backbone | mAP-50 92.5% on Aadhaar fields (NetraAadhaar, IEEE Access 2025); best speed/accuracy tradeoff at 160 FPS vs Faster-RCNN at 10 FPS |
| 2026-03-16 | Tesseract over EasyOCR/Google Vision | Offline, free, high privacy — critical for identity docs (NetraAadhaar Table 5) |
| 2026-03-16 | FastAPI over Django | Async-native, lighter footprint, Python-native (same as AI stack) |
| 2026-03-16 | Server-side inference in v1 | React Native ONNX runtime integration deferred to v2 |
| 2026-03-16 | MinIO over AWS S3 | Full data sovereignty; no cloud vendor holding identity documents |

## Key Research References
- NetraAadhaar (IEEE Access 2025) — YOLOv8 + Tesseract on Aadhaar
- Mero Nagarikta (IOE, 2024) — Flutter + Django + YOLOv8 on Nepali citizenship
- Hybrid OCR+Regex PII Tool (IJARIIE 2025) — masking + deepfake detection
- Fake Aadhaar Detection Review (IJRTI 2025) — CNN + ELA forgery pipeline

## Quick Links
- PRD → `../DOCUSHIELD_PRD.md`
- How to run → `GETSHITDONE.md`
- Stack details → `../CLAUDE.md`
