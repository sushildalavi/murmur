# Murmur Project Brief

Audited 2026-06-03. Every claim below is backed by tracked source, tests, git history, or a command I ran in this repo.

## One-Line Summary
Murmur is a privacy-first voice memo app for iPhone, Mac, and Apple Watch that records, transcribes, searches, summarizes, and answers questions about memos entirely on device, with an opt-in encrypted sync server for ciphertext-only backup.

## Problem It Solves
Voice memos are hard to search and hard to use later. Murmur turns spoken notes into structured, searchable, answerable records without shipping raw content off the device.

## Full Tech Stack
- Swift 5.10 package plus Xcode-generated app targets.
- SwiftUI, Observation, AppIntents, AVFoundation, Speech, NaturalLanguage, CryptoKit, FoundationModels, SQLite3, Security.
- Go 1.25 sync server using `net/http`, `database/sql`, and `pgx/v5`.
- XcodeGen for project generation.
- GitHub Actions for CI.
- Docker for the Go service.
- No CocoaPods, no `Podfile`, no third-party Swift packages, and no SwiftData in tracked source.

## Architecture
- `MurmurCore` is a UI-free Swift package that owns audio, transcription, persistence, search, summarization, RAG, crypto, sync, metrics, and App Intents.
- `MurmurApp` is the shared SwiftUI app target for iOS and macOS, with `@Observable` view models and platform-conditional shells (`TabView` on iOS, `NavigationSplitView` on macOS).
- `MurmurWatchApp` is a standalone watchOS capture app with its own container and record view model.
- `server/` is a small Go HTTP service that stores only ciphertext blobs and timestamps.

### Data Flow
Record session -> `AVAudioEngine` tap -> `AsyncStream<Double>` levels and `AsyncStream<TranscriptSegment>` live transcript -> `MemoStore` -> `SQLiteMemoStore` -> hybrid Library search and memo metrics -> `IntelligentSummarizer` for insights -> `MemoAnswerService` for on-device RAG -> optional `MemoSyncService` -> Go server.

### Concurrency Model
- The codebase is mostly `@MainActor` view models plus `async/await` and `AsyncStream` for streaming audio/transcript data.
- `SQLiteMemoStore` serializes access on a private `DispatchQueue` and is marked `@unchecked Sendable`.
- `SemanticMemoIndex` uses `NSLock` for cache access and is also `@unchecked Sendable`.
- The only actor in tracked source is `InMemorySyncClient`, a test double.

### On-Device vs Network
- On-device: recording, transcript capture, transcript fallback, SQLite persistence, FTS5 search, embeddings, semantic ranking, hybrid ranking, metrics, summarization fallback, and the Apple Intelligence code path when the OS/model is available.
- Network: only the opt-in sync path via `HTTPSyncClient` (`URLSession`). The app passes `MURMUR_SYNC_URL` and optional `MURMUR_SYNC_TOKEN` to enable it.

## Built vs Not Built
### Fully implemented and tested
- SQLite persistence with WAL, FTS5, durability across store instances, and injection-safe query construction.
- On-device embeddings with `NLEmbedding`, cosine similarity, semantic search, and reciprocal-rank fusion with keyword search.
- Memo summarization and top-keyword extraction.
- RAG answer retrieval with semantic top-k selection and an extractive fallback.
- AES-GCM memo encryption with Keychain-backed symmetric key storage and a ciphertext-only sync contract.
- Live recording, streaming transcript capture, save flow, playback support, metrics, and swipe-to-delete library behavior.
- App Intents now perform work and are registered through an `AppShortcutsProvider`; the intent surface covers start/stop recording, search, ask, summarize latest, extract action items, sync, and delete, and the macOS app adds command-menu shortcuts for start/stop recording.
- Go sync server with bearer-token auth, plus tests for health, blob lifecycle, and auth.

### Implemented but not runtime-verified in this audit
- The Apple Intelligence generation path for insights and RAG answers is present in code and gated by `canImport(FoundationModels)` and `@available`, but this audit did not run it on a model-capable device.

