#!/usr/bin/env bash
# 在 macOS 上把工程打成 IPA。
#
# 默认：生成「未签名」包（needs-signing），给朋友用 AltStore/Sideloadly/Esign 自签，
#       对应原版那种 CarPlayWallpaperStudio-xxx-needs-signing.ipa 的分发方式。
# 带 Team ID：用你的苹果开发者证书签名（需要已装好证书/描述文件）。
#
# 用法：
#   ./build.sh                 # 未签名 IPA
#   ./build.sh TEAMID12345     # 签名 IPA
set -euo pipefail
cd "$(dirname "$0")"

SCHEME=CarPlayWallpaperStudioShell
CONFIG=Release
TEAM_ID="${1:-}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "[!] 先装 XcodeGen：brew install xcodegen" >&2
  exit 1
fi

echo "[1/2] 生成 Xcode 工程…"
xcodegen generate

if [ -n "$TEAM_ID" ]; then
  echo "[2/2] 用团队 $TEAM_ID 编译并导出（签名版）…"
  xcodebuild -project "$SCHEME.xcodeproj" -scheme "$SCHEME" \
    -configuration "$CONFIG" -sdk iphoneos \
    -archivePath "build/$SCHEME.xcarchive" \
    DEVELOPMENT_TEAM="$TEAM_ID" archive
  xcodebuild -exportArchive -archivePath "build/$SCHEME.xcarchive" \
    -exportOptionsPlist ExportOptions.plist -exportPath build
  echo "→ 完成：build/$SCHEME.ipa"
else
  echo "[2/2] 编译未签名包（needs-signing）…"
  xcodebuild -project "$SCHEME.xcodeproj" -scheme "$SCHEME" \
    -configuration "$CONFIG" -sdk iphoneos \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY="" build

  APP="build/Build/Products/$CONFIG-iphoneos/$SCHEME.app"
  rm -rf Payload "$SCHEME.ipa"
  mkdir -p Payload
  cp -R "$APP" Payload/
  zip -qr "$SCHEME.ipa" Payload
  rm -rf Payload
  echo "→ 完成：$SCHEME.ipa（未签名，朋友自签后即可安装）"
fi
