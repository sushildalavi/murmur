# Murmur — Resume Bullets

Three options. Outcome-first, one line, honest (no fabricated scale/users). Pick 1–2, or use all three. Metrics are measured, not estimated.

## Bullets

1. **Engineered** an on-device RAG feature (NaturalLanguage embeddings + rank-fusion search + Apple Foundation Models) that answers natural-language questions over voice memos with cited sources — no third-party dependencies.

2. **Built** native iPhone, Mac, and Apple Watch apps from one shared, UI-free Swift core, backed by a hand-written SQLite + FTS5 store benchmarked at ~4,200 inserts/sec and <10 ms p95 search.

3. **Hardened** delivery with 35 tests, ~55% core-package coverage, and a build-failing CI check that synced data is always ciphertext (AES-GCM, Keychain-held keys).

## Verb-duplication audit
| Bullet | Opening verb | Note |
|---|---|---|
| 1 | Engineered | Strong, specific, not overused. ✅ |
| 2 | Built | Common/slightly weak resume verb. Consider **Architected** or **Shipped** if "Built" appears elsewhere on the résumé. ⚠️ |
| 3 | Hardened | Strong, distinct, signals quality/testing. ✅ |

- No verb is repeated across these three.
- Only flag: **"Built"** is the one conventional verb here — swap to "Architected"/"Shipped" if your résumé already uses "Built"/"Developed"/"Created" nearby.

## Notes on honesty
- All numbers are measured on 2026-06-03 (LOC, test count, coverage via `llvm-cov`, benchmark via `MurmurBench`). They are host/engine numbers and a solo project's metrics — not production/device/user metrics.
- Do **not** add user counts, adoption, or feedback — there are none (see CANNOT-VERIFY notes).
- Avoid claiming "Siri/Shortcuts" or "speaker diarization" — those are stubs in this codebase.
