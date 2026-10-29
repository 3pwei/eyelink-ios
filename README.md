# EyeLink iOS

Native iOS engineering portfolio：裝置連線、模擬量測、離線紀錄與同步的可驗證開發專案。

**Phase 01 原生基礎已加入原始碼，狀態為 Implemented / Unverified。**
包含 SwiftUI 三個畫面、可替換 DeviceTransport、MockDevice、確定性 XCTest 與 XcodeGen spec。
尚未經 macOS／Xcode 編譯、XCTest 執行或 Simulator／iPhone 驗證；沒有可安裝 IPA。
模擬量測僅供工程展示，不代表實際儀器讀值或醫療判讀。

Phase 02A 已完成唯一一次手動 M2 建置：XcodeGen 成功，**Debug Build 因缺少 AppIcon 資產失敗**。
耗時 1 分 13 秒；XCTest／Simulator／截圖未執行。Debug Simulator 設定修正已準備，尚未重跑驗證。
見 [真實建置與費用證據](docs/testing/evidence/phase-02a-run-01.md)；第二次執行需要新的明確授權。
見 [Phase 02A 操作與人工審查](docs/testing/phase-02a.md)。

## 開發環境與範圍

- Repository：[3pwei/eyelink-ios](https://github.com/3pwei/eyelink-ios)，Public；預設分支保留 `master`。
- 開發者：Windows + iPhone，主要工具 Codex，沒有本機 Mac。
- Phase 01：Swift、SwiftUI、Swift Concurrency、XCTest、XcodeGen；無第三方 App 套件。
- 後續規劃：SwiftData、Core Bluetooth、AVFoundation、URLSession，本階段未實作。
- 規劃 deployment target：iOS 17.0；實際 iPhone 相容性於 Phase 01 確認。
- macOS 編譯與模擬器測試規劃使用 Codemagic；Phase 00 不啟用或觸發雲端建置。
- 授權提案：MIT，見 [LICENSE](LICENSE)；由維護者在合併前確認。

## 文件入口

| 文件 | 用途 |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Codex 與工程代理的操作限制 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commit、branch、PR、review 規範 |
| [架構](docs/architecture/overview.md) | 模組邊界與預定 source layout |
| [架構決策](docs/architecture/decisions.md) | 決策、取捨與待確認項目 |
| [DeviceTransport](docs/architecture/device-transport.md) | 真實 BLE 與 MockDevice 契約 |
| [需求追溯](docs/requirements/traceability.md) | 職缺能力、需求、驗收、證據對照 |
| [測試策略](docs/testing/strategy.md) | 靜態、模擬器與實機的證據界線 |
| [證據模板](docs/testing/evidence-template.md) | 可重現的驗證紀錄 |
| [建置規劃](docs/release/build-plan.md) | XcodeGen、Codemagic、Windows 工作流 |
| [Phase 00 狀態](docs/release/phase-00.md) | 遠端基準、交付與已知風險 |
| [Phase 01 門檻](docs/release/phase-01-entry.md) | 實作與編譯驗證的不同門檻 |
| [Phase 01 交付](docs/release/phase-01.md) | 使用方式、範圍、未驗證項目與 Phase 02 條件 |
| [Phase 01 測試](docs/testing/phase-01.md) | XCTest 對照、手動驗收與執行命令 |
| [Phase 02A 交付](docs/release/phase-02a.md) | 建置／UI 驗證準備與阻礙 |
| [Phase 02A 執行](docs/testing/phase-02a.md) | 費用門檻、Simulator 矩陣、Artifacts 下載與人工檢視 |

## 本階段可執行的檢查

在 repository 根目錄執行，Python 3.10+，不需要第三方套件：

```powershell
python scripts/check_docs.py
git diff --check
```

這些檢查只驗證文件與 repository hygiene，不能證明 Swift 編譯、App 可執行或 BLE 正常。
已提供 `project.yml` 與手動 `codemagic.yaml`；來源 `d1548af` 已成功生成專案，但 Debug Build 失敗。
後續圖示設定修正尚未經 macOS 驗證；沒有自動 CI trigger，也未啟動第二次建置。
靜態 project 檢查：`python scripts/check_phase01.py`，需要 PyYAML 6.0.3（僅檢查工具，本環境已安裝）。
macOS 生成與測試步驟見 [Phase 01 測試](docs/testing/phase-01.md)。
Phase 02A 工具的 Linux regression checks：`python -m unittest discover -s scripts -p 'test_phase02a_tools.py' -v`。
這些只測試證據工具的失敗處理，不能代替 XCTest。

## 提交流程

從最新 `master` 建立短期 feature branch，透過 PR 合併；不直接 push `master`。
Phase 00 已透過 [PR #1](https://github.com/3pwei/eyelink-ios/pull/1) 合併，Phase 01 基於 `79824ac3351f21285e9080e259b19826c0d8b307`。
Phase 01 已透過 [PR #2](https://github.com/3pwei/eyelink-ios/pull/2) 合併；Phase 02A 基於 master `42d44bb64e5fdf7c6ff6a0615338ff7c07679762`。
見 [交付狀態](docs/release/phase-00.md)。後續變更繼續遵守 feature branch 與 PR 流程。
