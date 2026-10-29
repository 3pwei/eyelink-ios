import XCTest

final class EyeLinkUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(scenario: String = "success", screen: String? = nil,
                        state: String? = nil) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_TW"]
        app.launchEnvironment["EYELINK_UI_TESTING"] = "1"
        app.launchEnvironment["EYELINK_UI_SCENARIO"] = scenario
        app.launchEnvironment["EYELINK_UI_SCREEN"] = screen
        app.launchEnvironment["EYELINK_UI_STATE"] = state
        app.launch()
        XCTAssertTrue(app.staticTexts["mock-mode"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["mock-mode"].label.contains("Mock Mode"))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable && app.windows.firstMatch.frame.contains(element.frame) { return }
            app.swipeUp()
        }
        XCTFail("Essential control is unreachable: \(element.identifier)")
    }

    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        // The full display includes status bar/home indicator for human safe-area review.
        let attachment = XCTAttachment(data: XCUIScreen.main.screenshot().pngRepresentation,
                                       uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func tap(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        reveal(button, in: app)
        XCTAssertTrue(button.isEnabled)
        button.tap()
    }

    @MainActor
    private func connectAndOpenExamination(_ app: XCUIApplication) {
        tap("connect", in: app)
        let next = app.buttons["open-examination"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: next)
        waitForExpectations(timeout: 10)
        tap("open-examination", in: app)
        XCTAssertTrue(app.staticTexts["examination-empty"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["mock-mode"].label.contains("Mock Mode"))
    }

    @MainActor
    func testNavigationAndMockLabels() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["dashboard-empty"].exists)
        capture("flow--dashboard--empty", app: app)
        tap("open-result", in: app)
        XCTAssertTrue(app.staticTexts["result-empty"].waitForExistence(timeout: 10))
        capture("flow--result--empty", app: app)
        tap("result-home", in: app)
        connectAndOpenExamination(app)
        capture("flow--examination--ready", app: app)
        tap("start-measurement", in: app)
        XCTAssertTrue(app.navigationBars["測試結果"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["mock-mode"].label.contains("Mock Mode"))
        capture("flow--result--success-top", app: app)
        let source = app.descendants(matching: .any)["result-source"].firstMatch
        reveal(source, in: app)
        XCTAssertTrue(app.staticTexts["Simulated"].exists)
        capture("flow--result--success-data", app: app)
        reveal(app.buttons["result-home"], in: app)
        capture("flow--result--success-bottom", app: app)
        tap("result-home", in: app)
        XCTAssertTrue(app.staticTexts["dashboard-empty"].waitForExistence(timeout: 10))
        app.terminate()
    }

    @MainActor
    func testConnectionFailure() {
        let app = launch(scenario: "connectionFailure")
        tap("connect", in: app)
        let error = app.staticTexts["session-error"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertTrue(error.label.contains("模擬連線失敗"))
        XCTAssertFalse(app.buttons["open-examination"].isEnabled)
        capture("flow--dashboard--error", app: app)
        app.terminate()
    }

    @MainActor
    func testMeasurementTimeout() {
        let app = launch(scenario: "measurementTimeout")
        connectAndOpenExamination(app)
        tap("start-measurement", in: app)
        let error = app.staticTexts["session-error"]
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        XCTAssertTrue(error.label.contains("模擬量測逾時"))
        XCTAssertFalse(app.buttons["start-measurement"].isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["result-source"].firstMatch.exists)
        capture("flow--examination--error", app: app)
        app.terminate()
    }

    @MainActor
    func testFrozenRenderingStates() {
        for screen in ["dashboard", "examination", "result"] {
            for state in ["empty", "loading", "error"] {
                let app = launch(screen: screen, state: state)
                let identifier: String
                switch state {
                case "loading": identifier = "session-loading"
                case "error": identifier = "session-error"
                default: identifier = "\(screen)-empty"
                }
                let marker = app.descendants(matching: .any)[identifier].firstMatch
                capture("fixture--\(screen)--\(state)--top", app: app)
                reveal(marker, in: app)
                capture("fixture--\(screen)--\(state)--detail", app: app)
                let control = screen == "dashboard" ? "disconnect" : "\(screen)-home"
                // Empty Dashboard has a disabled disconnect; inspect its visible frame separately.
                if screen == "dashboard" && state == "empty" {
                    reveal(app.buttons["connect"], in: app)
                } else {
                    reveal(app.buttons[control], in: app)
                }
                capture("fixture--\(screen)--\(state)--bottom", app: app)
                app.terminate()
            }
        }
    }
}
