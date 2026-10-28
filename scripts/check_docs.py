"""Check repository documentation only; never claims to validate iOS behavior."""

from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = (
    "README.md",
    "LICENSE",
    ".gitignore",
    ".gitattributes",
    ".editorconfig",
    "AGENTS.md",
    "CONTRIBUTING.md",
    ".github/pull_request_template.md",
    "docs/architecture/overview.md",
    "docs/architecture/decisions.md",
    "docs/architecture/device-transport.md",
    "docs/requirements/traceability.md",
    "docs/testing/strategy.md",
    "docs/testing/evidence-template.md",
    "docs/release/build-plan.md",
    "docs/release/phase-00.md",
    "docs/release/phase-01-entry.md",
)


def main() -> int:
    errors = []
    for name in REQUIRED:
        path = ROOT / name
        if not path.is_file() or not path.stat().st_size:
            errors.append(f"Missing or empty: {name}")

    markdown = sorted(ROOT.glob("*.md"))
    markdown += sorted((ROOT / "docs").rglob("*.md"))
    markdown += sorted((ROOT / ".github").rglob("*.md"))
    link_count = 0
    for path in markdown:
        relative = path.relative_to(ROOT)
        try:
            data = path.read_bytes()
            content = data.decode("utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"Cannot read UTF-8 {relative}: {error}")
            continue
        if not data.endswith(b"\n"):
            errors.append(f"Missing final newline: {relative}")
        if b"\r\n" in data:
            errors.append(f"Expected LF line endings: {relative}")
        for number, line in enumerate(content.splitlines(), 1):
            if line.rstrip() != line:
                errors.append(f"Trailing whitespace: {relative}:{number}")

        # Deliberately checks simple inline local file links only, not anchors,
        # external URLs, reference-style links, or examples inside code fences.
        prose = re.sub(r"```.*?```", "", content, flags=re.S)
        for href in re.findall(r"!?\[[^\]]*\]\(([^\s)]+)\)", prose):
            parsed = urlsplit(href)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            link_count += 1
            target = (path.parent / unquote(parsed.path)).resolve()
            if not target.is_relative_to(ROOT) or not target.is_file():
                errors.append(f"Broken/out-of-repository file link: {relative} -> {href}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(REQUIRED)} required files; {len(markdown)} Markdown files; "
          f"{link_count} local file links. Document checks only; iOS not verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
