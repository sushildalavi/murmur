import Foundation

public struct HTTPSyncClient: SyncClient {
    public enum ClientError: Error {
        case invalidResponse
        case httpStatus(Int)
        case invalidURL
    }

    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchChanges(since date: Date?) async throws -> [SyncBlob] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/blobs"), resolvingAgainstBaseURL: false)
        if let date {
            components?.queryItems = [URLQueryItem(name: "since", value: Self.iso8601.string(from: date))]
        }
        guard let url = components?.url else {
            throw ClientError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        struct Response: Codable {
            var blobs: [SyncBlob]
        }

        return try JSONDecoder.murMurCanonical.decode(Response.self, from: data).blobs
    }

    public func push(_ blob: SyncBlob) async throws {
        let url = baseURL.appendingPathComponent("v1/blobs")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.murMurCanonical.encode(blob)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    public func delete(memoID: UUID) async throws {
        let url = baseURL.appendingPathComponent("v1/blobs").appendingPathComponent(memoID.uuidString)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validate(response: response, expected: Self.defaultExpectedSuccessStatuses.union([Self.noContentStatus]))
    }

    private func validate(response: URLResponse, expected: Set<Int> = Self.defaultExpectedSuccessStatuses) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard expected.contains(httpResponse.statusCode) else {
            throw ClientError.httpStatus(httpResponse.statusCode)
        }
    }

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let defaultExpectedSuccessStatuses: Set<Int> = [200, 201]
    private static let noContentStatus = 204
}

private extension JSONEncoder {
    static var murMurCanonical: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let string = HTTPSyncClient.iso8601.string(from: date)
            try container.encode(string)
        }
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var murMurCanonical: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = HTTPSyncClient.iso8601.date(from: string) {
                return date
            }
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
        }
        return decoder
    }
}
