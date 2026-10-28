import Foundation

enum MockScenario: String, CaseIterable, Identifiable, Sendable {
    case success, connectionFailure, measurementTimeout, disconnectDuringMeasurement

    var id: Self { self }
}

@MainActor
final class MockDevice: DeviceTransport {
    private(set) var snapshot = DeviceSnapshot(deviceName: "EyeLink Mock Device")
    private let scenario: MockScenario
    private let clock: any DeviceClock
    private var generation: UInt64 = 0
    private var operation: Task<Void, Error>?
    private var subscribers: [UUID: AsyncStream<DeviceSnapshot>.Continuation] = [:]

    convenience init(scenario: MockScenario = .success) {
        self.init(scenario: scenario, clock: DemoDeviceClock())
    }

    init(scenario: MockScenario = .success, clock: any DeviceClock) {
        self.scenario = scenario
        self.clock = clock
    }

    func snapshots() -> AsyncStream<DeviceSnapshot> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            subscribers[id] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.subscribers.removeValue(forKey: id) }
            }
        }
    }

    func connect() async throws {
        guard !Task.isCancelled else { throw DeviceError.cancelled }
        if deviceState == .ready { return } // Idempotent established connection.
        guard operation == nil else { throw DeviceError.operationInProgress }
        guard deviceState == .idle || deviceState == .failed else {
            throw DeviceError.invalidState
        }
        generation &+= 1
        let token = generation
        snapshot = DeviceSnapshot(deviceName: snapshot.deviceName, deviceState: .connecting)
        publish()
        let work = Task { @MainActor [self] in
            try await clock.pause()
            try validate(token)
            if scenario == .connectionFailure { throw DeviceError.connectionFailed }
            snapshot.deviceState = .ready
            publish()
        }
        operation = work
        try await finish(work, token: token)
    }

    func startMeasurement() async throws -> MeasurementResult {
        guard !Task.isCancelled else { throw DeviceError.cancelled }
        guard operation == nil else { throw DeviceError.operationInProgress }
        guard deviceState == .ready else { throw DeviceError.invalidState }
        generation &+= 1
        let token = generation
        snapshot.deviceState = .measuring
        snapshot.progress = 0
        snapshot.error = nil
        snapshot.measurementResult = nil
        publish()
        let work = Task { @MainActor [self] in
            for step in 1...4 {
                try await clock.pause()
                try validate(token)
                if step == 2 && scenario == .disconnectDuringMeasurement {
                    throw DeviceError.disconnected
                }
                if step == 4 && scenario == .measurementTimeout {
                    throw DeviceError.measurementTimedOut
                }
                snapshot.progress = Double(step) / 4
                publish()
            }
            snapshot.measurementResult = MeasurementResult(
                measuredAt: clock.now, testValue: 42, source: .mock
            )
            snapshot.deviceState = .ready
            publish()
        }
        operation = work
        try await finish(work, token: token)
        guard token == generation, let result = measurementResult else {
            throw DeviceError.cancelled
        }
        return result
    }

    func cancelMeasurement() {
        guard deviceState == .measuring else { return }
        stop(reason: .cancelled)
    }

    func disconnect() {
        let interrupted = deviceState == .measuring || deviceState == .connecting
        stop(reason: interrupted ? .disconnected : nil)
    }

    private func stop(reason: DeviceError?) {
        generation &+= 1
        operation?.cancel()
        operation = nil
        snapshot.deviceState = .idle
        snapshot.progress = 0
        snapshot.error = reason
        publish()
    }

    private func validate(_ token: UInt64) throws {
        try Task.checkCancellation()
        guard token == generation else { throw DeviceError.cancelled }
    }

    private func finish(_ work: Task<Void, Error>, token: UInt64) async throws {
        do {
            // Propagate caller cancellation to the owned operation, including a
            // caller cancelled before this handler is installed.
            try await withTaskCancellationHandler {
                try await work.value
                try Task.checkCancellation()
            } onCancel: {
                work.cancel()
            }
            guard token == generation else { throw DeviceError.cancelled }
            operation = nil
        } catch {
            // Never let a completed old operation overwrite a newer session.
            guard token == generation else { throw DeviceError.cancelled }
            operation = nil
            let reason = (error as? DeviceError) ?? .cancelled
            snapshot.deviceState = reason == .cancelled ? .idle : .failed
            snapshot.progress = 0
            snapshot.measurementResult = nil
            snapshot.error = reason
            publish()
            throw reason
        }
    }

    private func publish() {
        for continuation in subscribers.values { continuation.yield(snapshot) }
    }

    deinit {
        operation?.cancel()
        for continuation in subscribers.values { continuation.finish() }
    }
}
