import Foundation
import MurmurCore

// A small host benchmark for the SQLite/FTS5 memo store: measures bulk-insert
// throughput and keyword-search latency over a synthetic corpus. These are
// engine numbers on the host, not device numbers — they show local search and
// indexing are not the bottleneck. Run with:
//
//     swift run -c release MurmurBench [corpusSize] [queryRuns]

let corpusSize = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 2000 : 2000
let queryRuns = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 200 : 200

let vocabulary = [
    "release", "roadmap", "sync", "encrypt", "transcribe", "metrics", "design",
    "review", "ship", "pipeline", "audio", "memo", "privacy", "search", "index",
    "follow", "standup", "kickoff", "backend", "device", "latency", "throughput"
]

func millis(since start: UInt64) -> Double {
    Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
}

let path = FileManager.default.temporaryDirectory
    .appendingPathComponent("murmur-bench-\(UUID().uuidString).sqlite").path
let store = try SQLiteMemoStore(path: path)

var rng = SystemRandomNumberGenerator()
let memos: [Memo] = (0..<corpusSize).map { index in
    let body = (0..<14).map { _ in vocabulary.randomElement(using: &rng)! }.joined(separator: " ")
    return Memo(
        title: "Memo \(index)",
        audioFileURL: URL(fileURLWithPath: "/tmp/memo-\(index).m4a"),
        transcriptSegments: [TranscriptSegment(text: body, startTime: 0, endTime: 1)]
    )
}

// Insert throughput.
let insertStart = DispatchTime.now().uptimeNanoseconds
for memo in memos { try store.save(memo) }
let insertMs = millis(since: insertStart)

// Search latency distribution.
var latencies: [Double] = []
latencies.reserveCapacity(queryRuns)
for _ in 0..<queryRuns {
    let term = vocabulary.randomElement(using: &rng)!
    let start = DispatchTime.now().uptimeNanoseconds
    _ = try store.search(term)
    latencies.append(millis(since: start))
}
latencies.sort()

func percentile(_ p: Double) -> Double {
    guard !latencies.isEmpty else { return 0 }
    let rank = Int((p / 100) * Double(latencies.count - 1))
    return latencies[rank]
}

let stats = try store.stats()
let throughput = Double(corpusSize) / (insertMs / 1000)

print("""
MurmurBench — SQLite + FTS5 memo store (host)
  corpus:          \(corpusSize) memos, \(queryRuns) queries
  insert total:    \(String(format: "%.0f", insertMs)) ms
  insert rate:     \(String(format: "%.0f", throughput)) memos/sec
  search p50:      \(String(format: "%.3f", percentile(50))) ms
  search p95:      \(String(format: "%.3f", percentile(95))) ms
  search max:      \(String(format: "%.3f", latencies.last ?? 0)) ms
  db size:         \(stats.databaseByteSize / 1024) KB
""")

try? FileManager.default.removeItem(atPath: path)
