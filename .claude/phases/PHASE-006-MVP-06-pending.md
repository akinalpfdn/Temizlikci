# Phase 006 (MVP-06) — Developer insights
Status: PENDING

## Goal
Developer artifacts are recognized and cleaned with the right method.

## Tasks
- [ ] `CleanupRule` strategies + `RuleEngine` (Xcode, simulators, Gradle, Android AVD/system images, node_modules, Flutter build/.dart_tool, Go build cache, Homebrew, npm)
- [ ] Safety levels: Safe to remove / Remove with tool / Keep — badges in chart, list, inspector
- [ ] Developer view: artifacts by ecosystem with reclaimable totals and "why" text
- [ ] `ToolRunner` + simctl (JSON output): list runtimes, delete runtime, delete unavailable devices; confirmation alerts; progress + output

## Acceptance Criteria
- Each rule tested for matches and non-matches (look-alikes)
- "Keep" items never offer deletion
- Tool failures surface the tool's error

## Decisions Made This Phase
