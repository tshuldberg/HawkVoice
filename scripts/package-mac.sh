#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "[HawkVoice] macOS packaging must run on macOS." >&2
  exit 1
fi

default_output="${TMPDIR:-/tmp}hawkvoice-release"
output_dir="${HAWKVOICE_RELEASE_OUTPUT:-${MYVOICE_RELEASE_OUTPUT:-$default_output}}"
builder_args=(--mac "--config.directories.output=$output_dir")

codesign_id="${HAWKVOICE_CODESIGN_ID:-${MYVOICE_CODESIGN_ID:-}}"
if [[ -n "$codesign_id" ]]; then
  if ! security find-identity -v -p codesigning | grep -q "$codesign_id"; then
    echo "[HawkVoice] Signing identity hash not found: $codesign_id" >&2
    exit 1
  fi
  export CSC_NAME="$codesign_id"
  echo "[HawkVoice] Using signing identity: $codesign_id"
else
  # Disable auto-signing for team/test builds unless explicitly requested.
  export CSC_IDENTITY_AUTO_DISCOVERY=false
  # Hardened runtime enforces library validation, which rejects ad-hoc Team IDs.
  # For unsigned internal/test builds, disable it to keep Electron loadable.
  builder_args+=(--config.mac.hardenedRuntime=false --config.mac.gatekeeperAssess=false)
  echo "[HawkVoice] Auto-signing disabled (set HAWKVOICE_CODESIGN_ID to sign)."
fi

mkdir -p "$output_dir"

echo "[HawkVoice] Packaging macOS app"
echo "[HawkVoice] Output directory: $output_dir"

electron-builder "${builder_args[@]}"

echo "[HawkVoice] Build complete"
find "$output_dir" -maxdepth 1 -name '*.dmg' -print
