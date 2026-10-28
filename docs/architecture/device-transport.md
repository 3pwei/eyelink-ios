# DeviceTransport and MockDevice contract

Status: Phase 00 full-device design below remains proposed. The Phase 01 subset is **Implemented / Unverified** as described at the end; none of this is BLE hardware evidence.

## Contract surface

| Operation | Proposed behavior |
| --- | --- |
| `scan()` | Returns a cancellable async stream of deduplicated domain device summaries |
| `connect(deviceID:)` | Connects one selected device with a deadline; confirms required services before ready |
| `disconnect()` | Idempotent teardown; cancels pending operations and releases resources |
| `send(command:)` | Validates ready state, serializes command, awaits matching response with timeout |
| `events()` | One ordered event stream per session: state, measurement, error, disconnect |

Use Sendable value types for device IDs, commands, events, measurements and errors.
Never expose CBPeripheral, CBCentralManager or SwiftData model instances through the contract.
The app coordinator owns one transport/session. Define bounded buffering when implementing streams;
never silently drop measurement events. UI discovery updates may coalesce.

## States and cancellation

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> scanning: start scan
    scanning --> connecting: select device
    connecting --> ready: services validated
    ready --> measuring: command accepted
    measuring --> ready: result persisted or surfaced
    connecting --> failed: timeout or error
    measuring --> failed: malformed or timeout
    ready --> idle: disconnect
    scanning --> idle: cancel
    connecting --> idle: cancel
    measuring --> idle: disconnect or cancel
    failed --> idle: cleanup and explicit retry
```

Authorization/radio availability is a separate state (`unknown`, `denied`, `unsupported`, `poweredOff`, `available`).
Only `available` permits scanning. Any radio loss interrupts work and emits a typed reason.
All failure paths clean up before reconnect. Prevent overlapping scans/connects; repeated disconnect is safe.
Cancellation ends the relevant stream or operation promptly; no delayed callbacks may mutate a new session.
Use a session generation ID to reject stale callbacks. Define reconnect as bounded and user-visible;
no infinite automatic retry or assumption of background reconnection.

## CoreBluetoothTransport (planned)

Own manager/delegate operations on a consistent executor/serial queue and map callbacks into domain events.
Validate selected services/characteristics, framing, payload length, unit/version and response correlation.
Unknown UUIDs and packet format remain blocked pending a firmware contract.
Handle unauthorized, powered-off, disconnect mid-command, unsupported services and malformed packets.
Verify notification subscription and teardown on an actual iPhone with a specified peripheral.

## MockDevice (planned)

Implement the same contract with an injected clock and deterministic scripted fixtures; no real sleeps in unit tests.
Scenarios: happy path, no devices, denied permission, radio off, connect timeout, disconnect mid-measurement,
malformed payload, duplicate notification, stale event after reconnect, and cancellation.
Record scenario/seed in evidence. UI must show **模擬裝置 / 模擬資料** and persist `source = mock`.
MockDevice can be a deliberate demo mode; it must never silently replace a failed real BLE connection.

Run common contract tests against MockDevice and, where possible, the adapter with fake delegate inputs.
Only hardware integration tests can verify actual Core Bluetooth/peripheral interoperability.

## Phase 01 concrete contract

Source: [DeviceTransport.swift](../../EyeLink/Domain/DeviceTransport/DeviceTransport.swift).
All protocol access is MainActor isolated; snapshots/results/errors are Sendable values.
No SwiftUI, SwiftData or Core Bluetooth import is allowed in Domain.

| Operation / state | Phase 01 behavior |
| --- | --- |
| connect from idle/failed | connecting → ready after one injected clock tick; scripted failure → failed |
| connect while ready | Idempotent; no additional work |
| overlapping connect/measurement | Throws operationInProgress, leaves current operation untouched |
| startMeasurement from ready | measuring → ready with result after four ticks |
| startMeasurement from idle/failed | Throws invalidState without state change |
| cancelMeasurement while measuring | Cancels owned task, invalidates generation, clears progress, idle with cancelled reason; reconnect required |
| cancelMeasurement otherwise | No-op |
| disconnect | Idempotent teardown; pending operations cancelled, idle; interrupted work exposes disconnected reason |
| timeout / scripted mid-measurement disconnect | failed, no result; reconnect explicitly |
| deviceState / measurementResult | Read-only domain values via current snapshot |
| snapshots | Initial/current complete snapshots, one-element newest buffer; result/error retained, progress may coalesce |

Each explicit operation gets a generation token; stale completions cannot alter a new session or clear its
operation handle. Cancellation of the caller forwards to the owned Task. Explicit teardown returns a
cancelled error to the suspended caller while the snapshot retains the user-facing disconnect/cancel reason.
The DemoDeviceClock is cancellable and uses 500 ms ticks only for the interactive demo; tests manually advance
suspensions and inject time, including deliberately uncooperative old work.

Four selectable scripts: success, connectionFailure, measurementTimeout, disconnectDuringMeasurement.
User cancellation and duplicate starts are actions on these scripts, with dedicated tests.
Timeout is a deterministic scripted failure at tick four, not a verified real-device deadline implementation.
No scan, permission/radio model, generic send, packet parser or lossless events API is implemented yet.
