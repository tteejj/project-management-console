#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
OUT_DIR="$ROOT_DIR/tests/results"
mkdir -p "$OUT_DIR"
ts="$(date +%Y%m%d-%H%M%S)"
out="$OUT_DIR/pmc-full-analysis-$ts.log"

echo "Running full PMC component analysis…" >&2
pwsh -NoProfile -NoLogo -File "$ROOT_DIR/tools/test_pmc_full.ps1" | tee "$out"
echo "\nWrote report: $out" >&2

