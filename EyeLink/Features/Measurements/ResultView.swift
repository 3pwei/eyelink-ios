import SwiftUI

struct ResultView: View {
    @ObservedObject var model: DeviceSessionModel

    var body: some View {
        Form {
            Section { MockNoticeView() }
            Section("Result") {
                SessionStatusView(model: model)
                if model.isBusy {
                    Text("等待本次量測完成。")
                } else if let result = model.snapshot.measurementResult {
                    LabeledContent("測試數值（任意點數）", value: result.testValue.formatted())
                    LabeledContent("量測時間") {
                        Text(result.measuredAt, format: .dateTime.year().month().day().hour().minute().second())
                    }
                    LabeledContent("資料來源", value: result.source == .mock ? "Simulated" : "Unknown")
                        .accessibilityIdentifier("result-source")
                    Text("僅保存在本次 App 工作階段，關閉 App 後不保留。")
                        .font(.footnote)
                } else {
                    Text("尚無量測結果。請返回設備首頁，連線後開始量測。")
                        .accessibilityIdentifier("result-empty")
                }
            }
            Section {
                Button("返回設備首頁") { model.returnHome() }
                    .accessibilityIdentifier("result-home")
            }
        }
        .navigationTitle("測試結果")
    }
}
