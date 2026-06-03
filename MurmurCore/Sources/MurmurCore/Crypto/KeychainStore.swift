import Foundation
import Security

public protocol SecretStoring: Sendable {
    func save(_ data: Data, for key: String) throws
    func data(for key: String) throws -> Data?
    func delete(_ key: String) throws
}

public struct KeychainStore {
    public enum StoreError: Error {
        case unhandledStatus(OSStatus)
        case invalidUTF8Key
    }

    public init() {}

    public func save(_ data: Data, for key: String) throws {
        try delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StoreError.unhandledStatus(status)
        }
    }

    public func data(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unhandledStatus(status)
        }
    }

    public func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.unhandledStatus(status)
        }
    }
}

extension KeychainStore: SecretStoring {}

public final class InMemorySecretStore: SecretStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]

    public init() {}

    public func save(_ data: Data, for key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        values[key] = data
    }

    public func data(for key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return values[key]
    }

    public func delete(_ key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        values.removeValue(forKey: key)
    }
}
