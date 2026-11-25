# v6.9 validation — 2026-11-25

## Verified here

- `npm run build`: PASS, generated `dist/GC_MotionVFX_Baker_v6_9.luau`.
- `npm run check`: PASS (manifest, generated release and SHA256).
- `npm test`: PASS (4 Node build/static regression tests).
- Archived v6.8 source SHA256 is unchanged and equals `baseline.json`.
- Added feature source is bundled in manifest and v6.9 release.

## NOT verified here

- No Roblox Player/client test, no installed executor compatibility test, no game environment attached.
- No Luau native parser/compiler is installed in this build environment; the **new v6.9 release is not compiler-verified**. Baseline v6.8 was reportedly compiler-checked in its own original release environment.
- F6/F8 import/playback regression in Studio and v6.9 F9 Inspector NPC tracking need a live test.
- FPS, memory and file storage across 120 seconds were **not** measured. The original VFX world-indexing code is still present.

## Suggested manual testing before treating it as final

1. In an authorized Roblox session, launch the v6.9 script and confirm the UI loads without syntax/runtime errors. If it fails, collect the exact line number and full error.
2. Record F6 for 3–5s, save, preview ghost, export raw and Studio importer. Confirm old v6.8 ANIM takes still load.
3. Record F8 for 3–5s around visible effects, preview ahead, split VFX and export. Confirm old VFX takes still load.
4. Open INSPECT tab, CHOOSE ACTORS, select a nearby NPC and self, then record F9 for 10s. Verify actor list, motion/joints, animation IDs and event ordering in the saved raw JSON.
5. Try movement, block/stun and a newly spawned VFX/audio effect, check that observed flags are labeled observational rather than server-authoritative.
6. Test a 120s run at 30 FPS, then at 60 FPS if performance permits. Check frame count, JSON output size, dropped/truncated flags, and memory/FPS.
7. Delete only a test take and verify its history is updated. Backup important recordings first.

Release is **statically verified, NOT live-play-tested**.
