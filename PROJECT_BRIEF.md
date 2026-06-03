# Murmur — Project Brief

> Factual context doc. Every claim below is backed by code, git history, tests, or a measured number. Audited 2026-06-03.

## One-line summary
A privacy-first, on-device voice-memo app for iPhone, Mac, and Apple Watch (SwiftUI) that records, transcribes, semantically searches, summarizes, and answers questions about your memos — with an opt-in encrypted sync server.

## Problem it solves
Voice notes are useful only if you can find and reason over them later. Murmur makes spoken notes searchable by meaning and answerable in natural language, while keeping audio, transcripts, and derived data on device (sync, when enabled, is ciphertext-only).

## Tech stack (verified)
- **Languages:** Swift (~4,950 LOC / 61 files incl. tests), Go (357 LOC, sync server), SQL (1 migration).
- **UI:** SwiftUI (iOS 17, macOS 14, watchOS 10 deployment targets).
- **Apple frameworks used (confirmed by imports):** AVFoundation (`AVAudioEngine`), Speech (`SFSpeechRecognizer`), CryptoKit (AES-GCM), NaturalLanguage (`NLEmbedding`), FoundationModels (Apple Intelligence), AppIntents, Observation (`@Observable`), SwiftUI.
- **Persistence:** raw **SQLite via the system `sqlite3` C API + FTS5** (NOT SwiftData/Core Data — 0 SwiftData references in the codebase).
- **Dependencies:** **none third-party.** No CocoaPods, no Carthage, no remote SwiftPM packages (`XCRemoteSwiftPackageReference` count = 0). Only the system `sqlite3` library is linked.
- **Build:** Xcode project generated from `project.yml` via XcodeGen. Go server is Dockerized.

## Architecture
- **`MurmurCore` (UI-free Swift package):** all domain logic — Audio, Transcription, Persistence (SQLite/FTS5), Search (FTS + embeddings + RRF), Summarization (heuristic + FoundationModels), RAG (`MemoAnswerService`), Crypto, Sync, Store, Metrics.
- **`MurmurApp` (iOS + macOS):** thin SwiftUI shells, `@Observable` MVVM view models. iOS uses `TabView`; macOS uses `NavigationSplitView`. Same sources, platform-conditional shells.
- **`MurmurWatchApp` (watchOS):** standalone quick-capture app (`WKApplication`/`WKWatchOnly`).
- **`server/` (Go):** stores `SyncBlob` ciphertext + minimal metadata; has a small test suite.

### Data flow
Record (`AVAudioEngine` tap → `AsyncStream<Double>` levels + `AsyncStream<TranscriptSegment>` live transcript) → save `Memo` to `SQLiteMemoStore` (write-through) → Library/Search (FTS5 keyword + `NLEmbedding` semantic, fused by Reciprocal Rank Fusion) → Insights (`FoundationModels` guided generation) → Ask/RAG (semantic retrieval → `FoundationModels` grounded answer + citations).

### Concurrency model (verified, precise)
Primarily **`@MainActor` isolation** (22 annotations) + **async/await** + **`AsyncStream`** (29 uses) for the streaming audio/transcript pipeline. **One actor** in the codebase (`InMemorySyncClient`, a test double). `SQLiteMemoStore` and `SemanticMemoIndex` are `@unchecked Sendable` and serialize access with a `DispatchQueue`/`NSLock`. It is a structured-concurrency design, not a heavily actor-based one.

### On-device vs network
- **On-device:** recording, transcription (prefers on-device: sets `requiresOnDeviceRecognition = true` when `supportsOnDeviceRecognition`), persistence, search, embeddings, summaries, RAG. No analytics/telemetry.
- **Network:** exactly one path — `HTTPSyncClient` (`URLSession`), used only by opt-in encrypted sync (enabled when `MURMUR_SYNC_URL` is set). It is the only `URLSession`/`URLRequest` in non-test source.

## Built vs. NOT built (honest status)
**Fully implemented & tested:**
- SQLite + FTS5 store (CRUD, WAL pragmas, injection-safe MATCH, durability across instances).
- On-device embeddings (`NLEmbedding`, 512-d) + cosine semantic ranking + RRF hybrid fusion.
- RAG retrieval (semantic top-k) + extractive fallback; generation path wired to FoundationModels.
- AES-GCM encrypt/decrypt round-trip; sync service (encrypt → push); Go server round-trip (mocked URLProtocol test).
- Live recording (`AVAudioEngine`) and live + file transcription (`SFSpeechRecognizer`).
- Heuristic summarizer; metrics aggregation; audio playback; hybrid Library search; swipe-to-delete.

**Implemented but only manually verified once (not in CI):**
- FoundationModels generation (Insights + RAG answers). CI's SDK lacks the model, so CI exercises retrieval + the deterministic fallback only. Real generation was confirmed once on an Apple-Intelligence-enabled Mac.

