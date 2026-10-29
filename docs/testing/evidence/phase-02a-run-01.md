# Phase 02A — first manual build record

## Pre-launch decision

Observed 2026-10-29 12:24 Asia/Taipei (04:24 UTC), before submitting a build.
Source: `d1548af2527cb604a44dcec8e23945375077f4d7`, PR #3 branch
`feature/phase-02a-build-ui-validation`. PR remains open/draft; master is unchanged.

- Email sign-in succeeded. Selected account is Personal Account (Individual).
- Account Billing UI: Free macOS minutes personal use `0 / 500`; 500 minutes remain.
- Paid subscription is not enabled: UI offers Enable subscription; no previous transactions.
  No payment details, subscription or billing settings were changed.
- Applicable rate for this M2 run is US$0 within the remaining free allowance.
  Estimated single-run / Phase 02A cumulative charge: US$0 / US$0, below US$2 / US$5.
  This is a preflight estimate, not a provider-displayed final charge.
- Provider YAML loaded from the exact feature branch: `mac_mini_m2`, `max_build_duration: 20`,
  Xcode `16.4`, workflow `phase-02a-manual`. No machine override, SSH/VNC, signing or publishing.
- Provider timeout enforces 20 minutes; the script budgets 15 minutes work plus 3 minutes finalization.
  Paid billing remains disabled. Free allowance exhaustion does not automatically enable paid billing.
  No configurable dollar cap is claimed; the free-only account state is the monetary control.
- Builds overview has no entries with All app/workflow/status and empty branch/tag filters.
- Application was added through its public Git URL. No GitHub OAuth integration or webhook was installed.
  Scheduled builds says No builds scheduled; Webhooks says a webhook is required and No deliveries yet.
  YAML has no automatic triggers. The selected build dialog is the intended branch/workflow.
- One manual submission is authorized. Do not submit another run or retry after acceptance/uncertainty.

Account evidence was inspected privately at <https://codemagic.io/billing/user>.
No account email, credentials, private billing screenshot or authentication artifact is committed.
Application: <https://codemagic.io/app/6ae2c9db01af2bc8f930cd97/settings>.

Provider references inspected on the same date:

- [Individual free M2 allowance and paid list rates](https://docs.codemagic.io/billing/pricing/)
- [Billing must be enabled for paid features](https://docs.codemagic.io/billing/billing/)
- [YAML timeout and machine types](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Workflow timeout](https://docs.codemagic.io/yaml-running-builds/timeout/)
- [Provider response: free allowance exhaustion stops builds until billing is enabled](https://github.com/orgs/codemagic-ci-cd/discussions/3541)

## Execution

One manual submission accepted after the pre-launch record:
[Build 1 / 6ae2caa5206ce93970c71bfe](https://codemagic.io/app/6ae2c9db01af2bc8f930cd97/build/6ae2caa5206ce93970c71bfe).
Initial provider state: queued; Machine Mac mini M2; Commit `d1548af`; intended feature branch/workflow.
The one-run authorization is now consumed. No retry or second submission is permitted.
Final provider status: **failed**. Duration shown by Codemagic: **1m 13s** (73 seconds, approximately
1.22 elapsed minutes). Start shown: 2026-10-29 12:25 CST (UTC+8). The UI does not expose exact
provider start/end seconds; do not reconstruct them from the rounded start label.
Script timestamps, a narrower interval, are 04:25:45.914330–04:26:22.521675 UTC.

| Evidence | Actual result |
| --- | --- |
| Machine | Mac mini M2, provider Build overview |
| macOS | 15.5 (24F74), arm64 |
| Xcode | 16.4 (16F6) |
| Swift | Apple Swift 6.1.2; project language mode remains Swift 5 |
| XcodeGen | 2.44.1, checksum verified and project generated successfully |
| Debug Build | Failed, `xcodebuild` exit 65, asset catalog compilation |
| Unit Tests | NOT RUN; compilation prevented the unit stage |
| Simulator / device model | None booted; no device UUIDs in manifest. iPhone 16 / SE 3 remain planned only |
| UI tests / PNG / visual review | NOT RUN; zero PNG, no xcresult; no clipping or Safe Area result |
| Failure evidence export | ZIP, command logs, environment manifest and offline HTML successfully downloaded |

The relevant diagnostic in `phase-02a/debug-build.log` is:

```text
Assets.xcassets: error: None of the input catalogs contained a matching stickers icon set or app icon set named "AppIcon".
```

`build-settings.log` records `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` and the build log records
`actool --app-icon AppIcon`; the repository only has AccentColor and no AppIcon set. XcodeGen's
application preset supplies AppIcon unless overridden. The follow-up change in `project.yml` clears
the icon name for Debug + iphonesimulator only. This preserves the future Release icon requirement.
**Fix Implemented / Unverified**: no second build, Apple SDK test or Simulator run was performed.
Other compilation/runtime issues may remain after this first failure is removed.

## Usage and artifacts

After the build, the same account Billing page displayed free macOS usage **1 / 500**, leaving **499
displayed minutes**. This is the provider's displayed quota counter, not an assertion that exactly
60 seconds were billed. The provider Build overview separately shows 73 elapsed seconds.
Paid subscription remains disabled and Billing history says No previous transactions.
No independent dollar amount for this build is displayed. Estimated charge remains **US$0**, based on
free allowance; an account-displayed US$0 charge or invoice is **not** claimed. Phase 02A estimated
aggregate remains US$0. Both monetary limits remain unused, but the one-run authorization is consumed.

On the build page, download `phase-02a-evidence.zip` from Artifacts. Downloaded byte size: 17,043.
SHA-256: `7a1cbfcacf5fb2f4cf02d398d3bc2425a5d1d7bb9e157ac35fa669b1b6fcdfb7`.
Extract and open `phase-02a/index.html`: it reports the failed stage and **No PNG evidence available**.
The original ZIP is also retained as `EyeLink-Phase02A-Run01-d1548af.zip` in the user handoff.
No modified/reconstructed report is presented as the downloaded provider artifact.

Next execution requires a **new explicit authorization**. PR #3 contains this failure evidence and
the unverified fix; it must not be merged automatically or described as Phase 02A accepted.

## Follow-up checks (Linux only)

After adding the Debug Simulator override and this report:

- `python scripts/check_docs.py`: PASS, 17 required files, 21 Markdown files, 58 local links.
- `python scripts/check_phase01.py`: PASS; 11 App Swift sources, 24 unit / 4 UI methods inventoried only.
- `python -m unittest discover -s scripts -p 'test_phase02a_tools.py' -v`: 8 passed.
- `git diff --check`: PASS.

These validate preparation/documentation on Linux and do not replace another macOS build.
