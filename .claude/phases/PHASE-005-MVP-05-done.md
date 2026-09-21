# Phase 005 (MVP-05) — Actions & access
Status: DONE

## Goal
People can safely reclaim space and grant access when needed.

## Tasks
- [x] `TrashService`: move to Trash, Undo (put back), per-item error reporting
- [x] Update tree after actions without rescanning
- [x] Trash size indicator + "space is freed when Trash is emptied" guidance
- [x] `AccessService`: FDA probe (verify path on macOS 26), contextual onboarding, System Settings deep link, recheck on activation
- [x] Explicit error states

- [x] Live test with the developer: Move to Trash (context menu) on a real item, chart updated, Undo and Put Back worked; FDA deep link not reported → verify in Phase 7

## Acceptance Criteria
- Move to Trash + Undo work and are tested on fixtures
- No alerts for undoable actions; failures reported specifically
- FDA flow verified granted and denied on macOS 26

## Decisions Made This Phase
- Tests never touch the real Trash (StubTrash); 63 tests pass (+1 opt-in benchmark skipped).
- Decisions: see DECISIONS "Move to Trash…" and "Full Disk Access…" (2026-09-22).
- 2026-09-22 — Live test passed for Trash/Undo/Put Back. Developer tried dragging onto the sidebar Trash (not supported) → Lore improvementIdea.
