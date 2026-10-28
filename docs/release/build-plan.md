# XcodeGen and Codemagic build plan

Status: **Not executed or validated on macOS.** Phase 01 now provides [project.yml](../../project.yml); historical Phase 00 examples below are retained as planning context. Current commands and configuration are in [Phase 01 testing](../testing/phase-01.md).
No root `project.yml`, `codemagic.yaml`, webhook, GitHub Actions workflow or signed artifact is created in Phase 00.
Do not run these examples as-is. The Phase 00 repository contained no App or test source directories; Phase 01 adds them.

## Windows + iPhone workflow

1. Codex/Windows edits Swift and text configuration on a feature branch; run document and static checks locally.
2. In Phase 01, add minimal App/test sources and a reviewed XcodeGen specification together.
3. Select and record one exact supported macOS/Xcode/Swift/XcodeGen/runtime tuple. Confirm runner availability first.
4. After build budget/scope authorization, manually start an unsigned iOS Simulator workflow on Codemagic macOS.
5. Collect generation logs, compiler logs, test `.xcresult`, source SHA and tool versions.
6. Separately plan signed device distribution and iPhone acceptance; an unsigned simulator app cannot be installed on iPhone.

The first build validates the skeleton/toolchain only. It does not validate BLE, camera or offline sync.

## XcodeGen specification design

The future root `project.yml` will be the source of truth; generated `.xcodeproj` stays ignored.
Use a shared scheme `EyeLink`, an app target and XCTest unit/UI targets. Proposed minimum iOS is 17.0.
Avoid third-party dependencies at the skeleton stage. When added, store a canonical `Package.resolved` outside
ignored generated project paths and restore it during generation; define that workflow before adding packages.

Illustrative target shape, **not yet runnable** (source directories do not exist):

```yaml
name: EyeLink
options:
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    GENERATE_INFOPLIST_FILE: YES
targets:
  EyeLink:
    type: application
    platform: iOS
    sources: [EyeLink]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.eyelink
        TARGETED_DEVICE_FAMILY: "1"
  EyeLinkTests:
    type: bundle.unit-test
    platform: iOS
    sources: [EyeLinkTests]
    dependencies:
      - target: EyeLink
  EyeLinkUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [EyeLinkUITests]
    dependencies:
      - target: EyeLink
schemes:
  EyeLink:
    build:
      targets:
        EyeLink: all
    test:
      targets:
        - EyeLinkTests
        - EyeLinkUITests
```

Phase 01 must replace the placeholder bundle ID, pin `SWIFT_VERSION`/strict-concurrency settings compatible
with the selected compiler, and validate generated target settings. Declare reviewed camera/Bluetooth usage
descriptions when those features are introduced. Background modes and entitlements must be justified separately.
Do not add `DEVELOPMENT_TEAM` or signing secrets to the planning sample.

## Codemagic workflow design

Only add an active root configuration after build authorization. Begin manual-only: omit automatic `triggering`,
disable dashboard automatic build settings, and do not configure repository webhooks or publishing.
Account configuration must also be inspected; absence of YAML triggers alone is not proof that no other job can run.
Before each first run, confirm the plan/quota, rate, maximum runtime, concurrency and authorized budget.
No free-tier availability or cost estimate is assumed here. Even a job that immediately exits can consume time.

Planned workflow fields:

| Field | Intended value / rule |
| --- | --- |
| Workflow ID | `ios-simulator-manual` |
| Instance type | Supported macOS machine, explicitly chosen with current cost |
| `max_build_duration` | Proposed 20 minutes; confirm enough for tests and approve cost ceiling |
| `environment.xcode` | Exact supported version; no `latest`/`edge` in reproducible builds |
| XcodeGen | Pinned release and verified checksum; record install/version output |
| Trigger | Manual start only; no `triggering` or publication block |
| Signing | Disabled for simulator verification; no secrets needed |
| Artifacts | Build/test logs, `.xcresult`, toolchain/source manifest |

Planned macOS commands after configuration and sources exist:

```sh
set -euo pipefail
xcodebuild -version
swift --version
xcodegen --version
xcodegen generate --spec project.yml
xcodebuild -list -project EyeLink.xcodeproj
xcrun simctl list devices available
# Set SIMULATOR_UDID from the available devices on this exact runner.
: "${SIMULATOR_UDID:?Select a verified available iOS simulator UUID}"
mkdir -p artifacts
xcodebuild -project EyeLink.xcodeproj -scheme EyeLink \
  -configuration Debug -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
  -derivedDataPath build/DerivedData \
  -resultBundlePath artifacts/EyeLink.xcresult \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee artifacts/xcodebuild.log
```

Pin a runtime/device selection policy and use fresh output paths per job. A missing simulator, absent scheme,
failed generation, compiler error or failing test must fail the job. Do not hide failures with `|| true`.
Before enabling the job, validate Codemagic YAML, install/check pinned XcodeGen, and ensure artifact collection
also preserves failed-run logs. The current Phase 01 instruction explicitly defers workflow YAML and cloud builds. No active workflow is part of this delivery.

## Signing and iPhone distribution (later gate)

Choose a supported Apple signing/distribution route with the owner's account: for example TestFlight or
registered-device distribution, subject to current eligibility and requirements. Verify current Apple/Codemagic
requirements before selecting a paid program. Windows alone cannot run Xcode or an iOS Simulator.
Keep App Store Connect keys, certificates and provisioning profiles only in approved secret storage.
No Apple Developer enrollment, credential upload, App Store submission or paid job is authorized by this plan.

## Source references

Reviewed 2026-10-29; recheck before activation:

- [XcodeGen specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [XcodeGen project](https://github.com/yonaskolb/XcodeGen)
- [Codemagic YAML configuration](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Codemagic automatic triggers](https://docs.codemagic.io/yaml-running-builds/starting-builds-automatically/)
- [Apple simulated-device workflow](https://help.apple.com/xcode/mac/current/en.lproj/devfd9e28378.html)
