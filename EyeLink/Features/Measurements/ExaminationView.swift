import SwiftUI

struct ExaminationView: View {
    @ObservedObject var model: DeviceSessionModel

    var body: some View {
        Form {
            Section { MockNoticeView() }
            Section("Examination") {
                SessionStatusView(model: model)
                if model.snapshot.deviceState == .measuring {
                    ProgressView(value: model.snapshot.progress) {
                        Text("量測進度 \(Int(model.snapshot.progress * 100))%")
                    }
                    .accessibilityIdentifier("measurement-progress")
                } else if model.snapshot.measurementResult == nil && model.error == nil {
                    Text("尚無量測。按下 Start Measurement 產生模擬測試資料。")
                        .accessibilityIdentifier("examination-empty")
                }
                Button("Start Measurement") { Task { await model.startMeasurement() } }
                    .disabled(model.snapshot.deviceState != .ready || model.isBusy)
                    .accessibilityIdentifier("start-measurement")
                Button("Cancel Measurement", role: .destructive) { model.cancelMeasurement() }
                    .disabled(model.snapshot.deviceState != .measuring)
                    .accessibilityIdentifier("cancel-measurement")
                if model.snapshot.measurementResult != nil && !model.isBusy {
                    Button("查看結果") { model.screen = .result }
                }
            }
            Section {
                Button("返回設備首頁") { model.returnHome() }
                    .accessibilityIdentifier("examination-home")
            }
        }
        .navigationTitle("模擬量測")
    }
}
