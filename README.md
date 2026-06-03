# Murmur

A privacy-first cross-device voice intelligence system for iPhone, Mac, Apple Watch, and encrypted sync.

## Overview
Murmur records voice memos, transcribes speech locally, generates summaries and action items locally when available, stores encrypted searchable memos, supports Apple Watch/App Intents, and later syncs ciphertext-only memo blobs through a Go/PostgreSQL backend.

## Features
- Local voice memo capture
- On-device speech transcription
- Local summaries and action items when available
- Encrypted searchable memo storage
- Apple Watch support and App Intents integration
- Ciphertext-only sync for future backend infrastructure

## Architecture
- Client apps run on Apple platforms and keep plaintext processing local.
- Memo content is encrypted on device before any sync.
- A future Go/PostgreSQL backend stores only ciphertext blobs and minimal metadata required for transport.

## Tech Stack
Swift 6, SwiftUI, SwiftData, SpeechAnalyzer, Foundation Models, CryptoKit, App Intents, watchOS, Go, PostgreSQL, Docker.

## Build Phases
- Phase 0 — repository setup and project skeleton.
- Phase 1 — core iPhone app foundation.
- Phase 2 — local transcription and memo storage.
- Phase 3 — Apple Watch and App Intents.
- Phase 4 — encrypted sync backend.

## Current Status
Phase 0 — repository setup and project skeleton.

## Privacy Model
Raw audio, transcripts, summaries, and action items never leave the device in plaintext.

## Running Locally
Phase 0 only. No runnable app or backend is committed yet.

## Testing
No automated tests are present in Phase 0.

## Roadmap
- Set up the Swift project structure.
- Implement local memo capture and transcription.
- Add encrypted memo indexing and search.
- Build watchOS and App Intents support.
- Add ciphertext-only sync through the backend.

## License
MIT License. See `LICENSE`.
