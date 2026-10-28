import Foundation

enum DeviceState: String, Equatable, Sendable {
    case idle, connecting, ready, measuring, failed
}

enum DeviceError: Error, Equatable, Sendable {
    case invalidState, operationInProgress, connectionFailed, measurementTimedOut
    case disconnected, cancelled
}

struct MeasurementResult: Equatable, Sendable {
    enum Source: String, Sendable {
        case mock
    }

    let measuredAt: Date
    /// Arbitrary fixture points: no physical unit or medical interpretation.
    let testValue: Double
    let source: Source
}

struct DeviceSnapshot: Equatable, Sendable {
    let deviceName: String
    var deviceState: DeviceState = .idle
    var progress: Double = 0
    var measurementResult: MeasurementResult?
    var error: DeviceError?
}
