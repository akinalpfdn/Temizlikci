---
{
  "codeAnchors" : [

  ],
  "createdAt" : "2026-09-21T21:25:23Z",
  "createdBy" : "claude",
  "formatVersion" : 1,
  "id" : "TEMIZLIK-0003",
  "plan" : "- [x] Verify firmlink/mount behavior on this Mac: scanning \"/\" and skipping non-root `isVolume`/`isMountTrigger` directories counts nothing twice (Data, Preboot, simulator images are volume roots; /Users etc. are plain dirs; /Volumes/Macintosh HD is a symlink)\n- [ ] Domain: FileNode (directory/file/smallerFiles/inaccessible), ScanConfiguration, ScanProgress, ScanResult, ScanEvent, ScanError (LocalizedError via L10n)\n- [ ] DiskScanner: AsyncThrowingStream, parallel top levels + sync recursion below, allocated sizes, hard-link dedupe (linkCount>1 → fileIdentifier), no symlink following, mount skip, inaccessible recorded, threshold aggregation, throttled progress with completed top-level nodes, cancellation\n- [ ] VolumeInfoService: usage (total/available/important), used − scanned = \"Other\"\n- [ ] Fixture tests: nested, hard links, symlink loop, unreadable folder, aggregation, progress, cancellation, root errors\n- [ ] Benchmark vs `du -skx` (env-gated test): totals within 1%, time recorded; peak RSS (ru_maxrss) for Home scan recorded\n- [ ] DECISIONS + phase file + commit",
  "priority" : "high",
  "relatedWorkItemIDs" : [

  ],
  "sprintID" : "TEMIZLIK-SPRINT-1",
  "status" : "inProgress",
  "title" : "Phase 003 (MVP-03): Scan engine",
  "type" : "task",
  "updatedAt" : "2026-09-21T21:39:08Z"
}
---

Mirror of `.claude/phases/PHASE-003-MVP-03-*.md`. DiskScanner (allocated sizes, hard-link dedupe, same volume, no symlinks, skip mounted images, firmlink-aware), memory model, VolumeInfoService, progress stream, cancellation, fixture tests, benchmark vs `du -skx`.