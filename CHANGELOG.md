# Changelog

## Unreleased

### Semantic search & RAG
- On-device sentence embeddings (`NLEmbedding`) with a cached `SemanticMemoIndex`
  for meaning-based ranking.
- Hybrid search via Reciprocal Rank Fusion of FTS5 keyword + semantic rankings;
  the Library search now uses it.
- New **Ask** tab: a retrieval-augmented generation pipeline that answers
  questions about your memos on device, with citations and an extractive
  fallback. Replaced the redundant standalone Search tab.

### Intelligence
- On-device memo summaries, action items, and topics via Apple Intelligence
  (the `FoundationModels` framework) with guided generation, gated behind
  availability checks and a deterministic heuristic fallback.

### Persistence & search
- Memos now persist in a local SQLite database (system `sqlite3`, WAL) and
  survive relaunch, behind a `MemoPersistence` protocol.
- Full-text search via an FTS5 index ranked by `bm25()`, with injection-safe
  prefix matching; Search and the library now use it.
- Audio playback in the memo detail view; swipe-to-delete in the library.
- Local index is excluded from iCloud backup.

### Rigor
- Test-enforced privacy invariant: the build fails if a sync payload is not
  ciphertext.
- `MurmurBench` host benchmark for store insert/search latency.
- Added ARCHITECTURE, PRIVACY, BENCHMARKS, and TRADEOFFS docs.

### UI
- Rebuilt the iOS, macOS, and watchOS interfaces around the Human Interface
  Guidelines: native `List`/`Form` containers, system materials, a single accent
  color, Dynamic Type, and full light/dark support.
- Replaced the macOS sidebar with a native `NavigationSplitView`.

### Fixes
- Recording files are now written with a `murmur-<timestamp>-<id>.m4a` name
  instead of nesting an empty `murmur-` directory.
- Search now uses the Core ranking index instead of a naive substring scan.

### Foundation
- Local privacy-safe metrics dashboard
- README refreshed with current UI screenshots

### Phase 0
- Repository setup
- Initial project metadata
