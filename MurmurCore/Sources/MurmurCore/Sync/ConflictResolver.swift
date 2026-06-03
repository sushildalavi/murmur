import Foundation

public struct ConflictResolver {
    public init() {}

    public func resolve(local: Memo, remote: Memo) -> Memo {
        if local.updatedAt != remote.updatedAt {
            return local.updatedAt > remote.updatedAt ? local : remote
        }

        if local.transcriptSegments.count != remote.transcriptSegments.count {
            return local.transcriptSegments.count > remote.transcriptSegments.count ? local : remote
        }

        return local.title.count >= remote.title.count ? local : remote
    }

    public func resolve(local: SyncBlob, remote: SyncBlob) -> SyncBlob {
        if local.updatedAt != remote.updatedAt {
            return local.updatedAt > remote.updatedAt ? local : remote
        }
        return local.ciphertext.count >= remote.ciphertext.count ? local : remote
    }
}
