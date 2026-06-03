import Foundation
import Observation
import MurmurCore

@MainActor
@Observable
final class MetricsViewModel {
    var metrics: MemoMetrics

    @ObservationIgnored private let memoStore: MemoStore

    init(memoStore: MemoStore) {
        self.memoStore = memoStore
        self.metrics = memoStore.metrics()
    }

    func refresh() {
        metrics = memoStore.metrics()
    }
}
