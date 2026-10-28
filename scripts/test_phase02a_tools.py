"""Linux-safe harness regression tests; these do not execute or simulate XCTest."""

import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import run_phase02a as runner
from phase02a_report import png_dimensions, write_report


class HarnessTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.output = self.root / "artifacts/phase-02a"
        self.output.mkdir(parents=True)
        self.root_patch = patch.object(runner, "ROOT", self.root)
        self.output_patch = patch.object(runner, "OUTPUT", self.output)
        self.root_patch.start()
        self.output_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.addCleanup(self.output_patch.stop)

    def test_command_failure_keeps_log_and_exit_code(self):
        validation = runner.Validation()
        with self.assertRaisesRegex(RuntimeError, "exit 7"):
            validation.run("failure", [sys.executable, "-c", "print('diagnostic'); raise SystemExit(7)"])
        self.assertIn("diagnostic", (self.output / "failure.log").read_text())
        self.assertEqual(validation.manifest["commands"][0]["exit_code"], 7)

    def test_missing_runtime_does_not_create_device(self):
        validation = runner.Validation()
        with patch.object(validation, "run", return_value='{"runtimes": []}') as command:
            with self.assertRaisesRegex(RuntimeError, "runtime unavailable"):
                validation.simulator(runner.MATRIX[0])
        self.assertEqual(command.call_count, 1)
        self.assertEqual(validation.created, [])

    def test_failed_build_packages_blocked_report(self):
        validation = runner.Validation()
        with patch.object(validation, "preflight"), patch.object(validation, "generate"), \
             patch.object(validation, "xcode", side_effect=RuntimeError("compiler rejected source")):
            self.assertEqual(validation.execute(), 1)
        manifest = json.loads((self.output / "manifest.json").read_text())
        self.assertEqual(manifest["result"], "FAILED / BLOCKED")
        self.assertEqual(manifest["stages"]["unit-tests"], "NOT RUN")
        self.assertEqual(manifest["screenshots"], [])
        with zipfile.ZipFile(self.output.parent / "phase-02a-evidence.zip") as archive:
            self.assertIn("phase-02a/index.html", archive.namelist())
            self.assertIn("phase-02a/manifest.json", archive.namelist())

    def test_test_summary_rejects_skipped_or_zero_tests(self):
        for passed, skipped in [(0, 0), (23, 1)]:
            validation = runner.Validation()
            bundle = self.output / "unit.xcresult"
            bundle.mkdir(exist_ok=True)
            summary = json.dumps({"passedTests": passed, "failedTests": 0, "skippedTests": skipped})
            with patch.object(validation, "run", return_value=summary):
                with self.assertRaisesRegex(RuntimeError, "Expected 24 passed"):
                    validation.export("unit", bundle, "EyeLinkTests")

    def test_report_does_not_invent_screenshots_or_visual_pass(self):
        manifest = {"commit": "<untrusted>", "result": "FAILED / BLOCKED", "stages": {"UI": "NOT RUN"}}
        write_report(self.output, manifest)
        page = (self.output / "index.html").read_text()
        self.assertIn("&lt;untrusted&gt;", page)
        self.assertIn("No PNG evidence available", page)
        self.assertIn("Human visual review: PENDING", page)
        self.assertEqual(manifest["screenshots"], [])

    def test_non_png_attachment_is_rejected(self):
        attachment = self.output / "invalid.png"
        attachment.write_bytes(b"not an image")
        with self.assertRaises(ValueError):
            png_dimensions(attachment)


if __name__ == "__main__":
    unittest.main()
