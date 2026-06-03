# Architecture

Murmur is a local-first voice memo app for iPhone, Mac, and Apple Watch. All
domain logic lives in a platform-agnostic Swift package (`MurmurCore`); the apps
are thin SwiftUI shells on top of it.

## Layers

```
SwiftUI apps (iOS · macOS · watchOS)
  Views ─ @Observable view models ─┐
                                    │
                               MurmurCore
  ┌──────────────┬─────────────────┼──────────────┬───────────────┐
  Audio          Transcription      Store           Sync            Search
  AVAudioEngine  SFSpeechRecognizer  MemoStore       MemoSyncService MemoSearchIndex
  level meter    live + file        SQLiteMemoStore  CryptoService   (in-memory)
                 AsyncStream         (SQLite + FTS5)  HTTP client     + FTS5 (store)
```

- **Views / view models.** Each screen has an `@Observable` view model that
  depends on protocols, not concrete services. The live app injects AVFoundation
  and Speech implementations; tests inject mocks, so the recording flow is
  verified without hardware.
- **MurmurCore.** No UI imports. Builds and unit-tests on the macOS host without
  a simulator, which keeps the test loop fast and CI cheap.

## Recording pipeline

`RecordViewModel` opens an `AudioRecordingSession` and consumes two
`AsyncStream`s — audio levels and live transcript segments. On stop it prefers
the live transcript already captured and only falls back to a full-file
transcription when nothing streamed, which avoids a redundant (and rate-limited)
second speech request.

## On-device intelligence

`IntelligentSummarizer` turns a transcript into a structured `MemoInsights`
(summary, action items, topics):

- On iOS 26 / macOS 26 with Apple Intelligence available, it runs Apple's
  on-device foundation model through `FoundationModels`, using **guided
  generation** — a `@Generable` struct with `@Guide` field hints — so the model
  returns typed fields directly instead of free text that needs parsing.
- It checks `SystemLanguageModel.default.availability` and surfaces the reason
  (device not eligible, Apple Intelligence off, model still downloading) to the UI.
- On any other platform/version, when Apple Intelligence is off, or on any model
  error, it falls back to the deterministic heuristic `Summarizer`. The whole
  foundation-model path is wrapped in `#if canImport(FoundationModels)` +
  `@available`, so the package still builds on older SDKs (CI) using the fallback.

This is the deliberate counterpoint to keyword/FTS retrieval: generative,
on-device understanding rather than substring matching.

## Semantic search & RAG

Murmur retrieves memos by meaning, not just keywords, and can answer questions
about them — a fully on-device retrieval-augmented generation pipeline.

```
Question / query
   │
   ├─ EmbeddingService (NLEmbedding, 512-d) ─ cosine ─► SemanticMemoIndex (cached)
   │                                                         │  ranked-by-meaning
   ├─ MemoStore.search (FTS5 bm25) ──────────────────────────┤  ranked-by-keyword
   │                                                         ▼
   │                                          HybridSearch.reciprocalRankFusion  → Library results
   │
   └─ MemoAnswerService: top-k semantic retrieval → FoundationModels (grounded) → Answer + sources
```

- **Embeddings:** `EmbeddingService` wraps `NLEmbedding.sentenceEmbedding`
  (`NaturalLanguage`) — on device, no dependency, available since iOS 14 / macOS
  11 (so it is safe to depend on unconditionally, unlike the iOS 26 model).
- **Semantic index:** `SemanticMemoIndex` caches memo vectors by id + `updatedAt`
  and ranks by cosine similarity.
- **Hybrid search:** `HybridSearch.reciprocalRankFusion` fuses the keyword (FTS5)
  and semantic rankings without score normalization; the Library search uses it.
- **RAG:** `MemoAnswerService` retrieves the top memos semantically, then prompts
  the foundation model to answer grounded in them (with citations), falling back
  to an extractive answer when Apple Intelligence is unavailable.

## Persistence

`MemoStore` is the observable, in-memory view SwiftUI binds to. Durability is
delegated to the `MemoPersistence` protocol:

- **`SQLiteMemoStore`** uses the system `sqlite3` C API (no third-party
  dependency) with WAL journaling and tuned pragmas (busy timeout, in-memory
  temp store). Memo rows store structured fields plus the transcript as JSON; an
  **FTS5** virtual table holds the searchable text keyed by memo id.
- Search builds an injection-safe `MATCH` expression — each user token is
  reduced to letters/digits and turned into a prefix term, then AND-ed — ordered
  by `bm25()`.
- The store is loaded once on launch and written through on every mutation.

### Concurrency trade-off

`MemoStore` is `@MainActor` and calls the persistence layer synchronously.
`SQLiteMemoStore` serializes all access on a private queue (and opens SQLite in
full-mutex mode), so it is safe to share, but writes currently run on the main
actor. For a single-user library of small records this is simple and correct;
the protocol boundary means moving writes to a background actor later is a
localized change. See [TRADEOFFS](TRADEOFFS.md).

## Sync & privacy

`MemoSyncService` encrypts each memo with AES-GCM (`CryptoService`, key in the
Keychain) before it reaches the Go server, which only ever stores ciphertext and
minimal metadata. The "sync is ciphertext, never plaintext" guarantee is
asserted by a test, not just documented. See [PRIVACY](PRIVACY.md).

## Testing

`MurmurCore` has a host XCTest suite (crypto round-trip, FTS search/ranking,
persistence durability across instances, upsert reindexing, deletion, sync
encryption, metrics, and the privacy invariant). The app target adds view-model
tests for the recording state machine and deterministic save path. CI runs the
package tests, the macOS app tests, an iOS build, and the Go server tests on
every push.
