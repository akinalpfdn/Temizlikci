#!/usr/bin/env bash
# Refreshes the Apple Human Interface Guidelines pages this project depends on.
# HIG pages are client-rendered; Apple's DocC JSON endpoint gives the raw content.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/claudedocs/hig"
BASE="https://developer.apple.com/tutorials/data/design/human-interface-guidelines"
PAGES=(design-principles designing-for-macos materials color dark-mode typography layout
  sidebars split-views toolbars the-menu-bar keyboards windows search-fields lists-and-tables
  outline-views disclosure-controls charts charting-data accessibility voiceover motion
  alerts buttons progress-indicators privacy file-management onboarding writing
  sf-symbols icons app-icons generative-ai machine-learning settings drag-and-drop panels)
mkdir -p "$OUT"
for p in "${PAGES[@]}"; do
  if curl -fsS "$BASE/$p.json" -o "$OUT/.$p.json"; then
    python3 "$ROOT/scripts/hig_extract.py" "$OUT/.$p.json" > "$OUT/$p.md"
    rm "$OUT/.$p.json"
    echo "ok   $p"
  else
    echo "FAIL $p" >&2
  fi
done
date -u +"Fetched %Y-%m-%dT%H:%MZ" > "$OUT/FETCHED_AT"
