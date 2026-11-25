#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=quickshell/shaders/vista-transition.frag
DEST=quickshell/shaders/vista-transition.frag.qsb
if ! command -v qsb >/dev/null 2>&1; then
    echo 'Qt Shader Baker (qsb) is required on Fedora; install the Qt 6 shader-tools package providing qsb.' >&2
    exit 1
fi
qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o "$DEST" "$SRC"
echo "Compiled $DEST"
echo 'Keep the .qsb file with the Quickshell config on the laptop; verify its compatibility with the installed Qt 6.'
