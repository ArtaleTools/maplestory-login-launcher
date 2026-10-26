#!/bin/bash
# 一鍵重建：編譯 app → 設定 → 簽名 → 產生美化 DMG
# 用法：在「原始碼」資料夾內執行  bash build.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"

APPNAME="MapleStory 登入啟動器"
BUNDLE_ID="com.maple.loginlauncher"
VERSION="1.0"
GAME="/Library/Application Support/Nexon/MapleStory Worlds/MapleStory Worlds.app"
ICON_SRC="$GAME/Contents/Resources/PlayerIcon.icns"

BUILD="$HERE/build"
APP="$BUILD/$APPNAME.app"
SUPPORT="$HOME/Library/Application Support/MapleLauncher"

rm -rf "$BUILD"; mkdir -p "$BUILD"

echo "[1/5] 編譯 app"
osacompile -o "$APP" "$HERE/MapleLauncher.applescript"
PL="$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$PL" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PL"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PL" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PL"
[ -f "$ICON_SRC" ] && cp "$ICON_SRC" "$APP/Contents/Resources/applet.icns"
# 首次設定教學圖打包進 Resources
for g in guide_chromium.png guide_safari.png; do
  [ -f "$HERE/$g" ] && cp "$HERE/$g" "$APP/Contents/Resources/$g"
done

echo "[2/5] 簽名 (ad-hoc，必須放最後)"
codesign --force --deep -s - "$APP"

echo "[3/5] 安裝輔助腳本到 Application Support"
mkdir -p "$SUPPORT"
cp "$HERE/clear_login.sh" "$SUPPORT/clear_login.sh"
chmod +x "$SUPPORT/clear_login.sh"

echo "[4/5] 產生背景圖"
# genbg 輸出到當前資料夾的 bg.png
( cd "$HERE" && osascript genbg.applescript )
BG="$HERE/bg.png"

echo "[5/5] 打包美化 DMG"
VOL="$APPNAME"
RW="$BUILD/rw.dmg"
OUT="$HERE/../MapleStory登入啟動器.dmg"
hdiutil detach "/Volumes/$VOL" >/dev/null 2>&1 || true
hdiutil create -size 25m -fs "HFS+" -volname "$VOL" -o "$RW" >/dev/null
MP="/Volumes/$VOL"
hdiutil attach "$RW" -nobrowse >/dev/null; sleep 1
cp -R "$APP" "$MP/"; xattr -cr "$MP/$APPNAME.app"
cp "$HERE/安裝說明.txt" "$MP/安裝說明.txt"
mkdir -p "$MP/.background"; cp "$BG" "$MP/.background/bg.png"
ln -s /Applications "$MP/Applications"
osascript <<EOF
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 800, 520}
    set vo to the icon view options of container window
    set arrangement of vo to not arranged
    set icon size of vo to 110
    set text size of vo to 13
    set background picture of vo to file ".background:bg.png"
    set position of item "$APPNAME.app" of container window to {150, 170}
    set position of item "Applications" of container window to {450, 170}
    set position of item "安裝說明.txt" of container window to {300, 320}
    update without registering applications
    delay 1.5
    close
  end tell
end tell
EOF
sync
chflags hidden "$MP/.background" 2>/dev/null || true
hdiutil detach "$MP" >/dev/null 2>&1 || true; sleep 1
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$OUT" >/dev/null
rm -rf "$BUILD"
echo "完成 → $OUT"
