import Combine
import Foundation

@MainActor
final class DeviceSessionModel: ObservableObject {
    enum Screen: Equatable { case dashboard, examination, result }

    @Published private(set) var snapshot: DeviceSnapshot
    @Published private(set) var sessionID = UUID()
    @Published private(set) var actionError: DeviceError?
    @Published private var actionPending = false
    @Published var screen: Screen = .dashboard
    private var transport: any DeviceTransport
    private var actionID: UInt64 = 0

    init(transport: any DeviceTransport) {
        self.transport = transport
        snapshot = transport.snapshot
    }

    var isBusy: Bool {
        actionPending || snapshot.deviceState == .connecting || snapshot.deviceState == .measuring
    }

    var error: DeviceError? { actionError ?? snapshot.error }

    func observe() async {
        let session = sessionID
        for await value in transport.snapshots() {
            guard !Task.isCancelled, session == sessionID else { return }
            snapshot = value
        }
    }

    func connect() async {
        guard !isBusy else { return }
        actionID &+= 1
        let action = actionID
        actionPending = true
        defer { if action == actionID { actionPending = false } }
        actionError = nil
        snapshot.deviceState = .connecting
        do { try await transport.connect() }
        catch {
            guard action == actionID else { return }
            actionError = (error as? DeviceError) ?? .connectionFailed
        }
        guard action == actionID else { return }
        snapshot = transport.snapshot
    }

    func startMeasurement() async {
        guard !isBusy else { return }
        actionID &+= 1
        let action = actionID
        actionPending = true
        defer { if action == actionID { actionPending = false } }
        actionError = nil
        screen = .examination
        snapshot.deviceState = .measuring
        do {
            _ = try await transport.startMeasurement()
            guard action == actionID else { return }
            snapshot = transport.snapshot
            screen = .result
        } catch {
            guard action == actionID else { return }
            snapshot = transport.snapshot
            actionError = (error as? DeviceError) ?? .invalidState
        }
    }

    func cancelMeasurement() {
        actionID &+= 1
        actionPending = false
        transport.cancelMeasurement()
        actionError = nil
        snapshot = transport.snapshot
    }

    func disconnect() {
        actionID &+= 1
        actionPending = false
        transport.disconnect()
        actionError = nil
        snapshot = transport.snapshot
    }

    func returnHome() {
        disconnect()
        screen = .dashboard
    }

    func suspend() {
        // Foreground-only mock session: no automatic reconnect on resume.
        disconnect()
    }

    func replaceTransport(_ replacement: any DeviceTransport) {
        disconnect()
        transport = replacement
        sessionID = UUID()
        snapshot = replacement.snapshot
        screen = .dashboard
    }
}
