"""Static inventory/settings checks only. Does not compile Swift or run XCTest.

Requires Python 3.10+ and PyYAML 6.0.3 (development check only; no app dependency).
"""

import json
from pathlib import Path
import re
import yaml


ROOT = Path(__file__).resolve().parents[1]


def check(condition, message):
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def main():
    spec = yaml.safe_load((ROOT / "project.yml").read_text())
    check(spec["name"] == "EyeLink", "Project name")
    check(spec["configs"] == {"Debug": "debug", "Release": "release"}, "Configurations")
    base = spec["settings"]["base"]
    check(base["SWIFT_VERSION"] == "5.0", "Explicit Swift language mode")
    check(base["SWIFT_STRICT_CONCURRENCY"] == "complete", "Concurrency diagnostics")
    check(base["IPHONEOS_DEPLOYMENT_TARGET"] == "17.0", "Deployment target")
    check(base["CODE_SIGNING_ALLOWED"] == "NO", "Unsigned configuration")
    check(base["GENERATE_INFOPLIST_FILE"] == "YES", "Info.plist generation")
    targets = spec["targets"]
    target_types = {"EyeLink": "application", "EyeLinkTests": "bundle.unit-test",
                    "EyeLinkUITests": "bundle.ui-testing"}
    check(set(targets) == set(target_types), "App, unit and UI test targets")
    for name, target in targets.items():
        expected_type = target_types[name]
        check(target["type"] == expected_type, f"Target type: {name}")
        check(target["platform"] == "iOS", f"Platform: {name}")
        identifier = target["settings"]["base"]["PRODUCT_BUNDLE_IDENTIFIER"]
        check(re.fullmatch(r"[A-Za-z0-9.-]+", identifier) is not None, "Bundle ID syntax")
        check(not identifier.startswith("com.example"), "Placeholder bundle ID")
        for source in target["sources"]:
            check((ROOT / source["path"]).is_dir(), f"Missing source directory: {source}")
    check(targets["EyeLinkTests"]["dependencies"] == [{"target": "EyeLink"}], "Test host dependency")
    check(targets["EyeLinkUITests"]["dependencies"] == [{"target": "EyeLink"}], "UI test host dependency")
    check(spec["schemes"]["EyeLink"]["test"]["targets"] == ["EyeLinkTests", "EyeLinkUITests"], "Test scheme")
    check(any(s.get("buildPhase") == "resources" for s in targets["EyeLink"]["sources"]), "Resources phase")
    check("DEVELOPMENT_TEAM" not in (ROOT / "project.yml").read_text(), "No signing team")
    for asset in (ROOT / "EyeLink/Resources").rglob("*.json"):
        json.loads(asset.read_text())
    sources = sorted((ROOT / "EyeLink").rglob("*.swift"))
    tests = sorted((ROOT / "EyeLinkTests").rglob("*.swift"))
    ui_tests = sorted((ROOT / "EyeLinkUITests").rglob("*.swift"))
    check(len(sources) > 0 and len(tests) > 0, "Sources and tests exist")
    for source in sources:
        content = source.read_text()
        imports = set(re.findall(r"^import (\w+)", content, re.M))
        check(not imports & {"CoreBluetooth", "AVFoundation", "SwiftData", "WebKit"}, f"Scope: {source}")
        if "Domain" in source.parts:
            check(imports <= {"Foundation"}, f"Domain dependency: {source}")
        if "Features" in source.parts:
            check("MockDevice" not in content, f"Presentation adapter coupling: {source}")
        check("URLSession" not in content, f"No REST implementation: {source}")
    test_content = "\n".join(path.read_text() for path in tests)
    check("Task.sleep" not in test_content and "Thread.sleep" not in test_content, "Tests must not sleep")
    cases = re.findall(r"func (test\w+)\(", test_content)
    check(len(cases) == len(set(cases)), "Unique test names")
    check(len(cases) == 24, "Preserved Phase 01 unit test inventory")
    ui_cases = re.findall(r"func (test\w+)\(", "\n".join(path.read_text() for path in ui_tests))
    check(len(ui_cases) == 4 and len(set(ui_cases)) == 4, "UI test inventory")
    workflow = yaml.safe_load((ROOT / "codemagic.yaml").read_text())
    check(set(workflow) == {"workflows"}, "Only prepared workflow definitions")
    check(set(workflow["workflows"]) == {"phase-02a-manual"}, "One manual workflow")
    for config in workflow["workflows"].values():
        check("triggering" not in config and "publishing" not in config, "No automatic triggers or publishing")
        check("integrations" not in config, "No signing integrations")
        check(config["environment"] == {"xcode": "16.4"}, "Pinned Xcode; no signing configuration")
        check(config["max_build_duration"] == 20, "Bounded runner time (not a cost authorization)")
    check(not list((ROOT / ".github/workflows").glob("*.y*ml")), "No active Actions workflow")
    for path in sources + tests + ui_tests + [ROOT / "project.yml"]:
        data = path.read_bytes()
        check(data.endswith(b"\n") and b"\r" not in data, f"LF/final newline: {path}")
        check(all(line.rstrip() == line for line in data.splitlines()), f"Whitespace: {path}")
    print(f"PASS: project settings/path/asset/boundary checks; {len(sources)} app Swift files; "
          f"{len(cases)} unit and {len(ui_cases)} UI XCTest methods inventoried, NOT executed.")
    print("XcodeGen generation, Swift compilation, iOS build and runtime tests: UNVERIFIED.")


if __name__ == "__main__":
    main()
