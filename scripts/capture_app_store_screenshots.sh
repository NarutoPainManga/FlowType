#!/bin/zsh
set -euo pipefail

PROJECT="/Users/pain/Documents/flowtype/FlowType/FlowType.xcodeproj"
SCHEME="FlowType"
DERIVED_DATA="/tmp/flowtype-screenshots-derived-data"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/FlowType.app"
OUTPUT_DIR="${1:-/Users/pain/Documents/flowtype/FlowType/marketing/screenshots}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17}"
DEVICE_UDID=""
BUNDLE_ID=""

boot_device() {
  DEVICE_UDID="$(xcrun simctl list devices available | awk -F '[()]' -v name="$DEVICE_NAME" '$1 ~ "^[[:space:]]*" name " $" { print $2; exit }')"
  if [[ -z "$DEVICE_UDID" ]]; then
    echo "Could not find simulator named $DEVICE_NAME"
    exit 1
  fi

  xcrun simctl bootstatus "$DEVICE_UDID" >/dev/null 2>&1 || xcrun simctl boot "$DEVICE_UDID"
  xcrun simctl bootstatus "$DEVICE_UDID" -b
}

build_app() {
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
    -derivedDataPath "$DERIVED_DATA" \
    build

  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")"
  if [[ -z "$BUNDLE_ID" ]]; then
    echo "Could not read bundle identifier from $APP_PATH/Info.plist"
    exit 1
  fi
}

launch_and_capture() {
  local scene="$1"
  local file="$2"

  xcrun simctl terminate "$DEVICE_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl uninstall "$DEVICE_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$DEVICE_UDID" "$APP_PATH"
  xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID" \
    -FlowTypeResetState \
    -FlowTypeUseMockServices \
    -FlowTypeScreenshotScene "$scene"
  sleep 2
  mkdir -p "$OUTPUT_DIR"
  xcrun simctl io "$DEVICE_UDID" screenshot "$OUTPUT_DIR/$file"
}

boot_device
build_app

launch_and_capture onboarding onboarding.png
launch_and_capture home home.png
launch_and_capture review review.png
launch_and_capture help help.png

echo "Saved screenshots to $OUTPUT_DIR"
