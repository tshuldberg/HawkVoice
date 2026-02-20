#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "[HawkVoice] macOS release packaging must run on macOS." >&2
  exit 1
fi

codesign_id="${HAWKVOICE_CODESIGN_ID:-${MYVOICE_CODESIGN_ID:-}}"
if [[ -n "$codesign_id" ]]; then
  if ! security find-identity -v -p codesigning | grep -q "$codesign_id"; then
    echo "[HawkVoice] Signing identity hash not found: $codesign_id" >&2
    exit 1
  fi
  export CSC_NAME="$codesign_id"
  echo "[HawkVoice] Using signing identity: $codesign_id"
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  echo "[HawkVoice] Missing Developer ID Application certificate in keychain." >&2
  echo "[HawkVoice] Install your Developer ID Application cert and retry." >&2
  exit 1
fi

has_api_key_notarization=false
if [[ -n "${APPLE_API_KEY:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER:-}" ]]; then
  has_api_key_notarization=true
fi

has_apple_id_notarization=false
if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  has_apple_id_notarization=true
fi

if [[ "$has_api_key_notarization" != true && "$has_apple_id_notarization" != true ]]; then
  echo "[HawkVoice] Missing notarization credentials." >&2
  echo "[HawkVoice] Provide either:" >&2
  echo "  - APPLE_API_KEY + APPLE_API_KEY_ID + APPLE_API_ISSUER" >&2
  echo "  - APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD + APPLE_TEAM_ID" >&2
  exit 1
fi

default_output="${TMPDIR:-/tmp}hawkvoice-release-signed"
output_dir="${HAWKVOICE_RELEASE_OUTPUT:-${MYVOICE_RELEASE_OUTPUT:-$default_output}}"

mkdir -p "$output_dir"

echo "[HawkVoice] Building release DMG (signed + notarized)"
echo "[HawkVoice] Output directory: $output_dir"

electron-builder --mac --config.directories.output="$output_dir"

app_path="$(find "$output_dir" -maxdepth 2 -type d \( -name 'HawkVoice.app' -o -name 'MyVoice.app' \) | head -n 1)"
if [[ -z "$app_path" ]]; then
  echo "[HawkVoice] Could not locate built app bundle for stapling/verification." >&2
  exit 1
fi

echo "[HawkVoice] Stapling notarization ticket"
xcrun stapler staple "$app_path"

echo "[HawkVoice] Verifying Gatekeeper acceptance"
spctl -a -vv "$app_path"

echo "[HawkVoice] Release build complete"
find "$output_dir" -maxdepth 1 -name '*.dmg' -print
