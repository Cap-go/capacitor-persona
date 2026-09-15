#!/usr/bin/env bash
set -euo pipefail

platform="${1:-}"
case "$platform" in
  android | ios | web) ;;
  *)
    echo "Usage: $0 <android|ios|web>"
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_root="${RUNNER_TEMP:-$(mktemp -d)}"
pack_dir="$tmp_root/plugin-package"
test_app="$tmp_root/plugin-example-app"

cd "$repo_root"

bun run build

rm -rf "$pack_dir" "$test_app"
mkdir -p "$pack_dir" "$test_app"
bun pm pack --destination "$pack_dir" --quiet

shopt -s nullglob
packed_packages=("$pack_dir"/*.tgz)
shopt -u nullglob
if [ "${#packed_packages[@]}" -ne 1 ]; then
  echo "Expected exactly one package tarball, found ${#packed_packages[@]}"
  exit 1
fi

plugin_name="$(bun -e 'console.log(require("./package.json").name)')"
cp -R example-app/. "$test_app/"
cd "$test_app"
bun remove "$plugin_name"
bun add "${packed_packages[0]}"
bun run build

patch_android_intune_gradle_includes() {
  local cap_settings="android/capacitor.settings.gradle"
  if [ ! -f "$cap_settings" ]; then
    return 0
  fi
  if grep -q "intune-mam-sdk" "$cap_settings"; then
    return 0
  fi
  local plugin_android_dir
  plugin_android_dir="$(
    node -e "
      const fs = require('node:fs');
      const text = fs.readFileSync('${cap_settings}', 'utf8');
      const match = text.match(/project\\(':capgo-capacitor-intune'\\)\\.projectDir = new File\\('([^']+)'\\)/);
      if (!match) process.exit(1);
      process.stdout.write(match[1]);
    "
  )"
  cat >>"$cap_settings" <<EOF

include ':intune-mam-sdk'
project(':intune-mam-sdk').projectDir = new File('${plugin_android_dir}/intune-mam-sdk')
include ':intune-downlevel-stubs'
project(':intune-downlevel-stubs').projectDir = new File('${plugin_android_dir}/intune-downlevel-stubs')
EOF
}

patch_ios_deployment_target() {
  local ios_min_version
  ios_min_version="$(
    node -e "
      const fs = require('node:fs');
      const path = require('node:path');
      const podspec = fs.readFileSync(path.join('${repo_root}', 'CapgoCapacitorIntune.podspec'), 'utf8');
      const match = podspec.match(/deployment_target = '([0-9.]+)'/);
      process.stdout.write(match?.[1] ?? '15.0');
    "
  )"
  local pbxproj="ios/App/App.xcodeproj/project.pbxproj"
  if [ ! -f "$pbxproj" ]; then
    return 0
  fi
  sed -i.bak "s/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = ${ios_min_version};/g" "$pbxproj"
  rm -f "${pbxproj}.bak"
}

case "$platform" in
  android)
    if [ ! -d android ]; then
      bunx cap add android
    fi
    bunx cap sync android
    patch_android_intune_gradle_includes
    cd android
    ./gradlew build test
    ;;
  ios)
    if [ ! -d ios ]; then
      bunx cap add ios
    fi
    patch_ios_deployment_target
    bunx cap sync ios
    rm -rf "$HOME/Library/Caches/org.swift.swiftpm/artifacts"/https___github_com_ionic_team_capacitor_swift_pm_releases_download_*
    xcodebuild \
      -project ios/App/App.xcodeproj \
      -scheme App \
      -destination generic/platform=iOS \
      -clonedSourcePackagesDirPath "$tmp_root/plugin-example-swiftpm" \
      -derivedDataPath "$tmp_root/plugin-example-derived-data" \
      CODE_SIGNING_ALLOWED=NO
    ;;
  web)
    ;;
esac
