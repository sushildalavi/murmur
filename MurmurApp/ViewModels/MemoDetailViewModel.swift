import Observation
import MurmurCore

@MainActor
@Observable
final class MemoDetailViewModel {
    var memo: Memo

    init(memo: Memo) {
        self.memo = memo
    }
}
