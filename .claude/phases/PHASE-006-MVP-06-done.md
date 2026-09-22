# Phase 006 (MVP-06) — Developer insights
Status: DONE

## Goal
Developer artifacts are recognized and cleaned with the right method.

## Tasks
- [x] `CleanupRule` strategies + `RuleEngine` (Xcode, simulators, Gradle, Android AVD/system images, node_modules, Flutter build/.dart_tool, Go build cache, Homebrew, npm)
- [x] Safety levels: Safe to remove / Remove with tool / Keep — badges in chart, list, inspector
- [x] Developer view: artifacts by ecosystem with reclaimable totals and "why" text
- [x] `ToolRunner` + simctl (JSON output): list runtimes, delete runtime, delete unavailable devices; confirmation alerts; progress + output

- [x] Highlight Reclaimable restored (toolbar + View menu)
- [x] Live test with the developer: Developer view on real data looked right ("gayet güzel duruyor")

## Acceptance Criteria
- Each rule tested for matches and non-matches (look-alikes)
- "Keep" items never offer deletion
- Tool failures surface the tool's error

## Decisions Made This Phase
- Found on this Mac while checking simctl JSON: 29 unavailable simulator devices (one with 6.3 GB of data) left after runtimes were removed; runtime images live in /System/Library/AssetsV2.
- Tests: 78 (77 pass, 1 opt-in benchmark).