### Not present or not verified, so do not claim it
- User adoption, downloads, DAU, retention, or production launch.
- Device performance numbers for transcription or capture.
- A third-party security audit.
- SwiftData usage.
- Third-party Swift dependencies.
- Speaker diarization source in tracked code.
- VisionOS, tvOS, or iPad-specific targets beyond the iPhone/macOS/watchOS setup in the repo.

## Measurable Metrics
- Git history: 115 commits, single author (`sushildalavi`), date range 2026-06-02 to 2026-06-03.
- Tracked Swift code: 4,354 source LOC in 53 source files, plus 706 test LOC in 5 test files, for 5,060 Swift lines total across 58 Swift files.
- Other tracked code/config: Go 414 LOC, SQL 19 LOC, YAML 160 LOC.
- Tests I ran successfully: 44 Swift package tests, 11 macOS app tests, and 3 Go tests, for 58 total test cases.
- Coverage I measured: MurmurCore package line coverage 68.99% and function coverage 78.52% from `swift test --enable-code-coverage` plus `llvm-cov report`.
- Benchmark I ran: `swift run -c release MurmurBench` on the host with 2,000 synthetic memos and 200 queries produced 2,805 inserts/sec, search p50 7.285 ms, search p95 18.231 ms, max 189.505 ms, and database size 1,328 KB.
- Target platforms: iOS 17+, macOS 14+, watchOS 10+.

## Hardest Problems Solved
1. CI-safe Apple Intelligence integration, by wrapping FoundationModels code in `#if canImport(FoundationModels)` and `@available` gates so the package still builds on the CI SDK.
2. Direct SQLite + FTS5 persistence, by hand-writing the C API layer, WAL pragmas, JSON transcript storage, and injection-safe prefix search.
3. Hybrid retrieval, by combining FTS5 keyword ranking and `NLEmbedding` semantic ranking with reciprocal-rank fusion.
4. Streaming recording flow, by bridging AVFoundation and Speech into async streams so the UI can show live transcript and audio level updates.
5. Ciphertext-only sync, by encrypting memos with AES-GCM, storing the key in the Keychain, and verifying with tests that the payload does not leak plaintext.
6. Cross-target app reuse, by pushing domain logic into a shared package and keeping the app targets as thin SwiftUI shells.
7. Intent routing for Siri/Shortcuts, by adding a deterministic classifier for start/stop/search/ask/summarize/sync/delete phrases, resulting in a reusable fallback path when generative routing is unavailable.

## Interview Talking Points
1. I built an on-device RAG flow over voice memos, which required semantic retrieval, keyword fallback, and a grounded answer path, resulting in natural-language question answering over local memos.
2. I implemented SQLite persistence directly on the system `sqlite3` API, which required WAL setup, FTS5 maintenance, and manual query binding, resulting in durable local search without third-party dependencies.
3. I fused semantic and keyword ranking, which required caching `NLEmbedding` vectors and combining scores with reciprocal-rank fusion, resulting in search that matches both intent and exact terms.
4. I added ciphertext-only sync, which required AES-GCM encryption plus Keychain-held keys and server-side bearer-token auth, resulting in a network path that stores encrypted blobs instead of plaintext memos.
5. I modeled recording as async streams, which required bridging AVFoundation and Speech callbacks into `AsyncStream`, resulting in live transcript updates and a stop flow that reuses captured transcript instead of re-transcribing by default.
6. I registered real App Intents and shortcuts, which required a notification bridge into the SwiftUI shell plus a macOS command menu, resulting in Siri/Shortcuts actions that can start/stop recording, search, ask, summarize, sync, and delete memos.
7. I wired the repo for repeatable CI, which required XcodeGen project generation and platform-specific GitHub Actions jobs, resulting in package, app, and server tests that all run on push.
8. I added a labeled retrieval evaluation, which required a low-overlap query set and explicit Recall@k/MRR thresholds, resulting in a measurable guardrail for semantic search quality.

## Audit Notes
- The README contains stronger wording than this audit can independently verify for Apple Intelligence generation, so I have treated that path as implemented but not runtime-verified here.
- There is no SwiftData code in tracked source; the persistence layer is SQLite via `sqlite3` and FTS5.
