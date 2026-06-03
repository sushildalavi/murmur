import Foundation

#if canImport(AppIntents)
import AppIntents

public struct DeleteMemoIntent: AppIntent, Sendable {
    public static var title: LocalizedStringResource = "Delete Memo"
    public static var description = IntentDescription("Delete the best-matching memo from your local library.")

    @Parameter(title: "Query")
    public var query: String

    public init() {
        query = ""
    }

    public init(query: String) {
        self.query = query
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let deletedTitle = await deleteBestMatchingMemo()
        guard let deletedTitle else {
            return .result(value: "", dialog: "No memo matched “\(query)”.")
        }

        return .result(value: deletedTitle, dialog: "Deleted “\(deletedTitle)”.")
    }

    public func deleteBestMatchingMemo() async -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return await MainActor.run { () -> String? in
            guard let memo = MemoStore.shared.search(trimmed).first else { return nil }
            MemoStore.shared.remove(id: memo.id)
            return memo.title
        }
    }
}
#else
public struct DeleteMemoIntent: Sendable {
    public var query: String

    public init(query: String = "") {
        self.query = query
    }
}
#endif
