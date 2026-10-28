# Phase 01 tests and reproduction

Status: **Implemented / Unverified**. XCTest sources exist but have not been compiled or executed.
Linux has Python 3.12.14 / PyYAML 6.0.3; Swift, Xcode and XcodeGen are absent.
No simulator, iPhone, signing or Codemagic build was used.

## Static checks (not an iOS build)

```sh
python scripts/check_docs.py
python scripts/check_phase01.py
git diff --check
```

The project check requires PyYAML 6.0.3, already installed in the delivery environment. It checks YAML
parsing, explicit target/configuration/settings/path structure, resource JSON, layer import restrictions,
no active CI and test inventory. It is not the XcodeGen schema validator or a Swift compiler.
Recorded outcomes belong in `docs/testing/evidence/`; do not infer XCTest passes from inventory counts.

## Deterministic XCTest inventory

All 24 methods below use an injected manually advanced clock or an immediate test adapter.
There is no real sleep, elapsed-time assertion, random seed, hardware or network dependency.
ManualDeviceClock.waitUntilPause is a continuation rendezvous, not polling or timed waiting.
If a regression prevents a suspension, the runner's test timeout should fail the test; no synthetic pass
or timeout fallback advances the clock. A deliberately cancellation-ignoring clock tests stale callbacks.

| Case / behavior | XCTest method in MockDeviceTests |
| --- | --- |
| P01-MOCK-01 normal transitions/result | testNormalTransitionsAndSyntheticResult |
| P01-MOCK-02 illegal start | testMeasurementWhileIdleIsRejected |
| P01-MOCK-03 duplicate pending connection | testDuplicateConnectionWhileConnectingIsRejected |
| P01-MOCK-03 established connection | testDuplicateEstablishedConnectionIsIdempotent |
| P01-MOCK-04 concurrent measurement/connect | testDuplicateMeasurementAndConnectDuringMeasurementAreRejected |
| P01-MOCK-05 user cancellation | testCancelMeasurementCleansUpAndAllowsReconnect |
| P01-MOCK-06 connection failure/retry | testConnectionFailureAndExplicitRetry |
| P01-MOCK-07 timeout/failed-state rejection | testTimeoutCleansUpAndRequiresReconnect |
| P01-MOCK-08 scripted disconnect | testScriptedDisconnectAndRecovery |
| P01-MOCK-08 explicit disconnect and successful recovery | testExplicitDisconnectDuringMeasurementAndRecovery |
| P01-MOCK-08 stale measurement | testLateMeasurementCannotOverwriteNewSession |
| P01-MOCK-08 stale connection | testLateConnectionCannotOverwriteNewSession |
| P01-MOCK-05 caller cancels connection | testCallerCancellationPropagatesToConnect |
| P01-MOCK-05 caller cancels measurement | testCallerCancellationPropagatesToMeasurement |
| P01-MOCK-05 pre-cancelled caller | testAlreadyCancelledCallerDoesNotStartWork |
| P01-MOCK-05 idempotent teardown | testRepeatedDisconnectAndCancelAreSafe |
| P01-CONTRACT-01 slow snapshot consumer | testSlowSnapshotConsumerStillReceivesCompletedResult |
| P01-MOCK-01 repeatable script | testSameScriptAndClockProduceIdenticalResults |

| Case / behavior | XCTest method in DeviceSessionModelTests |
| --- | --- |
| P01-CONTRACT-01 interchangeable adapter, result/home navigation | testAlternateTransportCanDriveResultAndReturnHome |
| P01-UI-01 cancellation/error rendering model | testCancellationStaysOnExaminationWithActionableError |
| P01-LC-01 foreground interruption | testInactiveSceneInterruptsWorkWithoutAutomaticReconnect |
| P01-UI-01 failed measurement never navigates to result | testFailureIsVisibleAndDoesNotNavigateToResult |
| P01-UI-01 home navigation survives late completion | testReturnHomeDuringMeasurementPreventsLateNavigation |
| P01-CONTRACT-01 old session cannot overwrite replacement | testReplacementCannotBeOverwrittenByOldAction |

## First authorized macOS run (not run)

Choose and record the exact macOS, Xcode, Swift compiler, XcodeGen and iOS simulator tuple before executing.
`SWIFT_VERSION: 5.0` means language mode only; it is not a claim that Swift compiler 5.0 supports this source.
Use a supported compiler with the used concurrency APIs and iOS 17+ SDK. No version tuple is verified yet.
Do not enable paid CI or signing to follow these instructions without the separate build authorization.

```sh
set -euo pipefail
git rev-parse HEAD
sw_vers
xcodebuild -version
swift --version
xcodegen --version
xcodegen generate --spec project.yml
xcodebuild -list -project EyeLink.xcodeproj
xcrun simctl list devices available
: "${SIMULATOR_UDID:?Choose an actually available iOS 17+ simulator}"
mkdir -p artifacts
xcodebuild -project EyeLink.xcodeproj -scheme EyeLink \
  -configuration Debug -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
  -derivedDataPath build/DerivedData -resultBundlePath artifacts/Phase01.xcresult \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 30 \
  -maximum-test-execution-time-allowance 60 \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee artifacts/phase01-test.log
xcodebuild -project EyeLink.xcodeproj -scheme EyeLink \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee artifacts/phase01-release.log
```

Use fresh artifact paths per run. Review strict-concurrency diagnostics, generated test host, resources,
Info.plist and both build configurations. Keep failed logs and xcresult; record source SHA and tool versions.
Generated project/build output stays ignored. Successful generation alone is not a build or test pass.

## Simulator/manual acceptance (all Unverified)

| Screen / case | Steps and expected evidence |
| --- | --- |
| Dashboard empty/loading/error | Launch → unconnected empty hint; Connect → loading; select connectionFailure → actionable error; Disconnect/Connect recovery. Device name/status/Mock Mode visible. |
| Examination empty/loading/error | Connect success → open examination → empty hint; Start → percentage progress; Cancel → cancelled and no result; reconnect after returning home. Timeout/disconnect scripts show distinct errors. |
| Result empty/loading/error | Dashboard View Result before measuring → empty; a view fixture with measuring snapshot → loading; failed snapshot → error; successful flow → result/time/Simulated and home button. Loading/error rendering fixtures still need simulator execution. |
| Success | Select success; connect; measure; result shows 42 arbitrary test points, runtime clock time, Simulated, nonmedical notice. Return home; reconnect clears previous result. |
| Repeated actions | Rapid Connect/Start attempts create only one operation; cancellation/home never causes delayed navigation to result. Protocol rejection is additionally covered by unit tests. |
| Foreground only | During connect/measurement, inactive/background → idle with interruption reason; resume does not reconnect; explicit retry works. Repeat three times. |
| Accessibility | All three screens at largest supported Dynamic Type; controls remain reachable; check VoiceOver labels/order, progress, errors and notice. No accessibility pass claimed from identifiers alone. |
| Resource/configuration | Verify accent asset loads, iPhone portrait layout, Debug/Release settings, no hardware permission prompts. |

No UI automation target is included in this phase; XCTest covers domain/session-model behavior, not rendering.
The Result screen's loading/error branches are defensive shared-state rendering; the normal success flow
navigates there after completion. Execute those branches using an injected view fixture during UI acceptance.
