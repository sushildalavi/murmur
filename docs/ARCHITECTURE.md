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
