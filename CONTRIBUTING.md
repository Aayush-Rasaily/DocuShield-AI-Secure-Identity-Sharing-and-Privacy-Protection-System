# Contributing to DocuShield AI

## Team
| Role | GitHub |
|---|---|
| Dev | [@Manzil777](https://github.com/Manzil777) |
| Dev | [@Aayush-Rasaily](https://github.com/Aayush-Rasaily) |

---

## Branch Strategy

```
main        ← stable, working code only
dev         ← integration branch (merge features here first)
feat/*      ← individual feature branches
fix/*       ← bug fixes
exp/*       ← experiments / notebooks (no review required)
```

**Never push directly to `main`.** All changes go through a PR.

---

## Workflow

```bash
# 1. Always branch off dev
git checkout dev
git pull origin dev
git checkout -b feat/your-feature-name

# 2. Work, commit often
git add .
git commit -m "feat: short description of what you did"

# 3. Push and open a PR → dev
git push origin feat/your-feature-name
```

Then open a Pull Request on GitHub: `feat/your-feature-name` → `dev`.

When `dev` is stable and tested, one of you merges `dev` → `main`.

---

## Commit Message Format

```
feat: add aadhaar OCR extraction
fix: correct regex for PAN number
refactor: clean up masking pipeline
docs: update README setup steps
exp: test easyocr vs tesseract accuracy
```

---

## Module Ownership (suggested)

| Module | Owner |
|---|---|
| `src/ocr/` | Discuss & split |
| `src/masking/` | Discuss & split |
| `src/detection/` | Discuss & split |
| `src/sharing/` | Discuss & split |
| `notebooks/` | Both freely |

---

## PR Rules

- At least one approval before merging to `dev`
- Keep PRs small and focused — one feature at a time
- Link to any relevant issue or task in the PR description

---

## ⚠️ Data Privacy Rule

**Never commit real identity documents** (Aadhaar, PAN, Passport scans, etc.) to this repo — real or otherwise. Use only synthetic/anonymized samples in `data/samples/`. The `.gitignore` enforces this, but stay mindful.
