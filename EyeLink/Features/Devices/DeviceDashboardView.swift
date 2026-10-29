import SwiftUI

struct DeviceDashboardView: View {
    @ObservedObject var model: DeviceSessionModel

    var body: some View {
        Form {
            Section { MockNoticeView() }
            Section("Device Dashboard") {
                Text(model.snapshot.deviceName).font(.headline)
                LabeledContent("連線狀態", value: model.snapshot.deviceState.label)
                SessionStatusView(model: model)
                if model.snapshot.deviceState == .idle {
                    Text("尚未連線。請連線至模擬裝置以開始測試。")
                        .accessibilityIdentifier("dashboard-empty")
                }
                Button("Connect / 重新連線") { Task { await model.connect() } }
                    .disabled(model.isBusy || model.snapshot.deviceState == .ready)
                    .accessibilityIdentifier("connect")
                Button("Disconnect") { model.disconnect() }
                    .disabled(model.snapshot.deviceState == .idle)
                    .accessibilityIdentifier("disconnect")
            }
            Section {
                Button("前往量測") { model.screen = .examination }
                    .disabled(model.snapshot.deviceState != .ready)
                    .accessibilityIdentifier("open-examination")
                Button("查看結果") { model.screen = .result }
                    .disabled(model.isBusy)
                    .accessibilityIdentifier("open-result")
            }
        }
        .navigationTitle("EyeLink")
    }
}
