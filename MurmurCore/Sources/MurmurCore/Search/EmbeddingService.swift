import Foundation
import NaturalLanguage

/// On-device text embeddings using Apple's `NaturalLanguage` sentence model.
///
/// Runs entirely on device with no third-party dependency and no network. The
/// model ships with the OS (iOS 14+ / macOS 11+), so this is available on every
/// supported platform — including older SDKs — which keeps it safe to depend on
/// unconditionally, unlike the iOS 26 foundation model.
public struct EmbeddingService: @unchecked Sendable {
    private let embedding: NLEmbedding?

    public init(language: NLLanguage = .english) {
        self.embedding = NLEmbedding.sentenceEmbedding(for: language)
    }

    /// Whether the on-device embedding model loaded for the configured language.
    public var isAvailable: Bool { embedding != nil }

    /// The fixed dimensionality of the produced vectors, or 0 if unavailable.
    public var dimension: Int { embedding?.dimension ?? 0 }

    /// A normalized embedding vector for `text`, or nil if the model is
    /// unavailable or the text is empty.
    public func vector(for text: String) -> [Double]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let embedding else { return nil }
        return embedding.vector(for: trimmed)
    }

    /// Cosine similarity in [-1, 1]; higher means more semantically similar.
    public static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0, normA = 0.0, normB = 0.0
        for i in a.indices {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (normA.squareRoot() * normB.squareRoot())
    }
}
