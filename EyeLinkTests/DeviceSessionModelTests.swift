import Foundation
import XCTest
@testable import EyeLink

final class DeviceSessionModelTests: XCTestCase {
    @MainActor
    func testAlternateTransportCanDriveResultAndReturnHome() async {
        let model = DeviceSessionModel(transport: ImmediateTransport())
        XCTAssertNil(model.snapshot.measurementResult)
        await model.connect()
        XCTAssertEqual(model.snapshot.deviceState, .ready)
        await model.startMeasurement()
        XCTAssertEqual(model.screen, .result)
        XCTAssertEqual(model.snapshot.measurementResult?.testValue, 7)
        model.returnHome()
        XCTAssertEqual(model.screen, .dashboard)
        XCTAssertEqual(model.snapshot.deviceState, .idle)
    }

    @MainActor
    func testCancellationStaysOnExaminationWithActionableError() async {
        let clock = ManualDeviceClock()
        let model = DeviceSessionModel(transport: MockDevice(clock: clock))
        let connect = Task { await model.connect() }
        await clock.waitUntilPause(1)
        clock.advance()
        await connect.value
        let measure = Task { await model.startMeasurement() }
        await clock.waitUntilPause(2)
        model.cancelMeasurement()
        await measure.value
        XCTAssertEqual(model.screen, .examination)
        XCTAssertEqual(model.error, .cancelled)
        XCTAssertFalse(model.isBusy)
        XCTAssertNil(model.snapshot.measurementResult)
    }

    @MainActor
    func testInactiveSceneInterruptsWorkWithoutAutomaticReconnect() async {
        let clock = ManualDeviceClock()
        let model = DeviceSessionModel(transport: MockDevice(clock: clock))
        let connect = Task { await model.connect() }
        await clock.waitUntilPause(1)
        model.suspend()
        await connect.value
        XCTAssertEqual(model.snapshot.deviceState, .idle)
        XCTAssertEqual(model.error, .disconnected)
        XCTAssertEqual(clock.pauseCount, 1)
    }

    @MainActor
    func testFailureIsVisibleAndDoesNotNavigateToResult() async {
        let clock = ManualDeviceClock()
        let model = DeviceSessionModel(transport: MockDevice(scenario: .measurementTimeout, clock: clock))
        let connect = Task { await model.connect() }
        await clock.waitUntilPause(1)
        clock.advance()
        await connect.value
        let measure = Task { await model.startMeasurement() }
        await clock.advance(through: 2...5)
        await measure.value
        XCTAssertEqual(model.screen, .examination)
        XCTAssertEqual(model.error, .measurementTimedOut)
        XCTAssertFalse(model.isBusy)
        XCTAssertNil(model.snapshot.measurementResult)
    }

    @MainActor
    func testReturnHomeDuringMeasurementPreventsLateNavigation() async {
        let clock = ManualDeviceClock()
        clock.ignoresCancellation = true
        let model = DeviceSessionModel(transport: MockDevice(clock: clock))
        let connect = Task { await model.connect() }
        await clock.waitUntilPause(1)
        clock.advance()
        await connect.value
        let measure = Task { await model.startMeasurement() }
        await clock.waitUntilPause(2)
        model.returnHome()
        clock.advance()
        await measure.value
        XCTAssertEqual(model.screen, .dashboard)
        XCTAssertEqual(model.snapshot.deviceState, .idle)
        XCTAssertNil(model.snapshot.measurementResult)
    }

    @MainActor
    func testReplacementCannotBeOverwrittenByOldAction() async {
        let clock = ManualDeviceClock()
        clock.ignoresCancellation = true
        let model = DeviceSessionModel(transport: MockDevice(clock: clock))
        let old = Task { await model.connect() }
        await clock.waitUntilPause(1)
        model.replaceTransport(ImmediateTransport())
        await model.connect()
        clock.advance()
        await old.value
        XCTAssertEqual(model.snapshot.deviceName, "Alternate test transport")
        XCTAssertEqual(model.snapshot.deviceState, .ready)
        XCTAssertNil(model.error)
    }
}

/// Intentionally unrelated to MockDevice; exercises the Presentation injection seam.
@MainActor
private final class ImmediateTransport: DeviceTransport {
    private(set) var snapshot = DeviceSnapshot(deviceName: "Alternate test transport")

    func snapshots() -> AsyncStream<DeviceSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }

    func connect() async throws { snapshot.deviceState = .ready }
    func disconnect() { snapshot.deviceState = .idle }
    func cancelMeasurement() { disconnect() }

    func startMeasurement() async throws -> MeasurementResult {
        let result = MeasurementResult(
            measuredAt: Date(timeIntervalSince1970: 0), testValue: 7, source: .mock
        )
        snapshot.measurementResult = result
        return result
    }
}
