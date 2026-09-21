# Phase 005 (MVP-05) — Actions & access
Status: ACTIVE

## Goal
People can safely reclaim space and grant access when needed.

## Tasks
- [ ] `TrashService`: move to Trash, Undo (put back), per-item error reporting
- [ ] Update tree after actions without rescanning
- [ ] Trash size indicator + "space is freed when Trash is emptied" guidance
- [ ] `AccessService`: FDA probe (verify path on macOS 26), contextual onboarding, System Settings deep link, recheck on activation
- [ ] Explicit error states

## Acceptance Criteria
- Move to Trash + Undo work and are tested on fixtures
- No alerts for undoable actions; failures reported specifically
- FDA flow verified granted and denied on macOS 26

## Decisions Made This Phase
