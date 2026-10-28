# Phase 00 architecture decisions

Date: 2026-10-29 (Asia/Taipei). Status of all records: **Proposed for PR review**.
These describe intended engineering choices, not verified capabilities.

| ID | Decision | Reason / tradeoff | Revisit when |
| --- | --- | --- | --- |
| ADR-001 | SwiftUI + observable feature models; explicit MainActor UI boundary | Native state-driven UI with testable transitions; requires actor discipline | Initial lifecycle tests expose ownership issues |
| ADR-002 | SwiftData; proposed iOS 17.0 minimum | Native persistence; excludes older iOS and requires schema migration planning | Owner's iPhone/version or compatibility goals differ |
| ADR-003 | Domain-owned DeviceTransport; MockDevice and CoreBluetooth adapters | Enables deterministic early tests without hardware; mock cannot validate RF/GATT behavior | Actual firmware protocol and peripheral are available |
| ADR-004 | One app target with layered folders first | Keeps Phase 01 small; packages can enforce boundaries later | Module size or test isolation warrants extraction |
| ADR-005 | REST client + explicit durable outbox | Supports offline workflow and observable retry; server must support idempotency/conflict rules | Backend contract is approved |
| ADR-006 | XcodeGen spec as project source of truth | Windows/Codex can review text; requires macOS generation/build verification | Pinned toolchain is selected |
| ADR-007 | Codemagic macOS, initially manual unsigned simulator build | Fits no-Mac environment; simulator cannot validate iPhone hardware | Build budget, signing and distribution are authorized |
| ADR-008 | Short-lived branches and PRs to `master` | Maintains requested branch and review trail; empty remote requires bootstrap exception | Repository governance changes |
| ADR-009 | Foreground device/camera/sync scope first | Testable lifecycle scope; no promise of uninterrupted background execution | Product requires approved background modes |
| ADR-010 | MIT license proposed | Simple portfolio sharing choice; owner must approve grant and copyright attribution | Owner selects another license before merge |

## Deferred decisions

Do not silently invent the following: BLE service/characteristic UUIDs, packet framing/units,
supported peripheral and firmware, production backend/authentication, remote record mutation semantics,
photo retention/sharing, actual bundle ID and Apple team, Xcode/Swift/XcodeGen version tuple,
Codemagic plan/quota, target iPhone model/OS, required branch checks.

## Change procedure

Append a new ADR or supersede an existing row with rationale, impacted requirement IDs and evidence.
Preserve prior decisions for review. Accepted architecture still requires implementation and verification.

## Phase 01 implementation decisions (2026-10-29)

These append to ADR-001–010; they do not claim toolchain or hardware verification.

| ID | Decision | Reason / scope | Verification |
| --- | --- | --- | --- |
| ADR-011 | Implement Domain-owned MainActor DeviceTransport with connect/disconnect/startMeasurement/cancelMeasurement, snapshot properties and bounded current-state feed | One foreground device, no discovery/GATT yet. Explicit measurement methods replace the proposed generic send for this phase. Foundation/Swift only; future adapters marshal callbacks to this boundary, blocking work stays off MainActor. | Implemented / Unverified; contract and presentation tests authored |
| ADR-012 | Keep one app + XCTest target, iOS 17.0, XcodeGen source; set Swift 5 language mode and complete strict-concurrency checking | `SWIFT_VERSION: 5.0` is a language mode, not a Swift 5.0 compiler pin. Source uses newer concurrency APIs. Exact compiler/Xcode/XcodeGen/runtime tuple must be selected and recorded on first authorized macOS run. | Unverified; no XcodeGen generation or Apple SDK compilation |
| ADR-013 | Use `io.github.3pwei.eyelink` / `.tests` as unsigned development bundle IDs | Repository-scoped local identifiers replace `com.example`; no App Store registration, ownership of an Apple identifier or signing claim. Production ID remains a release decision. | Static configuration only |

ADR-011 narrows, rather than implements, the Phase 00 scan/send/events proposal. `snapshots()` is explicitly
not an event log: bufferingNewest(1) coalesces progress and each snapshot retains result/error until the next
explicit operation. No measurement completion is delivered solely via the feed: startMeasurement also returns
it. Callers must handle that return if they need every result. Real BLE must revisit the lossless event contract.

Mock fixture: `testValue = 42`, arbitrary test points (no physical unit, no clinical meaning), measuredAt from
an injected clock, source raw value `mock`, UI source label `Simulated`. No medical field names or GATT units
are invented. Clock and named scenario fully determine output; no random generator is needed.
