import Foundation
@testable import EyeLink

/// No wall-clock sleep, polling, random seed or timer. Tests rendezvous with each
/// suspension, then explicitly release it. Cancellation can be ignored to model
/// a late callback from an uncooperative adapter.
@MainActor
final class ManualDeviceClock: DeviceClock {
    private(set) var now = Date(timeIntervalSince1970: 1_700_000_000)
    private(set) var pauseCount = 0
    private var pending: [(Int, CheckedContinuation<Void, Error>)] = []
    private var observers: [(Int, CheckedContinuation<Void, Never>)] = []
    var ignoresCancellation = false

    func pause() async throws {
        if !ignoresCancellation { try Task.checkCancellation() }
        pauseCount += 1
        let id = pauseCount
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending.append((id, continuation))
                let ready = observers.filter { $0.0 <= pauseCount }
                observers.removeAll { $0.0 <= pauseCount }
                for (_, observer) in ready { observer.resume() }
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel(id) }
        }
    }

    func waitUntilPause(_ count: Int) async {
        if pauseCount >= count { return }
        await withCheckedContinuation { observers.append((count, $0)) }
    }

    func advance() {
        precondition(!pending.isEmpty, "Wait for a registered suspension before advancing")
        now.addTimeInterval(0.5)
        pending.removeFirst().1.resume()
    }

    func advance(through counts: ClosedRange<Int>) async {
        for count in counts {
            await waitUntilPause(count)
            advance()
        }
    }

    private func cancel(_ id: Int) {
        guard !ignoresCancellation, let index = pending.firstIndex(where: { $0.0 == id }) else { return }
        pending.remove(at: index).1.resume(throwing: CancellationError())
    }
}
