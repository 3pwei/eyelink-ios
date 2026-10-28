import Foundation

@MainActor
protocol DeviceClock {
    var now: Date { get }
    func pause() async throws
}

struct DemoDeviceClock: DeviceClock {
    var now: Date { Date() }

    func pause() async throws {
        try await Task.sleep(for: .milliseconds(500))
    }
}
