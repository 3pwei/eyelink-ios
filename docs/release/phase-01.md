# Phase 01 native foundation delivery

Status: **Implemented / Unverified**. Date: 2026-10-29 (Asia/Taipei).
Base: remote `master` at `79824ac3351f21285e9080e259b19826c0d8b307` (Phase 00 PR #1 merged).
Branch: `feature/phase-01-native-foundation`; PR target: `master`; no automatic merge.
Preflight inspected remote branches and existing PRs; only Phase 00 PR #1 existed.

## Delivered scope

- Native SwiftUI App entry and Dashboard / Examination / Result, each with loading/empty/error handling.
- MainActor session model, foreground teardown and explicit dependency composition.
- Domain-owned DeviceTransport, Sendable state/result/errors, bounded snapshot feed.
- MockDevice: successful connection/measurement, failed connection, timeout, cancellation, disconnect,
  duplicate-operation rejection and generation protection against stale completions.
- 24 XCTest cases with manual time progression and an alternative transport implementation.
- XcodeGen `project.yml`: App/Test targets, resources, scheme, Debug/Release, iOS 17.0, Swift language
  mode, strict concurrency and unsigned development bundle IDs.
- Updated architecture decisions, requirements, test matrix and static project checks.

No Core Bluetooth, Camera, REST API, SwiftData, signing/team, active CI, paid build or publishing is added.
No third-party runtime package is added. PyYAML is used only by the static project inspection script.
No generated project, real measurement, credential or personal data is committed.

## Demo behavior (source implementation; runtime Unverified)

1. Launch into Mock Mode. Choose a named script in the dashboard's 模擬情境 menu.
2. Connect, enter Examination, Start Measurement. Success opens Result automatically.
3. Result displays 42 arbitrary test points, measurement time and Simulated; it has no physical or medical meaning.
4. Cancel/timeout/disconnect requires explicit reconnect. Return Home tears down pending work.
5. Inactive/background tears down the session. Resume never silently reconnects.

The demo clock uses 500 ms ticks; tests use no real-time waiting. Completed results live in memory only.
Switching scenario creates a new transport at the composition root. New connection/measurement clears
the previous result. Full discovery, radio permissions and packet-level scenarios remain future work.

## Verification limits

Run [Phase 01 checks](../testing/phase-01.md) for static validation and the future macOS command sequence.
Actual check output and exact source commit are recorded in `docs/testing/evidence/` at handoff.
Linux/Python checks do not validate Swift syntax, actor diagnostics, XcodeGen generation or Apple SDK APIs.
All XCTest runtime results, SwiftUI rendering, accessibility, iOS builds and iPhone compatibility are Unverified.
There is no claim of iOS Build Passed or a verified toolchain version tuple.

## Phase 02 entry conditions

1. Review this PR and resolve the uncompiled-source risks; owner handles merge separately.
2. Select exact macOS/Xcode/Swift/XcodeGen/simulator versions; confirm iOS 17 baseline against the target iPhone.
3. Authorize a concrete unsigned validation run with scope/budget if cloud execution is needed; inspect account
   auto-trigger settings before any cloud integration. Keep signing and paid builds outside current authorization.
4. Generate project, pass Debug XCTest and Release simulator build; fix compiler/concurrency/test failures and
   retain SHA-linked logs/xcresult. Execute the three-screen state/navigation/lifecycle/accessibility matrix.
5. Agree on Phase 02 scope and dependent contracts before implementing: hardware/GATT/firmware for BLE;
   persistence/schema/retention for storage; API/auth/idempotency for networking. No such feature is implied here.

Rollback is reverting this feature's source/configuration/docs through a reviewed PR; no data migration exists.
