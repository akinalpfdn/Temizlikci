# Phase 007 (MVP-07) — Polish & release
Status: ACTIVE

## Goal
A signed, notarized build usable daily and shareable.

## Tasks
- [x] Layered app icon (Icon Composer) — developer assembled AppIcon.icon; wired at Temizlikci/Resources/AppIcon.icon (IconImageStack + .icns fallback verified in the build)
- [x] Optional interactive sunburst introduction, reachable from Help (4914fe8)
- [x] Review empty, error, low-space states — Find command, Help menu, free-space badge added (4914fe8)
- [x] Performance pass (engineering part): retained heap −36% (5c96931); startup-disk figure to be measured live. Scan memory (Lore knownIssue 101 — 1.1 GB peak on the startup disk, measured before the /.nofollow fix)
- [x] Accessibility audit: developer checked VoiceOver, Increase Contrast, Reduce Transparency — no problems
- [x] HIG compliance review → claudedocs/hig-review-2026-09.md (fad3b92); 4 unused strings removed + usage test
- [ ] Developer ID signing, notarization, DMG (`mac-release` skill)

- [x] Verify the Full Disk Access settings deep link live — opens the right pane
- [x] Re-check Increase Contrast / Reduce Transparency and VoiceOver (carried over from Phases 2 and 4)

## Acceptance Criteria
- Notarized DMG installs and runs on a clean user account
- Accessibility audit recorded
- HIG compliance review recorded

## Decisions Made This Phase
- 2026-09-22 — Developer chose: icon via Icon Composer layers they assemble; notarized DMG after the final live audit.
- Finding: running `xcodebuild test` while the Debug app is open made test-host launch take ~15 min (same bundle ID). Close the app before running tests.
- 2026-09-22 — With the app closed the full suite ran in 11.6 s (80 tests, 79 pass, 1 opt-in), confirming the slow runs came from the open Debug app.
- 2026-09-22 19:19–19:21 — Final in-app startup-disk scan (Debug): peak RSS 383 MB (was 1,112 → 1,017 MB). Lore knownIssue 101 closed. Developer confirmed Developer-view Move to Trash now drops the row immediately.
- 2026-09-22 — Developer: list still scrolled sideways at the default size (fine when maximized) → column widths fixed (ec00a79). FDA deep link correct; accessibility checks fine. Asked to wait before notarization.
