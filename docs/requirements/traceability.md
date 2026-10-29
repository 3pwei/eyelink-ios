# Requirements and acceptance traceability

Baseline: 2026-10-29. The six skill areas below come from the requested iOS job alignment;
no employer-specific job description was supplied, so this is not a verbatim job-spec audit.
All product requirements were Planned in Phase 00. Phase 01 implements only the native/mock subset below,
with **Implemented / Unverified** status. Original acceptance cases remain specifications unless mapped below.

## Capability map

| Requirement | Job skill / intended behavior | Architecture | Planned acceptance cases | Required evidence | Status |
| --- | --- | --- | --- | --- | --- |
| EL-UI-001 | SwiftUI: device list, measurement and history views show loading/empty/success/error; mock mode visible | ADR-001; Presentation | AC-UI-01, AC-UI-02 | Simulator UI test, screenshots, accessibility checks | Partial: Phase 01 screens Implemented / Unverified; discovery/history Planned |
| EL-LC-001 | Lifecycle: active/inactive/background safely pause resources and reconcile persisted state on resume | ADR-001, ADR-009; App coordinator | AC-LC-01, AC-LC-02 | Unit/UI tests plus iPhone lifecycle recording | Partial: foreground mock teardown Implemented / Unverified; persistence lifecycle Planned |
| EL-CAM-001 | Camera: request access at point of use, capture a still image, handle refusal/interruption | CameraService | AC-CAM-01, AC-CAM-02 | iPhone model/OS, permission cases, capture evidence | Planned |
| EL-BLE-001 | BLE: discover/connect/subscribe/command/disconnect with typed errors and cancellation | ADR-003; DeviceTransport | AC-BLE-01, AC-BLE-02, AC-BLE-03 | Contract tests plus iPhone + specified peripheral/firmware logs | Planned |
| EL-API-001 | REST API: typed requests/responses, timeout/cancellation, auth and HTTP errors | ADR-005; APIClient | AC-API-01, AC-API-02 | Stub tests and separate staging contract run | Planned |
| EL-SYNC-001 | Offline Sync: durable local record/outbox, replay safely after connectivity returns | ADR-002, ADR-005; Repository + SyncWorker | AC-SYNC-01, AC-SYNC-02, AC-SYNC-03 | Persistence/restart/fault tests and server idempotency evidence | Planned |
| EL-DATA-001 | SwiftData: local create/read and schema evolution without silent data loss | ADR-002; Persistence | AC-DATA-01, AC-DATA-02 | File-backed store reopen and migration fixtures | Planned |
| EL-MOCK-001 | MockDevice: deterministic scenarios, explicit simulated source | ADR-003, ADR-011; Infrastructure/Mock | AC-MOCK-01, P01-MOCK-01–08 | Contract tests, source flag and UI evidence | Partial: mock source/tests Implemented / Unverified; persistence Planned |

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
| P00-REPO | Read remote before changes; reuse repository; preserve `master` default | Passed: existing repo reused; owner initialized zero-file ec3cd14; master remains default |
| P00-DOCS | Root files, four docs directories, architecture, engineering rules, traceability | 18 files submitted in PR #1; results recorded in [Phase 00 report](../release/phase-00.md) |
| P00-CI | Document XcodeGen/Codemagic without starting paid build | Planning document only; no root CI config/workflow |
| P00-PR | Submit feature branch PR targeting `master` | Passed: [PR #1](https://github.com/3pwei/eyelink-ios/pull/1), feature branch → master; merged by owner before Phase 01 |

## Status and evidence rules

`Planned` → `Implemented / Unverified` → `Verified`; use `Blocked` with a reason when progress cannot continue.
Only mark `Verified` after all acceptance cases for that requirement pass in their required environments.
A mock-only result can verify a mock test, not EL-BLE-001. Record partial evidence without upgrading the whole requirement.
Use the [evidence template](../testing/evidence-template.md), linking requirement and case IDs, commit SHA,
toolchain, device/runtime, commands, expected/actual results, and artifacts. A later regression reopens the requirement.

Unknowns: actual job description, iPhone model/OS, hardware/GATT specification, backend schema/auth/idempotency,
photo retention, account/signing/distribution and budget. Resolve each before its dependent implementation.

## Phase 01 implementation and acceptance map

All rows below are **Implemented / Unverified**, not Verified. XCTest source existence is not a test pass.
Case names, reproduction steps and environment are in [Phase 01 testing](../testing/phase-01.md).
Original EL-BLE/CAM/API/SYNC/DATA requirements remain Planned; no hardware or persistence evidence is inferred.

| Case | Requirement / behavior | Source / evidence needed |
| --- | --- | --- |
| P01-UI-01 | EL-UI-001: three native screens, loading/empty/error, navigation, Mock Mode / Simulated | Features views, DeviceSessionModelTests; simulator matrix still required |
| P01-MOCK-01 | EL-MOCK-001: normal state transitions and synthetic result/time/source | MockDeviceTests: normal transitions + same-script replay |
| P01-MOCK-02 | EL-MOCK-001: illegal transitions | Idle/failed start tests |
| P01-MOCK-03 | EL-MOCK-001: duplicate connect | Connecting rejection, ready idempotency |
| P01-MOCK-04 | EL-MOCK-001: duplicate measurement | Overlapping start/connect rejection |
| P01-MOCK-05 | EL-MOCK-001: user/caller cancellation | Cancel cleanup + caller cancellation + repeated teardown |
| P01-MOCK-06 | EL-MOCK-001: connection failure | Failure and explicit retry |
| P01-MOCK-07 | EL-MOCK-001: measurement timeout | No result, failed state, reconnect |
| P01-MOCK-08 | EL-MOCK-001: disconnect recovery / stale work | Scripted/manual disconnect, successful recovery, late connection/measurement tests |
| P01-CONTRACT-01 | ADR-011: replaceable transport and bounded snapshot semantics | Alternate transport model test + slow-consumer snapshot test |
| P01-LC-01 | EL-LC-001 subset: foreground mock interruption | Inactive scene model test; simulator inactive/background/resume still required |
| P01-BUILD-01 | ADR-006/012/013: app/test targets, resources and settings | project.yml static checks; macOS generation/Debug test/Release build still required |

AC-MOCK-01's persisted-source criterion and AC-LC-02 are deferred because this phase forbids persistence.
AC-UI-02 still needs Dynamic Type/VoiceOver validation. Full Phase 00 discovery/radio/packet scenarios remain
future BLE adapter work; Phase 01 tests only the explicitly scoped mock session.

## Phase 02A build and UI validation map

Runtime acceptance remains **Blocked** after [the first real M2 run](../testing/evidence/phase-02a-run-01.md):
XcodeGen passed but Debug Build failed on the missing AppIcon asset. XCTest, Simulator and PNG capture did not run.
The Debug Simulator icon override is **Implemented / Unverified**; no second build is authorized.
No original requirement is promoted to Verified. See the [authorization record](../testing/phase-02a-authorization.md).
See [Phase 02A runbook](../testing/phase-02a.md) for the exact test/environment/artifact matrix.

| Case | Requirement / acceptance | Implementation / evidence still required |
| --- | --- | --- |
| P02A-BUILD-01 | P01-BUILD-01 subset: XcodeGen + unsigned Debug build on real macOS | Source d1548af: generation PASS, build FAILED exit 65; real logs/manifest in Build #1. Fix unverified |
| P02A-UNIT-01 | P01-MOCK/CONTRACT/LC tests execute | Existing 24 unit tests preserved; need xcresult and 24 passes / 0 failures / 0 skips |
| P02A-UI-01 | P01-UI-01 / AC-UI-01: Dashboard → Examination → Result, empty/error and mock labels | Four XCUITest methods; need UI xcresult on three matrix entries |
| P02A-UI-02 | AC-UI-01 rendering subset: loading/error/empty for all three views | Debug frozen snapshots rendered by real SwiftUI; must identify fixture attachments separately from flow |
| P02A-VISUAL-01 | AC-UI-02 subset: compact/large iPhone, text truncation, Safe Area, maximum Dynamic Type | Real Simulator PNGs, pixel dimensions, manual reviewer/date/finding table; VoiceOver remains separate |
| P02A-EVIDENCE-01 | Downloadable evidence and human review access | Failure ZIP/logs/manifest/HTML downloaded from Build #1; no xcresult or PNG, so full evidence acceptance remains incomplete |

No Release build, physical iPhone, VoiceOver or real BLE claim follows from this scoped workflow.
