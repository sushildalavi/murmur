# Trade-offs

Deliberate choices and their costs, kept honest.

## SQLite over Core Data / SwiftData
Direct `sqlite3` keeps the dependency surface at zero and makes FTS5 and the
exact SQL explicit and testable on the host without a simulator. The cost is
hand-written C-API binding code (centralized in one tested wrapper) instead of a
generated object graph.

## Synchronous writes on the main actor
`MemoStore` is `@MainActor` and writes through to SQLite synchronously. For a
single-user library of small records this is simple and correct, and the
benchmark shows inserts are sub-millisecond each. If libraries grow large or
batch imports appear, the `MemoPersistence` boundary lets writes move to a
background actor without touching the UI.

## Observable cache + persistence protocol
The UI binds to an in-memory `[Memo]` for instant updates, with the database as
the source of truth written through on each mutation. This duplicates state but
keeps SwiftUI fast and makes tests hermetic (in-memory store, no disk).

## Reuse the live transcript on stop
Recording prefers the transcript already streamed during capture and only does a
full-file transcription when nothing streamed. This avoids a redundant,
rate-limited second speech request — at the cost of depending on the live
recognizer's output for the common path.

## Hybrid retrieval (keyword + semantic)
Search fuses FTS5 keyword ranking (`bm25()`) with on-device semantic ranking
(`NLEmbedding` cosine) via Reciprocal Rank Fusion, rather than committing to one.
`NLEmbedding` is a lightweight, built-in sentence model — chosen over a heavier
custom embedding model to stay dependency-free and on device, trading some
ceiling on retrieval quality for zero footprint.

## What is deferred
Server authentication / certificate pinning, app-level encryption at rest for
the local index, and on-device performance benchmarks are out of scope for the
current build and called out in [PRIVACY](PRIVACY.md) and [BENCHMARKS](BENCHMARKS.md).
