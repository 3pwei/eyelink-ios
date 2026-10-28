# EyeLink iOS

Native iOS engineering portfolio：裝置連線、模擬量測、離線紀錄與同步的可驗證開發專案。

**目前是 Phase 00 工程規範與架構規劃；沒有已實作或已驗證的 iOS 功能。**
本階段沒有 App source、Xcode project、可安裝 IPA、iOS build 或裝置測試結果。
模擬量測僅供工程展示，不代表實際儀器讀值或醫療判讀。

## 開發環境與範圍

- Repository：[3pwei/eyelink-ios](https://github.com/3pwei/eyelink-ios)，Public；預設分支保留 `master`。
- 開發者：Windows + iPhone，主要工具 Codex，沒有本機 Mac。
- 規劃技術：Swift、SwiftUI、SwiftData、Core Bluetooth、AVFoundation、URLSession。
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
| [Phase 01 門檻](docs/release/phase-01-entry.md) | 開始實作前必備條件 |

## 本階段可執行的檢查

在 repository 根目錄執行，Python 3.10+，不需要第三方套件：

```powershell
python scripts/check_docs.py
git diff --check
```

這些檢查只驗證文件與 repository hygiene，不能證明 Swift 編譯、App 可執行或 BLE 正常。
尚未提供 `project.yml` 或 `codemagic.yaml`；不要將文件中的範例視為可立即執行的設定。

## 提交流程

從最新 `master` 建立短期 feature branch，透過 PR 合併；不直接 push `master`。
Phase 00 的空白基底初始化已取得一次性授權；目前受限於 Git 推送環境尚未完成，
見 [初始化狀態](docs/release/phase-00.md)。此授權僅涵蓋指定的零檔案 commit，不涵蓋直接寫入 Phase 00 檔案。
