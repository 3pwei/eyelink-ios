# Requirements and acceptance traceability

Baseline: 2026-10-29. The six skill areas below come from the requested iOS job alignment;
no employer-specific job description was supplied, so this is not a verbatim job-spec audit.
All product requirements are **Planned / Not implemented / Not verified** in Phase 00.
Acceptance IDs are planned test cases, not existing test code.

## Capability map

| Requirement | Job skill / intended behavior | Architecture | Planned acceptance cases | Required evidence | Status |
| --- | --- | --- | --- | --- | --- |
| EL-UI-001 | SwiftUI: device list, measurement and history views show loading/empty/success/error; mock mode visible | ADR-001; Presentation | AC-UI-01, AC-UI-02 | Simulator UI test, screenshots, accessibility checks | Planned |
| EL-LC-001 | Lifecycle: active/inactive/background safely pause resources and reconcile persisted state on resume | ADR-001, ADR-009; App coordinator | AC-LC-01, AC-LC-02 | Unit/UI tests plus iPhone lifecycle recording | Planned |
| EL-CAM-001 | Camera: request access at point of use, capture a still image, handle refusal/interruption | CameraService | AC-CAM-01, AC-CAM-02 | iPhone model/OS, permission cases, capture evidence | Planned |
| EL-BLE-001 | BLE: discover/connect/subscribe/command/disconnect with typed errors and cancellation | ADR-003; DeviceTransport | AC-BLE-01, AC-BLE-02, AC-BLE-03 | Contract tests plus iPhone + specified peripheral/firmware logs | Planned |
| EL-API-001 | REST API: typed requests/responses, timeout/cancellation, auth and HTTP errors | ADR-005; APIClient | AC-API-01, AC-API-02 | Stub tests and separate staging contract run | Planned |
| EL-SYNC-001 | Offline Sync: durable local record/outbox, replay safely after connectivity returns | ADR-002, ADR-005; Repository + SyncWorker | AC-SYNC-01, AC-SYNC-02, AC-SYNC-03 | Persistence/restart/fault tests and server idempotency evidence | Planned |
| EL-DATA-001 | SwiftData: local create/read and schema evolution without silent data loss | ADR-002; Persistence | AC-DATA-01, AC-DATA-02 | File-backed store reopen and migration fixtures | Planned |
| EL-MOCK-001 | MockDevice: deterministic scenarios, explicit simulated source | ADR-003; TestSupport | AC-MOCK-01 | Contract tests, source flag and UI evidence | Planned |

## Acceptance scenarios

| Case | Given / When | Pass criteria |
| --- | --- | --- |
| AC-UI-01 | Launch with empty, loading, populated and failing fixtures | Each state renders expected content and retry/navigation works; no duplicate action |
| AC-UI-02 | Use largest supported Dynamic Type and VoiceOver on the three primary views | Essential controls have labels/order, remain reachable and do not truncate critical data; mock label visible |
| AC-LC-01 | During scan/capture, move inactive → background → active three times | Resources pause per foreground policy; no duplicate session/worker, stale callbacks or crash |
| AC-LC-02 | Save a record and pending operation, terminate and relaunch | Saved record/outbox restored; interrupted operation is recoverable; no reliance on termination callback |
| AC-CAM-01 | Permission undetermined, then allow; take one still image | Prompt occurs at use, preview/capture succeed, local reference resolves; no automatic upload |
| AC-CAM-02 | Deny/restrict access, interrupt session, then return | Clear explanation/recovery path; no crash; resources released and state refreshed |
| AC-BLE-01 | Specified iPhone/peripheral available; discover, connect and execute known command | Required services/characteristics validated; decoded response matches firmware fixture; disconnect cleans up |
| AC-BLE-02 | Radio off, permission denied, timeout, malformed packet or disconnect mid-command | Typed actionable error, bounded timeout/retry, no stuck progress or fabricated result |
| AC-BLE-03 | Cancel connect and immediately create a new session; inject late/duplicate callbacks | Old callbacks ignored, one active session, no duplicate measurement persistence |
| AC-API-01 | Fixtures for valid JSON, invalid JSON, 401/403, 429 and 5xx | DTO/error mapping correct; Retry-After honored; no auth loop, secret or payload leakage |
| AC-API-02 | Slow response then timeout/cancel; separate staging request after contract approval | Task terminates per policy; staging request/response matches approved schema with redacted evidence |
| AC-SYNC-01 | Airplane mode; save record; terminate/relaunch | Record and outbox survive; pending state visible; local-save failure never appears successful |
| AC-SYNC-02 | Server commits then response is lost; retry/relaunch worker | Same idempotency key reused; exactly one server record, successful ACK marks local state once |
| AC-SYNC-03 | Concurrent sync triggers, 429/5xx, auth failure or revision conflict | Single worker, persisted bounded backoff, no duplicate writes; auth/conflict visible without silent overwrite |
| AC-DATA-01 | Create a record/outbox in a file-backed test store, close then reopen; inject save failure | Record/outbox are both durable or neither reported saved; values/source preserved |
| AC-DATA-02 | Migrate a previous schema fixture; inject incompatible store | Supported migration preserves records; unsupported store surfaces error without deleting user data |
| AC-MOCK-01 | Replay named scripted scenario twice with same clock/seed | Same ordered events/results; visible simulated mode; persisted source remains mock |

## Phase 00 engineering acceptance

| ID | Criterion | Current evidence / state |
| --- | --- | --- |
| P00-REPO | Read remote before changes; reuse repository; preserve `master` default | API + clone inspection: empty remote, no refs/PRs; no remote writes |
| P00-DOCS | Root files, four docs directories, architecture, engineering rules, traceability | Files prepared; results recorded in [Phase 00 report](../release/phase-00.md) |
| P00-CI | Document XcodeGen/Codemagic without starting paid build | Planning document only; no root CI config/workflow |
| P00-PR | Submit feature branch PR targeting `master` | Bootstrap authorized; Git push authentication unavailable; no remote branch or PR created |

## Status and evidence rules

`Planned` → `Implemented / Unverified` → `Verified`; use `Blocked` with a reason when progress cannot continue.
Only mark `Verified` after all acceptance cases for that requirement pass in their required environments.
A mock-only result can verify a mock test, not EL-BLE-001. Record partial evidence without upgrading the whole requirement.
Use the [evidence template](../testing/evidence-template.md), linking requirement and case IDs, commit SHA,
toolchain, device/runtime, commands, expected/actual results, and artifacts. A later regression reopens the requirement.

Unknowns: actual job description, iPhone model/OS, hardware/GATT specification, backend schema/auth/idempotency,
photo retention, account/signing/distribution and budget. Resolve each before its dependent implementation.
