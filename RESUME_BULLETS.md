# Murmur Resume Bullets

Three honest options. Each line stays outcome-first and avoids invented scale.

## Bullets

1. **Engineered** an on-device RAG flow for voice memos using semantic retrieval, hybrid ranking, and grounded answers with source citations.
2. **Shipped** a shared SwiftUI app core for iPhone, Mac, and Watch, adding Siri/Shortcuts intents, macOS commands, live transcription, and SQLite-backed persistence.
3. **Hardened** privacy and delivery with AES-GCM ciphertext-only sync, Keychain-held keys, 58 automated tests, and a 2,805 inserts/sec local benchmark.

## Verb Duplication Audit
- Bullet 1 opening verb: `Engineered`
- Bullet 2 opening verb: `Shipped`
- Bullet 3 opening verb: `Hardened`
- No opening verb is repeated.
- `Shipped` is the most common resume verb of the three; if you want a less generic tone, swap it for `Architected` or `Built`.

## Evidence Notes
- Benchmark number comes from `swift run -c release MurmurBench 2000 200` on the host.
- Test count is 44 Swift package tests + 11 macOS app tests + 3 Go tests.
- Coverage was remeasured after the final code changes and is documented in `PROJECT_BRIEF.md`.
