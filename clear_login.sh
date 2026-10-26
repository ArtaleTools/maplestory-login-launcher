#!/bin/bash
# 清除指定瀏覽器的 Nexon cookie。用法: clear_login.sh "<瀏覽器 AppleScript 名稱>"
# 遊戲權杖已由啟動器先清；這裡只處理瀏覽器端。支援 Chromium 家族。
APPNAME="${1:-Google Chrome}"

# 關閉該瀏覽器（輪詢不死等）
osascript -e "tell application \"$APPNAME\" to quit" 2>/dev/null
for i in $(seq 1 15); do pgrep -x "$APPNAME" >/dev/null || break; sleep 0.2; done
pkill -9 "$APPNAME" 2>/dev/null
sleep 0.3

# 依瀏覽器決定 cookie 根目錄（Chromium 家族）
BASES=()
case "$APPNAME" in
  "Google Chrome")        BASES=("$HOME/Library/Application Support/Google/Chrome") ;;
  "Google Chrome Beta")   BASES=("$HOME/Library/Application Support/Google/Chrome Beta") ;;
  "Microsoft Edge")       BASES=("$HOME/Library/Application Support/Microsoft Edge") ;;
  "Brave Browser")        BASES=("$HOME/Library/Application Support/BraveSoftware/Brave-Browser") ;;
  "Vivaldi")              BASES=("$HOME/Library/Application Support/Vivaldi") ;;
  "Opera")                BASES=("$HOME/Library/Application Support/com.operasoftware.Opera") ;;
  *)                      BASES=() ;;
esac

SQL="DELETE FROM cookies WHERE host_key LIKE '%nexon%';"
for base in "${BASES[@]}"; do
  [ -d "$base" ] || continue
  # 涵蓋各 Profile 的 Cookies 與新版 Network/Cookies
  find "$base" -maxdepth 3 -name "Cookies" -type f 2>/dev/null | while read -r f; do
    sqlite3 "$f" "$SQL" 2>/dev/null
  done
done
echo DONE
