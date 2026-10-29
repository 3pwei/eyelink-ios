import SwiftUI

@main
@MainActor
struct EyeLinkApp: App {
    var body: some Scene {
        WindowGroup { EyeLinkRootView() }
    }
}

@MainActor
struct EyeLinkRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var scenario: MockScenario
    @StateObject private var model: DeviceSessionModel

    init() {
        #if DEBUG
        let launch = UIValidationLaunch()
        _scenario = State(initialValue: launch.scenario)
        _model = StateObject(wrappedValue: launch.makeModel())
        #else
        _scenario = State(initialValue: .success)
        _model = StateObject(wrappedValue: DeviceSessionModel(transport: MockDevice()))
        #endif
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.screen {
                case .dashboard: DeviceDashboardView(model: model)
                case .examination: ExaminationView(model: model)
                case .result: ResultView(model: model)
                }
            }
            .toolbar {
                if model.screen == .dashboard {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu("模擬情境") {
                            Picker("模擬情境", selection: $scenario) {
                                ForEach(MockScenario.allCases) { scenario in
                                    Text(scenario.label).tag(scenario)
                                }
                            }
                        }
                        .disabled(model.isBusy)
                    }
                }
            }
        }
        .task(id: model.sessionID) { await model.observe() }
        .onChange(of: scenario) { _, value in
            model.replaceTransport(MockDevice(scenario: value))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.suspend() }
        }
    }
}

private extension MockScenario {
    var label: String {
        switch self {
        case .success: return "正常連線／量測成功"
        case .connectionFailure: return "連線失敗"
        case .measurementTimeout: return "量測逾時"
        case .disconnectDuringMeasurement: return "量測中斷線"
        }
    }
}
