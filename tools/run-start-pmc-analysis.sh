#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
OUT_DIR="$ROOT_DIR/tests/results"
mkdir -p "$OUT_DIR"
ts="$(date +%Y%m%d-%H%M%S)"
out="$OUT_DIR/start-pmc-analysis-$ts.log"

echo "Running start-pmc.ps1 component analysis…" >&2
pwsh -NoProfile -NoLogo -File "$ROOT_DIR/tools/test_start_pmc.ps1" | tee "$out"
echo "\nWrote report: $out" >&2

