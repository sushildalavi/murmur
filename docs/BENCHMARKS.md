# Benchmarks

Host micro-benchmark of the SQLite + FTS5 memo store. These are **engine numbers
on the host, not device numbers** — they show that local indexing and search are
not the bottleneck. They exclude the real on-device costs (audio capture and
speech transcription), which dominate end-to-end latency.

## Run it

```bash
cd MurmurCore
swift run -c release MurmurBench [corpusSize] [queryRuns]
# defaults: 2000 memos, 200 queries
```

## Results

Apple Silicon, release build, 2,000 synthetic memos (~14 words each), 200
keyword queries:

| Metric | Value |
|---|---|
| Insert throughput | ~4,200 memos/sec |
| Insert total (2,000 memos) | ~480 ms |
| Search latency p50 | ~6 ms |
| Search latency p95 | ~10 ms |
| Index size (2,000 memos) | ~1.3 MB |

Search latency here includes fully decoding and ranking every matching row
(common query terms match a large fraction of the corpus), so it is an upper
bound for realistic, more selective queries. Numbers will vary by machine; re-run
the command above to reproduce on your hardware.

## Not yet measured

On-device throughput — OCR/transcription time per recording, memory under load,
and p95 search over a persisted database at realistic library sizes — is the
subject of a planned device benchmark.
