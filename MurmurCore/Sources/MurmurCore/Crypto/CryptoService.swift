import Foundation
import CryptoKit

public struct CryptoService {
    public enum CryptoError: Error {
        case invalidEnvelope
        case invalidPayload
    }

    public init() {}

    public func makeSymmetricKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    public func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.invalidEnvelope
        }
        return combined
    }

    public func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    public func seal(_ memo: Memo, using key: SymmetricKey) throws -> Data {
        let encodedMemo = try JSONEncoder.murMurCanonical.encode(memo)
        return try encrypt(encodedMemo, using: key)
    }

    public func openMemo(_ data: Data, using key: SymmetricKey) throws -> Memo {
        let decryptedData = try decrypt(data, using: key)
        return try JSONDecoder.murMurCanonical.decode(Memo.self, from: decryptedData)
    }
}

private extension JSONEncoder {
    static var murMurCanonical: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var murMurCanonical: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
