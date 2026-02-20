#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "[HawkVoice] macOS packaging must run on macOS." >&2
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

default_output="${TMPDIR:-/tmp}hawkvoice-release"
output_dir="${HAWKVOICE_RELEASE_OUTPUT:-${MYVOICE_RELEASE_OUTPUT:-$default_output}}"

mkdir -p "$output_dir"

echo "[HawkVoice] Packaging macOS app"
echo "[HawkVoice] Output directory: $output_dir"

electron-builder --mac --config.directories.output="$output_dir"

echo "[HawkVoice] Build complete"
find "$output_dir" -maxdepth 1 -name '*.dmg' -print
