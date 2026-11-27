# Validation and live acceptance checklist

Automated `node scripts/check.mjs` and `node --test tests/*.test.mjs` validate source composition, file hashes, original v6.8 preservation and structural presence of GAME capture paths. With LUAU_BIN set, the suite also executes the loader, actor settings and UI construction in the standalone Luau interpreter using explicit mocks. Native compilation is checked separately. None of these is a live Roblox Player integration test.

Live acceptance on your own/authorized Roblox client:

- [ ] Run v7 and confirm F6 recording, saved history, ghost preview and Studio motion export still work.
- [ ] Confirm F8 captures grouped VFX and its preview/Studio export still work.
- [ ] Select two client-visible actors including an NPC, start F3, move and attack. Verify a single saved `GAME` JSON contains nonempty `frames`, `inspector.frames`, `game.frames`, `events` and, **when VFX actually appears**, `vfx`.
- [ ] Verify all streams use the same `t` origin and input timing aligns with animation + FX starts.
- [ ] Verify new sound play/stop events and readable state/attribute changes if the game exposes them.
- [ ] Verify selected actor joint snapshots and camera/HUD names/visibility. No UI text should be included.
- [ ] Confirm a selected GAME take can separately preview motion, preview VFX, export motion Studio and export VFX Studio.
- [ ] Confirm 120-second cap and that event/frame limits are marked as truncated rather than silently claimed complete.
- [ ] Stop and re-run F3; verify temporary listeners disconnect and playback doesn't mutate live player physics.
- [ ] Reopen legacy v6.8/v6.9 takes and verify old history is retained.
- [ ] Profile FPS and memory before/during capture in a controlled test. 120-second combined takes may be substantial.

Report any runtime errors with the relevant console message and time in take; do not label v7 **live verified** until these checks pass.

## 7.1.5 UI and subjects acceptance
- [ ] Confirm Capture, Library and Settings have the new reference-matched theme.
- [ ] Toggle NPCs OFF and other players ON; verify only self/player actor tracks in the next Game take.
- [ ] Reverse the toggles and verify self/NPC tracks.
- [ ] With both OFF, verify only self actor tracks.
- [ ] Test a manual selection and the four-actor bound.
- [ ] Re-run the recorder and verify persisted filters.
- [ ] Confirm active recording rejects filter changes.
- [ ] Resize viewport, open/close actor picker, switch pages and press F7.

