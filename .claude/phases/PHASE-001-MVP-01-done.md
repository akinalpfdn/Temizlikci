# Phase 001 (MVP-01) — Design direction & mockups
Status: DONE

## Goal
An approved visual design exists before any UI code is written.

## Tasks
- [x] Refresh HIG notes if stale (`scripts/fetch-hig.sh`) and re-read `claudedocs/hig-research-2026-09.md`
- [x] Write the one-sentence visual direction
- [x] Define category palette (developer artifacts, media, apps, system, other, needs access) with light/dark/high-contrast variants; check contrast
- [x] Design canvas (Artifact): main window light + dark — sidebar, sunburst + list, inspector
- [x] Design canvas: states — first launch/empty, scanning (progressive), Full Disk Access needed, Developer insights view, simctl confirmation alert
- [x] App icon concept (layered, Liquid Glass–ready)
- [x] Record design decisions in DECISIONS.md (palette; layout/color/vocabulary decisions await approval)
- [x] Developer approval of the proposal (2026-09-22: "tasarımı beğendim devam edebiliriz")

## Acceptance Criteria
- Design follows every item in DEVPLAN "Design Direction (HIG-driven)"
- Palette passes contrast checks in light, dark, and Increase Contrast
- Developer explicitly approves the design

## Decisions Made This Phase
- 2026-09-22 — Proposal published: https://claude.ai/artifact/HjFcHStMX4Lnhigg6v4vbY (source `claudedocs/design/mockups.html`). The `design` canvas skill is user-invoked only, so the proposal is an interactive HTML prototype instead.
- Visual direction (proposed): "A calm, instrument-grade Mac utility — native macOS 26 chrome, a quiet neutral canvas, and the sunburst as the only source of color on screen."
- Proposed, awaiting approval: color by top-level folder (slots in size order, depth = lighter tint, 9th+ → "Smaller items"); "Highlight Reclaimable" toolbar toggle (safe = green, tool = amber, rest gray, always with symbol + label); vocabulary "Safe to Remove / Remove with Tool / Keep"; click = select, double-click/Return = open, center/Escape = up; sidebar = Locations + Insights.
- System colors measured on this Mac (macOS 26.6.2, sRGB): blue #0088ff/#0091ff, orange #ff8d28/#ff9230, green #34c759/#30d158, yellow #ffcc00/#ffd600 … surfaces #ffffff / #1e1e1e. High-contrast variants could not be read via NSAppearance — verify in-app.
- Palette validation (dataviz validator, adjacent pairs): light on #ffffff — all pass, contrast WARN for 3 slots (relief: list + labels); dark on #1e1e1e — all pass. System colors as chart palette — FAIL (light lightness band; dark CVD ΔE 4.9).
- 2026-09-22 — Design approved as proposed. Lore: TEMIZLIK-0001.
