# MapleStory 登入啟動器 — 原始碼

多帳號一鍵登入啟動器（macOS，AppleScript-ObjC）。

## 檔案
| 檔案 | 說明 |
|---|---|
| `MapleLauncher.applescript` | 主程式。Cocoa 原生視窗（NSWindow + view-based NSTableView），多帳號管理、瀏覽器偵測、自動登入流程。 |
| `clear_login.sh` | 換帳號時清除瀏覽器的 Nexon cookie（支援 Chromium 家族）。會被安裝到 `~/Library/Application Support/MapleLauncher/`。 |
| `genbg.applescript` | 用 Cocoa 繪製 DMG 背景圖（600×400）。 |
| `安裝說明.txt` | 放進 DMG 給使用者看的說明。 |
| `build.sh` | 一鍵重建：編譯 → 簽名 → 打包美化 DMG。 |

## 重建
```bash
cd 原始碼
bash build.sh
```
輸出：上層資料夾的 `MapleStory登入啟動器.dmg`。

## 技術重點
- **語言/UI**：AppleScript-ObjC，直接呼叫 Foundation / AppKit，手刻 Cocoa 視窗。
- **帳密儲存**：macOS 鑰匙圈（service=`MapleWorldsLogin`，account=email，`-A` 免提示讀取）。不外傳。
- **登入方式**：偵測預設瀏覽器 → 找到 Nexon 登入分頁 → 注入 JavaScript（MutationObserver 自動填帳密、按繼續/登入、取消自動登入）→ 成功後關分頁切回遊戲。
- **瀏覽器支援**：Chrome / Edge / Brave / Vivaldi / Opera（共用 Chrome 字典，`using terms from application "Google Chrome"` + `tell application 變數`）、Safari（`do JavaScript ... in tab`）；其他降級成「複製密碼手動貼上」。
- **簽名**：ad-hoc（`codesign --force --deep -s -`），**務必最後一步**，動過 bundle（換圖示等）就要重簽，否則 cdhash 變動使 TCC 授權失效。

## 已知限制
- ad-hoc 簽名：別人下載後第一次要「右鍵 → 打開」。要雙擊直接開需付費 Apple Developer 帳號做正式簽名＋公證（notarize）。
- Safari 換不同帳號時 cookie 可能清不乾淨（binarycookies 無法只刪單一網域），有機率帶到舊帳號；單帳號或 Chromium 不受影響。
- 僅 macOS，不支援 Windows。
