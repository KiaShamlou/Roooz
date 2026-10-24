#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/rooz-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"
swift test --disable-sandbox --scratch-path build/swift --cache-path "${TMPDIR:-/tmp}/rooz-swift-cache" --config-path "${TMPDIR:-/tmp}/rooz-swift-config" --security-path "${TMPDIR:-/tmp}/rooz-swift-security"
