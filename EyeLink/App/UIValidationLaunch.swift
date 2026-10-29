#if DEBUG
import Foundation

/// Opt-in UI-test composition only. Release builds do not contain this fixture adapter.
/// Screenshots still render the production SwiftUI views on a real iOS Simulator.
@MainActor
struct UIValidationLaunch {
    private let environment = ProcessInfo.processInfo.environment

    private var isEnabled: Bool { environment["EYELINK_UI_TESTING"] == "1" }

    var scenario: MockScenario {
        guard isEnabled, let name = environment["EYELINK_UI_SCENARIO"] else { return .success }
        return MockScenario(rawValue: name) ?? .success
    }

    func makeModel() -> DeviceSessionModel {
        guard isEnabled,
              let screenName = environment["EYELINK_UI_SCREEN"],
              let stateName = environment["EYELINK_UI_STATE"] else {
            return DeviceSessionModel(transport: MockDevice(scenario: scenario))
        }
        let screen: DeviceSessionModel.Screen
        switch screenName {
        case "dashboard": screen = .dashboard
        case "examination": screen = .examination
        case "result": screen = .result
        default: preconditionFailure("Unknown UI validation screen")
        }
        var snapshot = DeviceSnapshot(deviceName: "EyeLink Mock Device")
        switch stateName {
        case "empty": break
        case "loading":
            snapshot.deviceState = screen == .dashboard ? .connecting : .measuring
            snapshot.progress = 0.5
        case "error":
            snapshot.deviceState = .failed
            snapshot.error = screen == .dashboard ? .connectionFailed : .measurementTimedOut
        default: preconditionFailure("Unknown UI validation state")
        }
        let model = DeviceSessionModel(transport: UIValidationTransport(snapshot: snapshot))
        model.screen = screen
        return model
    }
}

/// Frozen snapshots exercise transient and defensive view branches without timing races.
/// Navigation/operation tests use MockDevice instead; this is rendering evidence only.
@MainActor
private final class UIValidationTransport: DeviceTransport {
    let snapshot: DeviceSnapshot

    init(snapshot: DeviceSnapshot) { self.snapshot = snapshot }

    func snapshots() -> AsyncStream<DeviceSnapshot> {
        AsyncStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }

    func connect() async throws { throw DeviceError.invalidState }
    func startMeasurement() async throws -> MeasurementResult { throw DeviceError.invalidState }
    func disconnect() {}
    func cancelMeasurement() {}
}
#endif
