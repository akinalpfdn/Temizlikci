# Phase 013 (PLUS-06) — Release
Status: PENDING

## Goal
A signed, notarized DMG of the finished app that installs cleanly.

## Tasks
- [ ] Re-run the HIG review for everything added in Phases 008–012 (refresh the HIG notes first)
- [ ] Release build: version and build number, Hardened Runtime, Developer ID Application (team WQ54PPL5VQ)
- [ ] Notarize with the developer's notarytool keychain profile; staple
- [ ] Build the DMG (`mac-release` skill); verify with spctl on a clean user account
- [ ] Tag the release

## Acceptance Criteria
- Notarized DMG installs and runs on a clean user account
- Gatekeeper accepts it (spctl) and the ticket is stapled
- Release notes list what's in the app

## Decisions Made This Phase
