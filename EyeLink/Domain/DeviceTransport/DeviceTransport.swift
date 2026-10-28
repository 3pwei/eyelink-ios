import Foundation

/// Domain-owned session boundary. MainActor serializes the small foreground session;
/// real adapters must move blocking I/O off this executor and return domain values.
@MainActor
protocol DeviceTransport: AnyObject {
    var snapshot: DeviceSnapshot { get }
    var deviceState: DeviceState { get }
    var measurementResult: MeasurementResult? { get }
    /// A current-state feed, NOT a lossless event log. Each snapshot carries the result
    /// and error; newest-state buffering can coalesce intermediate progress only.
    func snapshots() -> AsyncStream<DeviceSnapshot>
    func connect() async throws
    func disconnect()
    func startMeasurement() async throws -> MeasurementResult
    func cancelMeasurement()
}

extension DeviceTransport {
    var deviceState: DeviceState { snapshot.deviceState }
    var measurementResult: MeasurementResult? { snapshot.measurementResult }
}
