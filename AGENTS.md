# EyeLink engineering instructions

## Scope and truthfulness

- Read this file, README, relevant architecture decisions and requirement rows before editing.
- Phase 00 is documentation and repository setup only. No iOS feature is complete.
- Distinguish `Planned`, `Implemented / Unverified`, `Verified`, and `Blocked`.
- A passing text check is not an iOS build. A build is not a runtime test. Mock evidence is not BLE hardware evidence.
- Every verification claim must name the commit, environment, command or steps, result, and evidence location.
- Do not invent device UUIDs, server contracts, Apple credentials, test results, CI runs, or PR links.

## Git and change control

- Inspect the latest remote branches, tree and open PRs before work. Preserve existing content.
- Default branch is `master`; never rename it or push changes directly to it.
- Use a short-lived branch and PR targeting `master`; do not merge unless explicitly instructed.
- For a completely empty remote, stop before writing any remote branch and explain the missing base. A one-time empty baseline on `master` requires explicit owner authorization.
- Do not force-push, discard unrelated work, change repository visibility or claim branch protection is enabled without evidence.
- Commit and PR titles follow [CONTRIBUTING.md](CONTRIBUTING.md).

## Implementation boundaries for later phases

- SwiftUI Views render state and dispatch actions. Framework callbacks and network/storage logic belong in adapters or use cases.
- UI state is isolated to `@MainActor`; keep Core Bluetooth delegate handling and storage concurrency explicit.
- Domain types and the DeviceTransport contract do not depend on SwiftUI, SwiftData, or Core Bluetooth.
- Inject MockDevice and real transport at the app composition root. Mark simulated data visibly and persist its source.
- Do not pass SwiftData models or contexts across isolation boundaries; use immutable values or identifiers.
- Implement permission denial, cancellation, lifecycle transitions and error paths with each feature.
- Treat backend, BLE packet format, signing, background execution and toolchain versions as unresolved until verified.

## Build, cost and privacy

- Windows/Linux checks cannot validate Apple SDK compilation, camera or BLE hardware.
- Phase 00: do not start Codemagic/macOS builds, configure webhooks, publish, or enroll in paid services.
- Keep CI inactive until the owner authorizes a concrete build scope and cost cap. A guard script still consumes runner time.
- Do not commit secrets, provisioning profiles, certificates, tokens, personal images or real measurement data.
- Commit only synthetic fixtures. Store credentials in provider secret storage; avoid logging payloads or identifiers.
- Do not edit generated `.xcodeproj` as the source of truth once XcodeGen is introduced.

## Validation and handoff

- Run `python scripts/check_docs.py` and relevant checks for the change. Record skipped checks and reasons.
- Update requirement/acceptance traceability when behavior or scope changes.
- Final report: changes, checks, unresolved risks, branch/PR, next entry conditions.
