"""Package actual runner outputs. Never creates substitute screenshots or test passes."""

import hashlib
import html
import json
from pathlib import Path
import shutil
import struct


def png_dimensions(path):
    data = path.read_bytes()
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG: {path}")
    return struct.unpack(">II", data[16:24])


def write_report(output, manifest):
    output = Path(output)
    screenshots = []
    cards = []
    attachment_names = {}

    def collect_names(value, folder):
        if isinstance(value, dict):
            filename = value.get("exportedFileName")
            label = value.get("suggestedHumanReadableName")
            if isinstance(filename, str) and isinstance(label, str):
                attachment_names[(folder / filename).resolve()] = label
            for child in value.values():
                collect_names(child, folder)
        elif isinstance(value, list):
            for child in value:
                collect_names(child, folder)

    for index in output.glob("attachments/**/manifest.json"):
        collect_names(json.loads(index.read_text()), index.parent)
    for path in sorted(output.glob("attachments/**/*.png")):
        relative = path.relative_to(output).as_posix()
        width, height = png_dimensions(path)
        label = attachment_names.get(path.resolve(), path.name)
        screenshots.append({"path": relative, "name": label, "width": width, "height": height,
                            "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        safe = html.escape(relative, quote=True)
        cards.append(f'<figure><a href="{safe}"><img loading="lazy" src="{safe}" alt="{safe}"></a>'
                     f'<figcaption>{html.escape(label)}<br>{safe}<br>{width} × {height} pixels</figcaption></figure>')
    manifest["screenshots"] = screenshots
    manifest["visual_review"] = "PENDING: human review of clipping, text and safe areas required"
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    rows = "".join(f"<tr><td>{html.escape(name)}</td><td>{html.escape(str(value))}</td></tr>"
                   for name, value in manifest["stages"].items())
    page = f"""<!doctype html><html lang="en"><meta charset="utf-8">
<title>EyeLink Phase 02A evidence</title>
<style>body{{font:16px system-ui;margin:2rem;background:#f5f5f5;color:#171717}}
table{{border-collapse:collapse}}td{{padding:.5rem;border:1px solid #aaa}}
main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1rem}}
figure{{margin:0;background:white;padding:1rem}}img{{width:100%;max-width:400px}}
figcaption{{overflow-wrap:anywhere}}pre{{white-space:pre-wrap}}</style>
<h1>EyeLink Phase 02A</h1><p>Commit: {html.escape(manifest.get('commit', 'unknown'))}</p>
<p>Automated result: {html.escape(manifest['result'])}. Human visual review: PENDING.</p>
<p>Real Simulator screenshots only. “fixture” attachments render frozen synthetic states;
“flow” attachments exercise MockDevice navigation. Neither is BLE or physical iPhone evidence.</p>
<p>Open <a href="manifest.json">manifest.json</a> for commands, versions, devices, hashes and statuses.
Attachment manifest.json files under attachments map exported filenames to XCTest attachment names.
Raw xcresult bundles can be opened in Xcode on macOS.</p>
<table>{rows}</table><h2>Screenshots</h2><main>{''.join(cards) or '<p>No PNG evidence available.</p>'}</main>
<h2>Review checklist</h2><p>For every device and text size: check titles, full error/notice text,
Mock Mode and Simulated labels, button reachability, truncation, top status bar and bottom home indicator.
Inspect top/detail/bottom images together. Record reviewer, date, attachment name, pass/fail and issue.
Accessibility element existence and hit testing do not prove text or safe-area correctness.</p></html>
"""
    (output / "index.html").write_text(page)
    shutil.make_archive(str(output.parent / "phase-02a-evidence"), "zip", output.parent, output.name)
