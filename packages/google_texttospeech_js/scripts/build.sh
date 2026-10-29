#!/usr/bin/env bash
# Compiles the Dart interop entry point into JavaScript using dart2js.
#
# Output: build/dart/google_texttospeech_js.js (installs globalThis.GoogleTtsJs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PKG_DIR}"

echo "==> Fetching Dart dependencies"
dart pub get

mkdir -p build/dart

echo "==> Compiling Dart -> JavaScript (dart2js -O4)"
dart compile js \
  -O4 \
  -o build/dart/google_texttospeech_js.js \
  lib/google_texttospeech_js.dart

# Remove the sibling .deps file that dart2js emits (not needed in dist).
rm -f build/dart/google_texttospeech_js.js.deps

# Copy to dist/ so the tsup-external dynamic import resolves at runtime.
mkdir -p dist
cp build/dart/google_texttospeech_js.js dist/google_texttospeech_js.runtime.js

echo "==> Dart runtime built: $(du -h build/dart/google_texttospeech_js.js | cut -f1)"
