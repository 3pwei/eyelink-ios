# Phase 01 entry conditions

Phase 01 scope proposal: minimal SwiftUI app shell, dependency composition, MockDevice contract skeleton,
initial test targets, XcodeGen configuration and a manually authorized unsigned simulator build.
The full Camera/BLE/REST/Offline Sync feature set is not a Phase 01 entry requirement or promised output.

## Ready to implement

- [x] Obtain explicit owner authorization for zero-file baseline `ec3cd14` only.
- [ ] Establish that authorized baseline using an authenticated Git client; current workspace push failed before any remote write.
- [ ] Phase 00 is submitted through a feature branch PR, reviewed and merged by the owner.
- [ ] Confirm architecture decisions, MIT license proposal, iOS 17.0 baseline and actual iPhone OS compatibility.
- [ ] Agree on minimal screens/use cases and the first synthetic measurement shape; keep payload units explicit.
- [ ] Select exact toolchain versions, bundle identifier and initial simulator target in a reviewed change.
- [ ] Define Phase 01 acceptance cases and evidence locations; mark unrun cases accurately.

## Ready to run cloud validation (separate gate)

- [ ] Codemagic access/repository integration verified, including automatic-build settings.
- [ ] Owner authorizes the specific workflow, machine, time cap and spending limit; no automatic triggers.
- [ ] XcodeGen spec, sources, tests and manual workflow are reviewed and ready to run.
- [ ] Selected macOS image/tool versions/runtime exist; secrets are unnecessary for unsigned simulator work.

These build conditions may remain blocked while source implementation proceeds after the first gate.
An unbuilt skeleton must remain `Implemented / Unverified`.

## Later feature gates

- Real BLE: known peripheral, firmware, GATT/packet contract and iPhone test access.
- Camera: permission copy, image lifecycle/retention and signed iPhone build path.
- REST/sync: approved API/auth, stable idempotency keys, conflict policy and staging environment.
- Physical-device release: account eligibility, signing, distribution, budget and privacy review.

## Proposed Phase 01 exit evidence

Reproducible XcodeGen generation, successful simulator build, app launch and basic UI/unit tests tied to an exact SHA.
Mock mode visible; minimum lifecycle/state handling exercised; pending requirements retain honest status.
No real BLE, camera, server or background-execution completion claim follows from a skeleton build alone.
