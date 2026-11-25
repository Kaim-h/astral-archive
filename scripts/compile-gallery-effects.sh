#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v qsb >/dev/null 2>&1; then
  echo "Qt Shader Tools (qsb) is required for the depth-correct dome and pixel-colony sky." >&2
  exit 1
fi
for NAME in gallery-dome gallery-colonies; do
  SOURCE="$ROOT/quickshell/shaders/$NAME.frag"
  DEST="$SOURCE.qsb"
  [ -s "$SOURCE" ] || { echo "Missing shader source: $SOURCE" >&2; exit 1; }
  qsb "$SOURCE" -o "$DEST"
  [ -s "$DEST" ] || { echo "Empty shader output: $DEST" >&2; exit 1; }
  echo "Compiled: $DEST"
done
