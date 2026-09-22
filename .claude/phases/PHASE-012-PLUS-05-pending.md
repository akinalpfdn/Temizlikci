# Phase 012 (PLUS-05) — What is this folder?
Status: PENDING

## Goal
People can learn what an unfamiliar folder is, without risk.

## Tasks
- [ ] Deterministic identification: installed apps by bundle identifier / name, known system folders, the rule catalog
- [ ] Optional on-device explanation via Foundation Models for folders still unknown; check availability (Apple Intelligence) and hide gracefully
- [ ] Inspector section labeled as generated; never changes safety labels or offers actions (DECISIONS 2026-09-22)
- [ ] Follow HIG Generative AI guidance (refresh the HIG notes first)
- [ ] Tests: deterministic identification; model calls behind a protocol with a stub

## Acceptance Criteria
- Known folders are identified without the model
- Generated text is clearly labeled and optional
- Works (minus the explanation) on Macs without Apple Intelligence

## Decisions Made This Phase
