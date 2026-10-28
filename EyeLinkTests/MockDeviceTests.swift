import XCTest
@testable import EyeLink

final class MockDeviceTests: XCTestCase {
    @MainActor
    private func connect(_ device: any DeviceTransport, clock: ManualDeviceClock) async throws {
        let next = clock.pauseCount + 1
        let task = Task { try await device.connect() }
        await clock.waitUntilPause(next)
        XCTAssertEqual(device.deviceState, .connecting)
        clock.advance()
        try await task.value
        XCTAssertEqual(device.deviceState, .ready)
    }

    @MainActor
    private func expectError(_ expected: DeviceError, operation: @MainActor () async throws -> Void) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)")
        } catch {
            XCTAssertEqual(error as? DeviceError, expected)
        }
    }

    @MainActor
    func testNormalTransitionsAndSyntheticResult() async throws {
        let clock = ManualDeviceClock()
        let device: any DeviceTransport = MockDevice(clock: clock)
        XCTAssertEqual(device.deviceState, .idle)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        XCTAssertEqual(device.deviceState, .measuring)
        XCTAssertNil(device.measurementResult)
        clock.advance()
        await clock.waitUntilPause(3)
        XCTAssertEqual(device.snapshot.progress, 0.25)
        await clock.advance(through: 3...5)
        let result = try await task.value
        XCTAssertEqual(device.deviceState, .ready)
        XCTAssertEqual(result.source, .mock)
        XCTAssertEqual(result.testValue, 42)
        XCTAssertEqual(result.measuredAt, clock.now)
        XCTAssertEqual(device.measurementResult, result)
        device.disconnect()
        XCTAssertEqual(device.deviceState, .idle)
    }

    @MainActor
    func testMeasurementWhileIdleIsRejected() async {
        let device = MockDevice(clock: ManualDeviceClock())
        await expectError(.invalidState) { _ = try await device.startMeasurement() }
        XCTAssertEqual(device.deviceState, .idle)
        XCTAssertNil(device.measurementResult)
    }

    @MainActor
    func testDuplicateConnectionWhileConnectingIsRejected() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        let first = Task { try await device.connect() }
        await clock.waitUntilPause(1)
        await expectError(.operationInProgress) { try await device.connect() }
        XCTAssertEqual(device.deviceState, .connecting)
        clock.advance()
        try await first.value
        XCTAssertEqual(clock.pauseCount, 1)
    }

    @MainActor
    func testDuplicateEstablishedConnectionIsIdempotent() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        try await device.connect()
        XCTAssertEqual(device.deviceState, .ready)
        XCTAssertEqual(clock.pauseCount, 1)
    }

    @MainActor
    func testDuplicateMeasurementAndConnectDuringMeasurementAreRejected() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        let first = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        await expectError(.operationInProgress) { _ = try await device.startMeasurement() }
        await expectError(.operationInProgress) { try await device.connect() }
        XCTAssertEqual(device.deviceState, .measuring)
        await clock.advance(through: 2...5)
        _ = try await first.value
        XCTAssertEqual(clock.pauseCount, 5)
        XCTAssertEqual(device.snapshot.progress, 1)
    }

    @MainActor
    func testCancelMeasurementCleansUpAndAllowsReconnect() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        device.cancelMeasurement()
        await expectError(.cancelled) { _ = try await task.value }
        XCTAssertEqual(device.deviceState, .idle)
        XCTAssertEqual(device.snapshot.error, .cancelled)
        XCTAssertNil(device.measurementResult)
        device.cancelMeasurement()
        try await connect(device, clock: clock)
        XCTAssertNil(device.snapshot.error)
    }

    @MainActor
    func testConnectionFailureAndExplicitRetry() async {
        let clock = ManualDeviceClock()
        let device = MockDevice(scenario: .connectionFailure, clock: clock)
        for count in 1...2 {
            let task = Task { try await device.connect() }
            await clock.waitUntilPause(count)
            clock.advance()
            await expectError(.connectionFailed) { try await task.value }
            XCTAssertEqual(device.deviceState, .failed)
            XCTAssertEqual(device.snapshot.error, .connectionFailed)
            XCTAssertNil(device.measurementResult)
        }
    }

    @MainActor
    func testTimeoutCleansUpAndRequiresReconnect() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(scenario: .measurementTimeout, clock: clock)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.advance(through: 2...5)
        await expectError(.measurementTimedOut) { _ = try await task.value }
        XCTAssertEqual(device.deviceState, .failed)
        XCTAssertEqual(device.snapshot.error, .measurementTimedOut)
        XCTAssertNil(device.measurementResult)
        await expectError(.invalidState) { _ = try await device.startMeasurement() }
        try await connect(device, clock: clock)
    }

    @MainActor
    func testScriptedDisconnectAndRecovery() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(scenario: .disconnectDuringMeasurement, clock: clock)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.advance(through: 2...3)
        await expectError(.disconnected) { _ = try await task.value }
        XCTAssertEqual(device.deviceState, .failed)
        XCTAssertEqual(device.snapshot.error, .disconnected)
        XCTAssertNil(device.measurementResult)
        try await connect(device, clock: clock)
    }

    @MainActor
    func testExplicitDisconnectDuringMeasurementAndRecovery() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        let old = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        device.disconnect()
        await expectError(.cancelled) { _ = try await old.value }
        XCTAssertEqual(device.snapshot.error, .disconnected)
        try await connect(device, clock: clock)
        let new = Task { try await device.startMeasurement() }
        await clock.advance(through: 4...7)
        _ = try await new.value
        XCTAssertEqual(device.measurementResult?.source, .mock)
    }

    @MainActor
    func testLateMeasurementCannotOverwriteNewSession() async throws {
        let clock = ManualDeviceClock()
        clock.ignoresCancellation = true
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        let old = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        device.disconnect()
        let reconnect = Task { try await device.connect() }
        await clock.waitUntilPause(3)
        clock.advance() // Release the old measurement after reconnect has begun.
        await expectError(.cancelled) { _ = try await old.value }
        XCTAssertEqual(device.deviceState, .connecting)
        XCTAssertNil(device.snapshot.error)
        XCTAssertNil(device.measurementResult)
        clock.advance()
        try await reconnect.value
        XCTAssertEqual(device.deviceState, .ready)
    }

    @MainActor
    func testLateConnectionCannotOverwriteNewSession() async throws {
        let clock = ManualDeviceClock()
        clock.ignoresCancellation = true
        let device = MockDevice(clock: clock)
        let old = Task { try await device.connect() }
        await clock.waitUntilPause(1)
        device.disconnect()
        let new = Task { try await device.connect() }
        await clock.waitUntilPause(2)
        clock.advance()
        await expectError(.cancelled) { try await old.value }
        XCTAssertEqual(device.deviceState, .connecting)
        clock.advance()
        try await new.value
        XCTAssertEqual(device.deviceState, .ready)
    }

    @MainActor
    func testCallerCancellationPropagatesToConnect() async {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        let task = Task { try await device.connect() }
        await clock.waitUntilPause(1)
        task.cancel()
        await expectError(.cancelled) { try await task.value }
        XCTAssertEqual(device.deviceState, .idle)
        XCTAssertEqual(device.snapshot.error, .cancelled)
    }

    @MainActor
    func testCallerCancellationPropagatesToMeasurement() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.waitUntilPause(2)
        task.cancel()
        await expectError(.cancelled) { _ = try await task.value }
        XCTAssertEqual(device.deviceState, .idle)
        XCTAssertNil(device.measurementResult)
    }

    @MainActor
    func testAlreadyCancelledCallerDoesNotStartWork() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        let connection = Task { try await device.connect() }
        connection.cancel() // MainActor task has not had an opportunity to start.
        await expectError(.cancelled) { try await connection.value }
        XCTAssertEqual(clock.pauseCount, 0)
        XCTAssertEqual(device.deviceState, .idle)
        try await connect(device, clock: clock)
        let measurement = Task { try await device.startMeasurement() }
        measurement.cancel()
        await expectError(.cancelled) { _ = try await measurement.value }
        XCTAssertEqual(clock.pauseCount, 1)
        XCTAssertEqual(device.deviceState, .ready)
        XCTAssertNil(device.measurementResult)
    }

    @MainActor
    func testRepeatedDisconnectAndCancelAreSafe() {
        let device = MockDevice(clock: ManualDeviceClock())
        device.disconnect()
        device.disconnect()
        device.cancelMeasurement()
        XCTAssertEqual(device.deviceState, .idle)
        XCTAssertNil(device.snapshot.error)
    }

    @MainActor
    func testSlowSnapshotConsumerStillReceivesCompletedResult() async throws {
        let clock = ManualDeviceClock()
        let device = MockDevice(clock: clock)
        var iterator = device.snapshots().makeAsyncIterator()
        let initial = await iterator.next()
        XCTAssertEqual(initial?.deviceState, .idle)
        try await connect(device, clock: clock)
        let task = Task { try await device.startMeasurement() }
        await clock.advance(through: 2...5)
        let result = try await task.value
        // Deliberately do not consume progress. The latest full snapshot keeps result.
        let latest = await iterator.next()
        XCTAssertEqual(latest?.deviceState, .ready)
        XCTAssertEqual(latest?.measurementResult, result)
        XCTAssertEqual(latest?.progress, 1)
    }

    @MainActor
    func testSameScriptAndClockProduceIdenticalResults() async throws {
        var results: [MeasurementResult] = []
        for _ in 0..<2 {
            let clock = ManualDeviceClock()
            let device = MockDevice(clock: clock)
            try await connect(device, clock: clock)
            let task = Task { try await device.startMeasurement() }
            await clock.advance(through: 2...5)
            results.append(try await task.value)
        }
        XCTAssertEqual(results[0], results[1])
    }
}
