# Phase 02A — iOS Build & UI Visual Verification

狀態：**首次 macOS 建置已執行但 Debug Build 失敗；修正 Implemented / Unverified；XCTest／UI Blocked**。
日期：2026-10-29（Asia/Taipei）。[首次建置結果](evidence/phase-02a-run-01.md)記錄真實環境、失敗日誌與 Artifacts。
已執行的 Linux 檢查見 [準備階段證據](evidence/phase-02a-static.md)。
帳戶查證完成後已使用唯一一次建置授權，詳見 [費用與帳戶驗證紀錄](phase-02a-authorization.md)；不得重試或再啟動。

## 起點與範圍

- [PR #2](https://github.com/3pwei/eyelink-ios/pull/2) 已合併；base master：`42d44bb64e5fdf7c6ff6a0615338ff7c07679762`。
- 分支：`feature/phase-02a-build-ui-validation`；僅透過 PR → master，不自行合併。
- 沿用 Phase 01 的 SwiftUI、DeviceTransport、MockDevice 與 24 個單元測試。
- 加入 4 個 XCUITest 方法、Debug 限定的可重現 UI 情境、手動 Codemagic 設定與證據匯出。
- 不實作 BLE／Camera／REST／SwiftData；不簽章、不產生 IPA、不發布 TestFlight／App Store。
- 本階段只做 Debug 驗證；Phase 01 文件中的 Release build、實機與完整 VoiceOver 驗收仍待後續處理。

## 費用與啟動門檻

[codemagic.yaml](../../codemagic.yaml) 是準備好的設定，沒有 `triggering`、`publishing` 或 signing integrations。
已用公開 Git URL 新增 Codemagic App；未新增 webhook／schedule，唯一一次 M2 runner 已執行。
執行前個人帳戶免費額度 0/500、Billing 未啟用；執行後額度 1/500，無交易紀錄或獨立美元費用欄位。
以下是每次執行的操作門檻；並非第二次建置授權。

Owner 已核准 M2、一次最多 20 分鐘、單次 US$2.00、Phase 02A 累計 US$5.00；不得重試或第二次建置。
執行前仍須查證以下項目並記錄，不再重複索取相同費用授權：

| 項目 | 待核准內容 |
| --- | --- |
| 來源 | 此 feature branch 的完整 commit SHA；不需要先合併 master |
| 範圍 | 一次 `phase-02a-manual`，優先 Debug build、24 unit tests，再視剩餘時間執行 UI matrix、artifact 匯出 |
| Runner | `mac_mini_m2`、Xcode 16.4，單次最多 20 分鐘，並行 1、不自動重試 |
| 費用 | 查證 Individual/Team、適用費率、剩餘免費分鐘、Billing 狀態與實際停止條件；單次 ≤ US$2、累計 ≤ US$5 |
| 外部設定 | 檢查 automatic build／schedule／webhook；不要開啟 push／PR 自動建置 |

任何帳戶費率、免費額度或費用控制方式無法查證時停留在設定準備。腳本不能在 runner 啟動後替使用者防止計費。
全部前置檢查完成後，在 Codemagic 選擇 repository → Start new build → 此分支 → `phase-02a-manual`，核對 SHA 後啟動一次。
沒有互動式 Simulator 的承諾；此流程使用 `simctl` 與 XCUITest 在 macOS 背景執行。
若無法啟動 runtime／Simulator，該組測試標示 FAILED / BLOCKED 並保存診斷，不切換成 mockup。

## 環境與矩陣

首次執行已確認 macOS 15.5 (24F74)、Xcode 16.4 (16F6)、Swift 6.1.2、XcodeGen 2.44.1。
Simulator 未啟動，以下裝置／runtime／字級仍為預定值；修正後的專案尚未重新生成或編譯。

| 元件 | 選定值 / 實際值取得方式 |
| --- | --- |
| macOS | Codemagic Xcode 16.4 image 文件列 macOS 15.5；執行時以 `sw_vers` 為準 |
| Xcode | 16.4 / build 16F6；不同版本會停止，不使用 latest |
| Swift | 由 `xcrun swift --version` 紀錄；`SWIFT_VERSION: 5.0` 仍只是 language mode |
| XcodeGen | 2.44.1；下載 upstream zip 並核對 SHA-256 |
| iPhone 16 | iOS 18.5，portrait／light／預設 large 字級 |
| iPhone SE (3rd generation) | iOS 17.5，portrait／light／預設 large 字級 |
| iPhone SE (3rd generation) | iOS 17.5，portrait／light／accessibility-extra-extra-extra-large 字級 |

選定 image 與 XcodeGen 生成已取得一次成功證據；Debug Build 因 AppIcon 缺漏失敗，後續測試未執行。
不宣稱 iOS 17.0 runtime 已測；iOS 17.0 deployment target 與 17.5 測試 runtime 是不同事項。
腳本會驗證 runtime 存在，建立專用 Simulator，紀錄實際 UUID，再於結束時刪除本次建立的裝置。
不使用預先捏造的 UUID，不下載額外 runtime，不改動使用者既有 Simulator。
PNG 像素尺寸寫入 manifest；裝置型號／runtime／字級對照亦寫入 manifest。

XcodeGen zip checksum：`a2e905fb68446e9bb4008cdfe2e13e3f176d0cbcca828b71770f8e53fca91b73`。
來源為 [2.44.1 release asset metadata](https://api.github.com/repos/yonaskolb/XcodeGen/releases/tags/2.44.1) 的 `xcodegen.zip` digest；runner 仍須實際核對下載內容。

## 執行命令與失敗處理

在已具備授權、Xcode 16.4 的 macOS 上，使用乾淨且已提交的 checkout：

```sh
python3 scripts/run_phase02a.py
```

腳本只有 Python standard library 依賴。所有實際命令、exit code、環境與 source SHA 都會記錄。
主要步驟：checksum 驗證並安裝 XcodeGen → `xcodegen generate --spec project.yml` →
`xcodebuild -list`／build settings → unsigned Debug Simulator build → unit tests → 3 組 UI tests → 匯出。
每個 `xcodebuild` 都使用 `CODE_SIGNING_ALLOWED=NO`；測試關閉平行執行與隱含裝置選擇。
單元測試只在第一組 iPhone 16 執行一次；UI methods 在三組各執行一次。
內部工作預算 15 分鐘，另留 3 分鐘匯出與清理；超時為失敗，仍嘗試封裝已存在的證據。

輸出固定在忽略追蹤的 `artifacts/phase-02a/`；目錄已存在時拒絕覆寫，請先保存舊證據並使用新 checkout。
任何命令失敗保留 log；單元測試命令失敗不再開始 UI。每組 UI 啟動前需有至少 180 秒工作時間，否則明確 NOT RUN。
缺少裝置、時間不足或 UI 失敗都不會被當作 pass。
`xcresulttool get test-results summary` 必須有 24 unit 或 4 UI passes，且 failures/skips 都為 0。
每組 UI 匯出至少 35 個 PNG 附件，否則 artifact gate 失敗。這些數量是預期，不是已執行的結果。
失敗 bundle 仍保存；若 summary／attachment 匯出本身失敗，原始 `.xcresult` 與錯誤 log 保留供診斷。
所有 stage 成功仍只標示 `AUTOMATED CHECKS PASSED; VISUAL REVIEW PENDING`。
runner 被平台強制中止或 timeout 時，finally／ZIP 不保證完成；YAML 另收集已寫出的散檔，不宣稱取消後必有完整證據。

## UI 測試與截圖對照

| XCTest method | 驗證與附件 |
| --- | --- |
| testNavigationAndMockLabels | Dashboard empty → Result empty → home → connect → Examination → start → Result success → home；Mock Mode／Simulated；6 個 flow PNG |
| testConnectionFailure | 真正操作 MockDevice connectionFailure；可重試錯誤、不能進入 Examination；1 個 flow PNG |
| testMeasurementTimeout | 真正操作 MockDevice measurementTimeout；留在 Examination、不產生 Result；1 個 flow PNG |
| testFrozenRenderingStates | 三畫面 × empty/loading/error，包含 Result 防禦性 loading/error 分支；每情境 top/detail/bottom，共 27 個 fixture PNG |

`flow--…` 附件是操作現有 MockDevice 的執行畫面。`fixture--…` 附件是 Debug 注入固定 snapshot 後，
**在實際 Simulator 渲染同一套 SwiftUI Views** 的畫面；僅證明該狀態的 rendering，不證明轉場或 BLE。
固定 fixture 避免 500ms loading 狀態造成截圖競速，並覆蓋正常成功流程不會停留的 Result loading/error。
`EYELINK_UI_TESTING=1` 才接受測試環境參數；Release 不編入測試 adapter，普通啟動仍用既有 MockDevice。
這些測試沒有合成畫面、程式碼截圖或預製 PNG；只有 `XCUIScreen.main.screenshot().pngRepresentation`。

UI 會檢查必要控制項可捲動至畫面內並可點擊。這不能證明 glyph 未截斷、Safe Area 正確或 VoiceOver 順序合格。
整個螢幕截圖保留 status bar／home indicator；最大字級用 top/detail/bottom 附件檢視內容與控制項。

## 人工檢視與下載方式

完成**實際建置後**，在該 Codemagic build detail 的 Artifacts 區下載 `phase-02a-evidence.zip`。
Windows／macOS 解壓縮，直接用瀏覽器開啟 `phase-02a/index.html`，不需要 Xcode 或互動式雲端 Simulator。
點擊縮圖可看原始 PNG。gallery 顯示附件名稱、檔案路徑與像素尺寸；來源對應保存在 attachment manifest。
JSON 的 `manifest.json` 包含 SHA、工具版本、裝置／字級、命令、stage 結果與 PNG hashes。
每組有 raw `.xcresult`、summary JSON、build／test／export logs；macOS 可用 Xcode 開啟 `.xcresult` 深查。
下載後保存 ZIP，避免依賴帳戶 artifact 保留期限。
[首次 Build](https://codemagic.io/app/6ae2c9db01af2bc8f930cd97/build/6ae2caa5206ce93970c71bfe)
已有失敗診斷 ZIP；HTML 明確顯示沒有 PNG，不能用來做 UI 人工驗收。

人工審查表（每一裝置／字級與三個畫面都需填寫）：

| 檢查 | 目前結果 | 填寫證據 |
| --- | --- | --- |
| Dashboard／Examination／Result 實際畫面 | NOT RUN | build URL、PNG 附件名 |
| Loading／Error／empty 分支 | NOT RUN | flow 或 fixture、狀態與附件名 |
| Mock Mode／Simulated／非醫療聲明清楚 | NOT RUN | 附件名、文字是否完整 |
| 中英文字不截斷、無重疊、數值與時間可讀 | NOT RUN | 預設與最大字級；必要時 issue |
| Safe Area、頂端標題、底部按鈕可達 | NOT RUN | top/detail/bottom PNG |
| 審查人、日期與結論 | PENDING | 人工 pass/fail、限制、後續修正 PR |

## 官方參考（2026-10-29 查閱）

- [Codemagic manual / automatic triggering](https://docs.codemagic.io/yaml-running-builds/starting-builds-automatically/)
- [Codemagic YAML / artifacts](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Codemagic Xcode 16.4 image](https://docs.codemagic.io/specs-macos/xcode-16-4/)
- [Apple xcresulttool additions](https://developer.apple.com/documentation/xcode-release-notes/xcode-16_3-release-notes)
- [XcodeGen project specification](https://github.com/yonaskolb/XcodeGen/blob/2.44.1/Docs/ProjectSpec.md)
