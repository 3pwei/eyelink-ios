# Phase 02A preparation evidence — not an iOS build

Date: 2026-10-29 (Asia/Taipei).
Historical preparation snapshot. Current conditional authorization/account blockers are tracked in the
[authorization record](../phase-02a-authorization.md); this original record is not upgraded to runtime evidence.
Source commit: [58ec3f41463fdacebfa6f1e198c6da1390d842ac](https://github.com/3pwei/eyelink-ios/commit/58ec3f41463fdacebfa6f1e198c6da1390d842ac).
Source tree: `91cd2c9d7583c27522751384d6c3e0ca7398e2b0`.
Base master: `42d44bb64e5fdf7c6ff6a0615338ff7c07679762` (PR #2 merged).
The subsequent evidence-only commit adds this record and documentation links; App, test and runner source are unchanged.

## Environment and source integrity

- Linux x86_64, kernel 6.18.55, glibc 2.39; Python 3.12.14, PyYAML 6.0.3, Git 2.51.1, Bash 5.2.21.
- No `xcodebuild`, XcodeGen, Apple SDK or iOS Simulator in this editing environment.
- GitHub connector supplied master files; the local baseline tree matched remote tree `0818ca7da14b3afb15183ac620b99b0394f76ccf`.
- Local staged source tree matched the GitHub-created source tree above. The exact source commit object
  was loaded locally and `git status --short` was empty before the Linux preflight probe.
- Remote master/feature refs rechecked before publication; only the feature branch was advanced, without force.
- No Codemagic integration, webhook, schedule, build API or runner was invoked. Existing account settings were not inspected.

## Checks actually run against source commit

| Command | Actual result | Scope |
| --- | --- | --- |
| `python scripts/check_docs.py` | PASS: 17 required files, 18 Markdown files, 44 local links | Document existence/links/whitespace |
| `python scripts/check_phase01.py` | PASS: 11 App Swift files; 24 unit + 4 UI methods inventoried, NOT executed | YAML/settings/path/assets/import boundaries; manual-only CI shape |
| `python -m unittest discover -s scripts -p 'test_phase02a_tools.py' -v` | Ran 6 tests; OK | Python evidence-tool regression tests, not XCTest |
| `bash -n scripts/install_xcodegen.sh` | Exit 0 | Shell syntax only; no download/install executed |
| `python -m py_compile scripts/run_phase02a.py scripts/phase02a_report.py` | Exit 0 | Python syntax |
| `git diff local-base-snapshot HEAD --check` | Exit 0 | Source diff whitespace against exact master snapshot |
| `python scripts/run_phase02a.py` on Linux | Exit 1, expected Blocked | Clean-SHA preflight and failure-report packaging; no Apple commands run |

Python regression cases: nonzero exit/log retention; missing runtime cannot create a device; failed build
packages NOT RUN stages; zero/skipped-test summary rejection; empty report does not invent screenshots or
visual passes; invalid PNG rejection. Mocked subprocess responses in these tests only validate the Python
harness's failure handling. They are not simulated Apple test evidence.

The actual Linux preflight produced this status for the source commit:

```text
FAILED / BLOCKED: macOS/Xcode required; no Simulator evidence can be produced on this host
generation: NOT RUN
debug-build: NOT RUN
unit-tests: NOT RUN
ui-iphone16-default: NOT RUN
ui-se3-default: NOT RUN
ui-se3-accessibility: NOT RUN
screenshots: []
```

Its local diagnostic ZIP/HTML contains only blocked metadata/logs and no images. It is **not** presented as a
macOS Build Artifact or acceptance result. The meaningful evidence is this committed, source-linked record.

## Acceptance still blocked

XcodeGen generation, Swift compilation, Debug build, XCTest, Simulator execution, PNG collection,
text truncation, Safe Area and visual review are all **NOT RUN / Unverified**.
No actual Xcode/runtime/device tuple, build URL, xcresult or Simulator screenshot exists for this phase yet.
The planned Xcode 16.4 / XcodeGen 2.44.1 / iPhone 16 and SE matrix is configuration, not measured evidence.
Cloud costs have not been authorized; no free tier or interactive Simulator is assumed.

Next: follow the [authorized-run checklist and human review instructions](../phase-02a.md), retain the actual
Codemagic build URL and evidence ZIP, and fill reviewer/date/attachment outcomes before marking cases Verified.
Self-review only; no independent review or automatic merge is claimed.