**NOT really built (stub/placeholder/unwired — DO NOT claim):**
- **Speaker diarization:** `FluidAudioDiarizer` is a placeholder that assigns `speaker_(index % 2)` — not real diarization — and it is **not wired** into the recording flow anywhere.
- **App Intents / Siri & Shortcuts:** `StartRecordingIntent`, `SearchMemosIntent`, `CreateActionItemIntent` all have empty `perform()` returning `.result()`, are not referenced by the app targets, and no `AppShortcutsProvider` registers them. Non-functional.

## Measurable metrics (all measured 2026-06-03)
- **Git:** 113 commits, single author (`sushildalavi`), all dated **2026-06-02 → 2026-06-03** (~2 days). No external contributors.
- **Code:** Swift ~4,950 LOC / 61 files (~4,297 source, ~622 tests); Go 357 LOC; SQL 19 LOC; YAML 154 LOC.
- **Tests:** 33 Swift tests + 2 Go tests = **35**. All green. **MurmurCore coverage ≈ 54.5% line / 58.7% function** (`swift test --enable-code-coverage` + `llvm-cov`). App UI (SwiftUI views) is largely not unit-tested; app target has 3 view-model/state-machine tests.
- **Benchmark** (`swift run -c release MurmurBench`, host, 2,000 synthetic memos): insert **~4,200 memos/sec**; keyword search **p50 ≈ 6 ms, p95 ≈ 10 ms**; index ≈ 1.3 MB. Host engine numbers, not device numbers.
- **CI:** GitHub Actions runs package tests, macOS app tests, an iOS build, and Go server tests per push — green.

## Hardest problems solved
1. **CI-safe Apple Intelligence integration:** FoundationModels needs the iOS 26/macOS 26 SDK, but CI runs older Xcode. Wrapped all FoundationModels code in `#if canImport(FoundationModels)` + `@available`, so `MurmurCore` builds on every SDK and degrades to deterministic paths when the model is absent.
2. **Raw SQLite + FTS5 with no ORM:** hand-managed prepared statements, WAL pragmas, JSON transcript columns, an external-content FTS index kept in sync on upsert/delete, and injection-safe `MATCH` construction (tokens reduced to alphanumerics + prefix).
3. **Hardware-independent recording pipeline:** protocol-injected recorder/transcriber with mock implementations, enabling deterministic tests (incl. a fixed save-path test) of an `AVAudioEngine`/`SFSpeechRecognizer` flow without a device.
4. **Build/CI drift:** the committed Xcode project (objectVersion 77, a 26.x test-target deployment target) was unreadable on CI's Xcode; fixed by pinning the runner toolchain and regenerating from `project.yml`.

## Interview talking points (I did X → required Y → resulting in Z)
1. **I** built an on-device RAG feature (semantic retrieval + RRF + FoundationModels), **which required** guarding the model API behind `canImport`/`@available` so the package compiles on the CI SDK that lacks it, **resulting in** a private Q&A feature that builds green everywhere and falls back to extractive answers when the model is unavailable.
2. **I** wrote the persistence layer directly against SQLite's C API with FTS5, **which required** manual prepared-statement and WAL management plus injection-safe query construction, **resulting in** durable storage benchmarked at ~4,200 inserts/sec and p95 search <10 ms with zero third-party deps.
3. **I** fused keyword (FTS5 `bm25`) and semantic (`NLEmbedding` cosine) rankings with Reciprocal Rank Fusion, **which required** normalizing two unrelated scoring systems without tuning weights, **resulting in** search that matches both exact terms and intent (covered by a test where a zero-keyword-overlap query still ranks the right memo first).
4. **I** added a privacy invariant test that encrypts a marker memo and asserts its bytes never appear in the sync payload, **which required** a clean crypto/sync boundary, **resulting in** a build that fails if synced data is ever not ciphertext.
5. **I** factored all logic into a UI-free Swift package consumed by three platforms, **which required** platform-conditional code (`#if os`) for FoundationModels, `AVAudioSession`, and grouped backgrounds, **resulting in** one tested core driving native iOS, macOS, and watchOS apps.
6. **I** modeled the recording pipeline as `AsyncStream`s consumed by `@Observable` view models, **which required** bridging `AVAudioEngine` tap callbacks and `SFSpeechRecognizer` into structured concurrency, **resulting in** a reactive live-transcript UI and reuse of the streamed transcript on stop to avoid a redundant recognition request.
7. **I** stood up CI generating the Xcode project from `project.yml` and running package/app/iOS/Go suites per push, **which required** fixing an objectVersion/deployment-target mismatch that made the committed project unreadable on the runner, **resulting in** reproducible green builds on a clean machine.
