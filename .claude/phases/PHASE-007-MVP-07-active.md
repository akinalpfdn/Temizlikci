# Phase 007 (MVP-07) — Polish & release
Status: ACTIVE

## Goal
A signed, notarized build usable daily and shareable.

## Tasks
- [ ] Layered app icon (Icon Composer) — layers + preview ready in design/app-icon (fbcb472); developer assembles AppIcon.icon, then wire it
- [x] Optional interactive sunburst introduction, reachable from Help (4914fe8)
- [x] Review empty, error, low-space states — Find command, Help menu, free-space badge added (4914fe8)
- [x] Performance pass (engineering part): retained heap −36% (5c96931); startup-disk figure to be measured live. Scan memory (Lore knownIssue 101 — 1.1 GB peak on the startup disk, measured before the /.nofollow fix)
- [ ] Accessibility audit: VoiceOver, Full Keyboard Access, contrast, motion, transparency
- [x] HIG compliance review → claudedocs/hig-review-2026-09.md (fad3b92); 4 unused strings removed + usage test
- [ ] Developer ID signing, notarization, DMG (`mac-release` skill)

- [ ] Verify the Full Disk Access settings deep link live (carried over from Phase 5)
- [ ] Re-check Increase Contrast / Reduce Transparency and VoiceOver/Audio Graphs (carried over from Phases 2 and 4)

## Acceptance Criteria
- Notarized DMG installs and runs on a clean user account
- Accessibility audit recorded
- HIG compliance review recorded

## Decisions Made This Phase
- 2026-09-22 — Developer chose: icon via Icon Composer layers they assemble; notarized DMG after the final live audit.
- Finding: running `xcodebuild test` while the Debug app is open made test-host launch take ~15 min (same bundle ID). Close the app before running tests.
