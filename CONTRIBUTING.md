# Engineering workflow

## Branches

`master` is the permanent integration branch. All work goes through a PR.
Create from freshly fetched `origin/master`, after it has an initial commit:

```sh
git fetch origin
git switch -c feature/phase-01-app-shell origin/master
```

Naming: `<kind>/<phase-or-issue>-<kebab-case-summary>`.
Kinds: `feature`, `fix`, `docs`, `chore`, `release`.
Examples: `feature/phase-00-repository-foundation`, `fix/42-ble-timeout`, `docs/phase-01-build-evidence`.
No long-lived `develop` branch, direct master push, or default-branch rename.

## Commits and PR titles

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`<type>(<optional-scope>): <imperative summary>`; breaking changes use `!` and explain migration.

- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`, `revert`.
- Suggested scopes: `repo`, `app`, `ui`, `lifecycle`, `camera`, `ble`, `storage`, `api`, `sync`.
- Use lowercase types/scopes; concise English titles preferred; body may use Traditional Chinese.
- Example commit: `docs(ble): define transport cancellation contract`.
- Example PR: `chore(repo): initialize Phase 00 engineering foundation`.
- Put requirement IDs and test evidence in the body; do not add `feat` for unimplemented planning alone.
- For Phase 00 commits, add `[skip ci]` as defense in depth; this does not replace disabling build triggers.

## PR and review

Use the [PR template](.github/pull_request_template.md). Keep one reviewable objective per PR.
Target `master`; link requirement IDs, architecture impact and evidence. Explicitly list tests not run.
Re-read remote state before pushing; if a concurrent update occurs, integrate it without overwriting.
Prefer squash merge with a Conventional Commit title; the owner reviews/merges separately.
For a solo maintainer, record self-review and unresolved risks; do not fabricate a second reviewer.

Recommended future branch rules: PR required, block force-push/deletion, require available checks.
These are recommendations, **not remotely enabled settings**. Do not require nonexistent CI checks.
Phase 00 uses manual document validation; later automation needs a separate reviewed change.

## Swift conventions (planned)

Use four-space indentation, UpperCamelCase types, lowerCamelCase members, descriptive names.
Prefer structured concurrency and injected dependencies; isolate actor ownership explicitly.
Avoid forced unwraps in runtime code. Make errors actionable, never expose secrets in logs.
Use XCTest for the initial unit/UI test targets; lint/format tooling will be pinned with the toolchain.
Keep dependencies minimal; commit lockfiles and review licenses when adding packages.

## Before proposing a merge

- Document checks pass; relevant implementation checks have actual evidence.
- Requirements state accurately separates plans, code, simulator evidence and real device evidence.
- No credentials, user data or generated project/build outputs in the diff.
- Architecture changes have a decision record; migration/rollback impact is stated.
- Camera/BLE/background capability changes identify permission strings and device checks.
- No automatic build or publication added without an agreed cost/distribution plan.
