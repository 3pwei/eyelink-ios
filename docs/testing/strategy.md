# Testing strategy

Status: Phase 00 had no Swift sources or runtime verification. Phase 01 XCTest sources now exist, but have not run; see [Phase 01 cases and commands](phase-01.md). iOS builds, simulator and iPhone acceptance remain Unverified.

## Verification levels

| Level | Environment | What it proves | What it cannot prove |
| --- | --- | --- | --- |
| Document checks | Windows/Linux; Python + Git | Required files/directories, local Markdown file links, formatting | Swift syntax, runtime behavior, permissions |
| Domain/contract tests | Future pinned Swift/Xcode environment | State machines, cancellation, mock behavior, error mapping | Radio, camera and OS permissions |
| Persistence tests | macOS-hosted iOS Simulator | In-memory use cases plus file-store reopen/migration behavior | Actual device lifecycle timing |
| UI tests | iOS Simulator | Navigation, state rendering, accessibility identifiers | Full VoiceOver experience or hardware interoperability |
| iPhone acceptance | Signed app + specified iPhone | Camera, permissions, lifecycle, physical interactions | BLE compatibility without actual peripheral |
| BLE / REST integration | iPhone + peripheral; staging backend | End-to-end contract compatibility | Every future device, OS, network or firmware version |

## Phase 00 checks

Run from repository root:

```sh
python scripts/check_docs.py
git diff --check
```

Review `.gitignore` against sample signing/runtime paths and ensure future source and lockfiles remain trackable.
Manually inspect documentation for unearned completion claims, secret values and accidental CI activation.
No GitHub Actions workflow or Codemagic build configuration is introduced by Phase 00.

## Later-phase test design

- XCTest unit tests for use-case transitions, concurrency/cancellation and domain validation.
- Parameterized transport contract cases for MockDevice and fake Core Bluetooth callback adapters.
- Inject clock, UUID factory and network client for deterministic retry/idempotency tests.
- SwiftData in-memory tests for isolated behavior, file-backed temporary stores for durability/relaunch,
  and versioned fixtures for schema migration. In-memory-only tests are insufficient evidence of durability.
- URLProtocol-style stub responses for URLSession mapping, timeout/cancel and HTTP error policies;
  separate staging tests for backend idempotency and contract compliance.
- UI tests cover empty/loading/error/success, permission recovery messages, visible mock mode and navigation.
- Device checklist covers grant/deny/revoke permissions, radio off/on, background/resume, force quit/relaunch,
  camera interruption, network loss, low storage/save failure, and BLE disconnect mid-command.
- Use synthetic data. Preserve failure artifacts; scrub logs/images/identifiers before publishing.

## Evidence policy

Use [evidence-template.md](evidence-template.md) for each verification batch.
Store reviewed text evidence in `docs/testing/evidence/` when produced; large/redacted build artifacts belong
in a retained CI artifact or release attachment with an access/retention note. Do not create success placeholders.
Record exact source SHA, runtime, Xcode/Swift/XcodeGen versions, physical device/firmware, scenario and outcome.
Keep `.xcresult` and full logs as build artifacts; link them with enough detail to reproduce a run.
An expired/unavailable artifact is a known evidence gap; a badge alone is insufficient.

## Merge gates

Phase 00 requires passing document checks and human review, then PR submission/approval.
Later code PRs require the relevant build/tests once authorized CI exists; until then label unverified work
explicitly and do not claim runnable functionality. Signing/release builds are separate gates.
Branch-protection settings and required checks are not configured by this document.
