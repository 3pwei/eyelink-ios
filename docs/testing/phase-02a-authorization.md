# Phase 02A — conditional one-run authorization

Date: 2026-10-29 (Asia/Taipei). **Authorization received; account verification pending. No build started.**
This records the owner's current instructions and supersedes earlier statements that no budget was supplied.
It does not establish that the account is eligible, free, billable at a particular rate, or safe to start.

## Authorized limits

| Control | Owner-authorized value |
| --- | --- |
| Currency | USD |
| Machine | macOS M2 only (`mac_mini_m2`); no M4 or other machine substitution |
| Attempts | One manually triggered build; no automatic retry and no second build |
| Duration | At most 20 minutes for the build |
| Single-run charge | At most US$2.00 |
| Phase 02A aggregate | At most US$5.00; this is not permission for additional builds |
| Triggers | No Push, PR or schedule automation |
| Priority | XcodeGen → Debug Build → Unit Tests; UI tests/screenshots only as remaining time permits |
| Publication | No Apple signing, TestFlight or App Store release |

## Mandatory checks before starting a runner

All five checks must be supported by the selected account's current UI or authoritative provider response.
If any cannot be verified, stay at configuration preparation. Do not start a runner to discover billing details.

| Check | Current result / evidence needed |
| --- | --- |
| Individual or Team | Pending: Codemagic browser currently shows login page; selected account not established |
| Applicable M2 rate and remaining free minutes | Pending: read selected account's Billing/usage and applicable plan; public list price is not account proof |
| Paid Billing enabled/disabled | Pending: inspect current state; do not enable Billing, add a card, change plan or buy concurrency |
| Worst-case single/aggregate charge | Pending: include applicable rounding, tax/fees and already consumed Phase 02A budget; confirm ≤ US$2 and ≤ US$5 respectively |
| Effective stopping conditions | YAML fixes M2/20 min and script bounds work/export time; provider enforcement/billable-time coverage and any monetary cap still need verification |

Public reference only: the [official pricing page](https://docs.codemagic.io/billing/pricing/) retrieved on
2026-10-29 lists M2 at US$0.095/minute. 20 × 0.095 = US$1.90 **before any applicable adjustments**.
This is not a quote for this account and is insufficient to authorize launch on its own.
The [timeout documentation](https://docs.codemagic.io/yaml-running-builds/timeout/) describes a per-workflow
time limit. A duration limit is not evidence of a US$2 hard spending cap or the scope of every billable charge.
Personal and Team usage/Billing are separate according to [Billing documentation](https://docs.codemagic.io/billing/billing/).

No service-specific Codemagic plugin was found in the available plugin search. The cloud browser reached
`https://codemagic.io/login`, so authentication is required for account verification. No build, account creation,
Billing change, payment, machine upgrade, external automation setting or repository integration was submitted.
Do not put credentials, card details or private billing documents into this public repository.

## First-run execution and stop policy

The workflow keeps `instance_type: mac_mini_m2`, `max_build_duration: 20`, and no `triggering`/`publishing`.
The script first generates and builds, then attempts the existing unit tests once. Only after that command
succeeds can UI suites start. Every UI matrix entry checks that at least 180 seconds remain in the 15-minute
work budget; otherwise it is explicitly `NOT RUN`. This threshold is an admission rule, not a completion guarantee.
The script reserves a separate 3-minute export/cleanup budget. Missing work keeps the overall result incomplete.
Raw logs and per-stage results preserve any core success without claiming full Phase 02A acceptance.

Before the one manual click, verify the exact PR head SHA and workflow, confirm no queued/running Phase 02A
build already consumes the authorization, and record the budget check. Once a build is accepted, record its
actual build ID/URL immediately. A timeout, lost response or failed UI is not permission to submit again.
If the start response is uncertain, inspect build history; do not retry the start operation.
Cancel the existing build if the verified controls cannot keep it within the authorized limits.

After the build, report provider start/end timestamps and billed minutes, account-displayed cost (or explicitly
pending/unavailable), core/UI test results, screenshot artifacts and remaining Phase 02A budget. Script elapsed
time is not the provider's billable duration. Do not equate a computed estimate with the account-displayed charge.
No second run is allowed without a new instruction, even if unused budget remains.

## Preparation checks for this update

The following are Linux-only checks of the prepared configuration/harness; no Apple test is implied:

- `python scripts/check_docs.py`: document/link checks.
- `python scripts/check_phase01.py`: project/manual-workflow invariants and source inventory.
- `python -m unittest discover -s scripts -p 'test_phase02a_tools.py' -v`: eight Python regression cases,
  including insufficient-time UI suppression and core-before-UI ordering with one unit attempt.
- `python -m py_compile scripts/run_phase02a.py scripts/phase02a_report.py`; `bash -n scripts/install_xcodegen.sh`;
  `git diff --check`: syntax/whitespace checks.

The PR description records the actual outcomes and source SHA after publication. These checks cannot resolve
the five account-side prerequisites above. See the [runbook](phase-02a.md) for future artifact review.
