#!/usr/bin/env python3
"""Manually authorized macOS validation only; no CI trigger or account API calls.

Python standard library only. Fresh artifacts required; failed outputs are preserved.
The provider's 20-minute runner limit is separate from (and not) a currency cost cap.
"""

from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import shlex
import signal
import subprocess
import sys
import time
import uuid

from phase02a_report import write_report

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "artifacts/phase-02a"
MATRIX = [
    ("iphone16-default", "iPhone 16", "com.apple.CoreSimulator.SimDeviceType.iPhone-16",
     "com.apple.CoreSimulator.SimRuntime.iOS-18-5", "large"),
    ("se3-default", "iPhone SE (3rd generation)", "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
     "com.apple.CoreSimulator.SimRuntime.iOS-17-5", "large"),
    ("se3-accessibility", "iPhone SE (3rd generation)", "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
     "com.apple.CoreSimulator.SimRuntime.iOS-17-5", "accessibility-extra-extra-extra-large"),
]


class Validation:
    def __init__(self):
        self.manifest = {
            "started_utc": datetime.now(timezone.utc).isoformat(),
            "host": platform.platform(), "python": platform.python_version(),
            "result": "FAILED", "commands": [], "devices": [],
            "stages": {key: "NOT RUN" for key in
                       ["preflight", "generation", "debug-build", "unit-tests"] +
                       [f"ui-{row[0]}" for row in MATRIX]},
        }
        self.created = []
        self.bundles = []
        self.failed = False
        # Leave time to export and zip evidence before the provider's 20-minute limit.
        self.deadline = time.monotonic() + 900

    def run(self, name, command, timeout=180):
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise RuntimeError(f"{name}: internal time budget exhausted; preserving partial evidence")
        timeout = min(timeout, remaining)
        log = OUTPUT / f"{name}.log"
        command = [str(arg) for arg in command]
        entry = {"name": name, "argv": command, "log": log.name}
        self.manifest["commands"].append(entry)
        print(f"$ {shlex.join(command)}", flush=True)
        with log.open("w") as stream:
            stream.write(f"$ {shlex.join(command)}\n")
            stream.flush()
            process = subprocess.Popen(command, cwd=ROOT, stdout=stream,
                                       stderr=subprocess.STDOUT, start_new_session=True)
            try:
                code = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                code = 124
            entry["exit_code"] = code
        text = log.read_text()
        if code:
            raise RuntimeError(f"{name}: exit {code}; see {log.name}")
        return text.split("\n", 1)[1]

    def stage(self, name, action):
        try:
            action()
            self.manifest["stages"][name] = "PASS"
            return True
        except Exception as error:
            self.failed = True
            self.manifest["stages"][name] = f"FAILED / BLOCKED: {error}"
            print(self.manifest["stages"][name], flush=True)
            return False
        finally:
            (OUTPUT / "manifest.json").write_text(json.dumps(self.manifest, indent=2) + "\n")

    def preflight(self):
        self.manifest["commit"] = self.run("commit", ["git", "rev-parse", "HEAD"]).strip()
        dirty = self.run("working-tree", ["git", "status", "--porcelain"]).strip()
        if dirty:
            raise RuntimeError("Commit all source changes before collecting SHA-linked evidence")
        if platform.system() != "Darwin":
            raise RuntimeError("macOS/Xcode required; no Simulator evidence can be produced on this host")
        self.manifest["macos"] = self.run("macos", ["sw_vers"])
        self.manifest["xcode"] = self.run("xcode", ["xcodebuild", "-version"])
        if self.manifest["xcode"].strip() != "Xcode 16.4\nBuild version 16F6":
            raise RuntimeError("Expected Xcode 16.4 (16F6); do not silently select another toolchain")
        self.manifest["swift"] = self.run("swift", ["xcrun", "swift", "--version"])
        self.run("install-xcodegen", ["bash", "scripts/install_xcodegen.sh"])
        self.xcodegen = ROOT / "build/tools/xcodegen/bin/xcodegen"
        self.manifest["xcodegen"] = self.run("xcodegen-version", [self.xcodegen, "--version"])
        if "2.44.1" not in self.manifest["xcodegen"]:
            raise RuntimeError("XcodeGen version mismatch")

    def xcode(self, name, arguments, timeout=300):
        return self.run(name, ["xcodebuild", "-project", "EyeLink.xcodeproj", "-scheme", "EyeLink",
                              "-configuration", "Debug", "-derivedDataPath", "build/DerivedData",
                              "CODE_SIGNING_ALLOWED=NO"] + arguments, timeout)

    def generate(self):
        self.run("generate", [self.xcodegen, "generate", "--spec", "project.yml"])
        self.run("project-list", ["xcodebuild", "-list", "-project", "EyeLink.xcodeproj"])
        self.xcode("build-settings", ["-showBuildSettings", "-destination", "generic/platform=iOS Simulator"])

    def simulator(self, row):
        key, model, device_type, runtime, size = row
        # Validate the exact runtime on this runner; no download or latest-device fallback.
        available = json.loads(self.run(f"runtimes-{key}", ["xcrun", "simctl", "list", "runtimes", "--json"]))
        if not any(r["identifier"] == runtime and r.get("isAvailable") for r in available["runtimes"]):
            raise RuntimeError(f"Required runtime unavailable: {runtime}")
        udid = self.run(f"create-{key}", ["xcrun", "simctl", "create", f"EyeLink-{key}", device_type, runtime]).strip()
        uuid.UUID(udid)  # Only use a real UUID returned by simctl.
        self.created.append(udid)
        self.manifest["devices"].append({"matrix": key, "model": model, "runtime": runtime,
                                         "udid": udid, "content_size": size, "orientation": "portrait"})
        self.run(f"boot-{key}", ["xcrun", "simctl", "boot", udid])
        self.run(f"bootstatus-{key}", ["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=120)
        self.run(f"appearance-{key}", ["xcrun", "simctl", "ui", udid, "appearance", "light"])
        self.run(f"content-size-{key}", ["xcrun", "simctl", "ui", udid, "content_size", size])
        actual_size = self.run(f"content-size-readback-{key}", ["xcrun", "simctl", "ui", udid, "content_size"]).strip()
        self.manifest["devices"][-1]["content_size_readback"] = actual_size
        if actual_size.lower() != size:
            raise RuntimeError(f"Dynamic Type setting mismatch: {actual_size!r}, expected {size!r}")
        self.run(f"devices-{key}", ["xcrun", "simctl", "list", "devices", "--json"])
        return udid

    def tests(self, key, target, udid):
        bundle = OUTPUT / f"{key}.xcresult"
        self.bundles.append((key, bundle, target))
        self.xcode(key, ["-destination", f"platform=iOS Simulator,id={udid}",
                         "-resultBundlePath", str(bundle), "-only-testing:" + target,
                         "-parallel-testing-enabled", "NO", "-maximum-concurrent-test-simulator-destinations", "1",
                         "-test-timeouts-enabled", "YES", "-default-test-execution-time-allowance", "180",
                         "-maximum-test-execution-time-allowance", "180", "test"], timeout=420)

    def matrix(self, row):
        key = row[0]
        udid = self.simulator(row)
        # Unit failures must not discard independent UI evidence.
        if key == "iphone16-default":
            self.stage("unit-tests", lambda: self.tests("unit-tests", "EyeLinkTests", udid))
        try:
            self.tests(f"ui-{key}", "EyeLinkUITests", udid)
        finally:
            self.run(f"shutdown-{key}", ["xcrun", "simctl", "shutdown", udid])

    def export(self, key, bundle, target):
        if not bundle.exists():
            raise RuntimeError(f"No result bundle created for {key}")
        summary = self.run(f"summary-{key}", ["xcrun", "xcresulttool", "get", "test-results", "summary",
                                               "--path", str(bundle)])
        (OUTPUT / f"{key}-summary.json").write_text(summary)
        data = json.loads(summary)
        # Require all authored tests, with no silent skips or zero-test success.
        expected = 24 if target == "EyeLinkTests" else 4
        summary_ok = data.get("passedTests") == expected and data.get("failedTests") == 0 and data.get("skippedTests") == 0
        if target == "EyeLinkUITests":
            destination = OUTPUT / "attachments" / key
            destination.mkdir(parents=True)
            self.run(f"attachments-{key}", ["xcrun", "xcresulttool", "export", "attachments",
                                            "--path", str(bundle), "--output-path", str(destination)])
            # 8 flow + 27 frozen-state PNG attachments. Failed-test diagnostics cannot
            # establish a pass: the XCTest exit code and strict summary gate also apply.
            if len(list(destination.rglob("*.png"))) < 35:
                raise RuntimeError(f"Incomplete PNG evidence for {key}; expected at least 35")
        if not summary_ok:
            raise RuntimeError(f"Expected {expected} passed tests and zero failures/skips; inspect summary JSON")

    def execute(self):
        try:
            if self.stage("preflight", self.preflight) and self.stage("generation", self.generate):
                if self.stage("debug-build", lambda: self.xcode("debug-build", ["-destination", "generic/platform=iOS Simulator", "build"])):
                    for row in MATRIX:
                        self.stage(f"ui-{row[0]}", lambda row=row: self.matrix(row))
        finally:
            self.deadline = time.monotonic() + 180
            for key, bundle, target in self.bundles:
                self.stage(f"export-{key}", lambda k=key, b=bundle, t=target: self.export(k, b, t))
            for index, udid in enumerate(self.created):
                # Delete only disposable devices created by this invocation.
                self.stage(f"cleanup-{index}", lambda u=udid, i=index: self.run(f"delete-{i}", ["xcrun", "simctl", "delete", u]))
            if any(value != "PASS" for value in self.manifest["stages"].values()):
                self.failed = True
            self.manifest["result"] = "FAILED / BLOCKED" if self.failed else "AUTOMATED CHECKS PASSED; VISUAL REVIEW PENDING"
            self.manifest["finished_utc"] = datetime.now(timezone.utc).isoformat()
            write_report(OUTPUT, self.manifest)
        return 1 if self.failed else 0


def main():
    os.chdir(ROOT)
    # Never mix evidence from different commits or runs; keep old directories separately.
    OUTPUT.mkdir(parents=True, exist_ok=False)
    return Validation().execute()


if __name__ == "__main__":
    sys.exit(main())
