import Foundation
import Observation

@MainActor
@Observable
public final class MemoStore {
    public static let shared = MemoStore()

    public private(set) var memos: [Memo] = []

    public init(memos: [Memo] = []) {
        self.memos = memos
    }

    public func upsert(_ memo: Memo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index] = memo
        } else {
            memos.insert(memo, at: 0)
        }
    }

    public func memo(id: UUID) -> Memo? {
        memos.first { $0.id == id }
    }

    public func removeAll() {
        memos.removeAll()
    }

    public func metrics(calendar: Calendar = .current) -> MemoMetrics {
        MemoMetrics.calculate(from: memos, calendar: calendar)
    }
}
