#!/usr/bin/env bash
set -euo pipefail

# Apply the Petdex-owned Native SDK patch to the exact SDK used for a build.
# The operation is idempotent and fails when the pinned source no longer
# matches, so an SDK upgrade cannot silently drop the signing fix.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK="${NATIVE_SDK_PATH:-}"

if [[ -z "$SDK" ]]; then
  echo "patch-native-sdk: NATIVE_SDK_PATH is required" >&2
  exit 1
fi
if ! git -C "$SDK" rev-parse --git-dir >/dev/null 2>&1; then
  echo "patch-native-sdk: SDK checkout not found: $SDK" >&2
  exit 1
fi

apply_idempotent() {
  local name="$1" patch="$2"
  if [[ ! -f "$patch" ]]; then
    echo "patch-native-sdk: patch file not found: $patch" >&2
    exit 1
  fi
  if git -C "$SDK" apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "patch-native-sdk: $name already applied"
    return
  fi
  if ! git -C "$SDK" apply --check "$patch" >/dev/null 2>&1; then
    echo "patch-native-sdk: $name does not match this SDK" >&2
    exit 1
  fi
  git -C "$SDK" apply "$patch"
  echo "patch-native-sdk: applied $name"
}

apply_idempotent "macOS Mach-O headerpad fix" "$ROOT/patches/native-sdk-macos-headerpad.patch"
apply_idempotent "Windows move/resize window services" "$ROOT/patches/native-sdk-win32-move-resize.patch"
