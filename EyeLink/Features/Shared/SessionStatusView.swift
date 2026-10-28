import SwiftUI

extension DeviceError {
    var message: String {
        switch self {
        case .invalidState: return "請先返回設備首頁並連線，再開始量測。"
        case .operationInProgress: return "已有操作進行中，請等待完成或取消。"
        case .connectionFailed: return "模擬連線失敗。可重試，或切換模擬情境。"
        case .measurementTimedOut: return "模擬量測逾時，連線已清理。請重新連線後重試。"
        case .disconnected: return "連線已中斷，未完成的量測不會產生結果。請重新連線。"
        case .cancelled: return "量測已取消，連線已清理。請重新連線後重試。"
        }
    }
}

extension DeviceState {
    var label: String {
        switch self {
        case .idle: return "未連線"
        case .connecting: return "連線中"
        case .ready: return "已連線"
        case .measuring: return "量測中"
        case .failed: return "操作失敗／未連線"
        }
    }
}

struct MockNoticeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Mock Mode · 模擬裝置", systemImage: "testtube.2")
                .font(.headline)
                .accessibilityIdentifier("mock-mode")
            Text("所有數值均為測試資料，不代表實際儀器讀值，無醫療意義。")
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
    }
}

/// Shared loading/error rendering; each screen supplies its own empty/content state.
struct SessionStatusView: View {
    @ObservedObject var model: DeviceSessionModel

    var body: some View {
        if model.isBusy {
            ProgressView(model.snapshot.deviceState.label)
                .accessibilityIdentifier("session-loading")
        }
        if let error = model.error {
            Label(error.message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .accessibilityIdentifier("session-error")
        }
    }
}
