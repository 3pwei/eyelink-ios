# Phase 02A delivery status

Date: 2026-10-29 (Asia/Taipei). **First macOS build failed; Debug fix Implemented / Unverified; UI acceptance Blocked.**
Base master: `42d44bb64e5fdf7c6ff6a0615338ff7c07679762`; [Phase 01 PR #2](https://github.com/3pwei/eyelink-ios/pull/2) merged.
Branch: `feature/phase-02a-build-ui-validation`; PR targets master and must be reviewed/merged by owner.

This adds a manual-only unsigned Codemagic workflow, checksum-pinned XcodeGen bootstrap, one UI test target,
Debug-only launch composition for frozen rendering states, and a macOS runner that preserves commands,
environment, unit/UI xcresult, PNG screenshots and an offline HTML gallery in a downloadable ZIP.
Phase 01 is preserved; its 24 unit tests and domain/mock/session logic are unchanged.
Only the composition root and a Dashboard accessibility identifier change existing App source.

The full [runbook and review matrix](../testing/phase-02a.md) separates real MockDevice flows from frozen
state rendering fixtures. See [traceability](../requirements/traceability.md) for P02A cases.
No source/static check qualifies as an iOS build. One real M2 build is now recorded, with no screenshot or xcresult.
Actual Linux checks and source SHA are in the [preparation evidence record](../testing/evidence/phase-02a-static.md).
The [account/budget checklist](../testing/phase-02a-authorization.md) was completed before the single
M2 run (20-minute limit, US$2/run, US$5 aggregate). The one-run authorization is consumed.
[Build #1](https://codemagic.io/app/6ae2c9db01af2bc8f930cd97/build/6ae2caa5206ce93970c71bfe)
ran source `d1548af2527cb604a44dcec8e23945375077f4d7` for 1m 13s and failed on missing AppIcon.
The follow-up `project.yml` override clears that preset only for Debug Simulator; it has not been rebuilt.
Detailed environment, command/diagnostic, timing, usage and ZIP hash are in the
[first-run evidence](../testing/evidence/phase-02a-run-01.md).

| Requested acceptance | Current status |
| --- | --- |
| True macOS Debug build | Attempted on M2: XcodeGen PASS, Debug Build FAILED exit 65; follow-up icon fix unverified |
| XCTest execution | Not run; 24 existing unit + 4 new UI methods are source inventory only |
| Simulator PNG evidence | NOT RUN: compilation failed before tests; no Simulator was booted |
| Xcode/runtime/device record | Actual macOS 15.5 (24F74), Xcode 16.4 (16F6), Swift 6.1.2, XcodeGen 2.44.1; device/runtime untested |
| Artifacts and human review | Actual failure ZIP/logs/manifest/HTML downloadable; no PNG, so UI visual review blocked |
| PR | Existing draft PR #3 contains evidence and unverified fix; no merge |

Email login and public-URL App setup succeeded. Personal account free usage changed from 0/500 to 1/500;
paid billing remains disabled, with no transactions and no per-build dollar amount displayed.
Estimated cost is US$0; no provider-displayed US$0 invoice is claimed.
No signing, webhook, push/PR trigger, schedule, publication, Apple enrollment, runtime download,
paid subscription or second build was submitted.

Next entry conditions: a new explicit authorization for any second run, then recheck account/cost controls
and the exact fix commit. Tests and human screenshot review still need actual successful execution before
promoting requirements to Verified. No automatic retries are authorized.

Release build, physical iPhone, VoiceOver, BLE and other Phase 02 feature gates remain separate.
Rollback: revert this PR through review. No persistent data migration; the manual Codemagic App and
Build #1 evidence now exist as external configuration/history.
