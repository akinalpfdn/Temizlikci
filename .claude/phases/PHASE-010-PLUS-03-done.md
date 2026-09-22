# Phase 010 (PLUS-03) — Other Used Space breakdown
Status: DONE

## Goal
The unattributed segment explains where its space is.

## Tasks
- [x] Research and verify on this Mac: purgeable space (important-usage vs available capacity), local Time Machine snapshots (tmutil, read-only), Trash size, system volume
- [x] Split Other Used Space into labeled parts; the remainder stays honest ("not attributed")
- [x] Inspector explanation per part with a next step (e.g. snapshots: how macOS removes them)
- [x] Tests with stubbed system readings

## Acceptance Criteria
- Parts add up to the unattributed total
- Nothing here requires new permission prompts
- Every figure states its source

## Decisions Made This Phase
- Verified on this Mac (2026-09-22): `diskutil apfs list -plist` and `getmntinfo` need no privileges and no permission prompt; `tmutil listlocalsnapshots /` reported no snapshots, and snapshot space is already counted as purgeable.
- Measured here: VM 18.25 GB, Preboot 9.03 GB, Recovery 1.3 GB, and two simulator runtime containers (iOS 17.57 GB, watchOS 8.81 GB) mounted inside the disk — the scan steps over them, which is why the segment looked unexplained.
- Parts that exceed the estimate raise the total rather than being scaled down (DECISIONS 2026-09-22).
- Tests: 104 (103 pass, 1 opt-in), including one that reads this Mac's real layout.
- Still to check live with the developer: the breakdown in the inspector after a startup-disk scan.
