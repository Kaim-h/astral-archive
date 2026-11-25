#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/quickshell/shaders/gallery-colonies.frag"
DEST="$ROOT/quickshell/shaders/gallery-colonies.frag.qsb"
if ! command -v qsb >/dev/null 2>&1; then
  echo 'Qt Shader Tools (qsb) is missing. Gallery will use its non-pixel fallback.' >&2
  exit 1
fi
qsb "$SOURCE" -o "$DEST"
[ -s "$DEST" ] || { echo 'Shader compilation produced no output' >&2; exit 1; }
echo "Compiled $DEST"
