# Phase 012 (PLUS-05) — What is this folder?
Status: DONE

## Goal
People can learn what an unfamiliar folder is, without risk.

## Tasks
- [x] Deterministic identification: installed apps by bundle identifier / name, known system folders, the rule catalog
- [x] Optional on-device explanation via Foundation Models for folders still unknown; check availability (Apple Intelligence) and hide gracefully
- [x] Inspector section labeled as generated; never changes safety labels or offers actions (DECISIONS 2026-09-22)
- [x] Follow HIG Generative AI guidance (refresh the HIG notes first)
- [x] Tests: deterministic identification; model calls behind a protocol with a stub

## Acceptance Criteria
- Known folders are identified without the model
- Generated text is clearly labeled and optional
- Works (minus the explanation) on Macs without Apple Intelligence

## Decisions Made This Phase
- HIG "Generative AI" and "Machine learning" pages fetched 2026-09-22 (`scripts/fetch-hig.sh` now includes them) and followed: on request only, labelled, retryable, never drives an action, works without Apple Intelligence.
- Foundation Models API verified against the SDK interface rather than from memory (`SystemLanguageModel.default.availability`, `LanguageModelSession(instructions:)`, `respond(to:options:)`).
- Prompt carries names and sizes only, with the home folder masked as `~`; file contents are never read.
- Tests: 128 (126 pass, 2 opt-in), including one that checks the prompt keeps the user name out.
- Still to check live with the developer: whether Apple Intelligence is on on this Mac, and the quality of an answer for a genuinely unknown folder.
