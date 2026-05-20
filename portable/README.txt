SVG Viewer · 綠色免安裝版
================================

中文使用說明
--------------------------------
這是 SVG Viewer 的綠色免安裝版（Portable Edition）。

特性：
  ✓ 不需安裝，雙擊 svg-viewer.exe 即可使用
  ✓ 不寫入系統登錄檔（Registry）
  ✓ 不寫入使用者設定檔（%APPDATA%、%LOCALAPPDATA%）
  ✓ 所有資料儲存在本資料夾的 `data/` 子目錄
  ✓ 可放在 USB 隨身碟、網路磁碟，狀態跟著走
  ✓ 移除整個資料夾即可乾淨卸載

主要功能：
  • 資料夾遞迴掃描 SVG 檔案
  • 支援 SMIL、CSS、JavaScript 動畫
  • 平移／縮放（滑鼠滾輪、拖曳）
  • 動畫播放／暫停／重啟
  • 透明背景棋盤格切換
  • SVG 原始碼面板（含語法高亮）

鍵盤捷徑：
  Alt+↑/↓  上一個／下一個檔案
  Ctrl+K   聚焦搜尋
  + / -    縮放
  0        實際尺寸 100%
  f        適應視窗
  r        重置變形
  Space    播放／暫停動畫
  Shift+R  重啟動畫
  b        切換背景
  s        切換源碼面板

切換為一般安裝模式：
  刪除 PORTABLE.txt 後，程式會改用 %LOCALAPPDATA% 儲存資料。


English
--------------------------------
This is the portable edition of SVG Viewer.

Features:
  ✓ No installation needed — just double-click svg-viewer.exe
  ✓ Writes NO entries to the system registry
  ✓ Writes NO files to %APPDATA% or %LOCALAPPDATA%
  ✓ All state lives in `data/` next to the .exe
  ✓ Runs from USB drives, network shares; moves with the folder
  ✓ Delete the folder to remove the app completely

Keyboard shortcuts:
  Alt+Up/Down   Previous / next file
  Ctrl+K        Focus search
  + / -         Zoom in / out
  0             Actual size (100%)
  f             Fit to viewport
  r             Reset transform
  Space         Play / pause animation
  Shift+R       Restart animation
  b             Cycle background
  s             Toggle source panel

To revert to install-mode (data in %LOCALAPPDATA%):
  Simply delete PORTABLE.txt.


Project · 專案資訊
--------------------------------
GitHub: https://github.com/ltangyu/svg-viewer
License: MIT
Built with Tauri v2 + Vue 3 + TypeScript
