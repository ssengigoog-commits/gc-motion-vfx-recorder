# Requested recorder upgrades

Status: **pending implementation**. This file records the user's requests; unchecked items must not be advertised as working.

## Performance first

- [ ] Near-idle workload when recording and previews are off. No continuous whole-world warm index.
- [ ] Lazy, bounded discovery around selected actors/effects; configurable radius, watch count, time budget and memory cap.
- [ ] Attach property listeners only during capture and detach them on stop/shutdown.
- [ ] Separate sampling rates: motion, VFX and UI refresh. No repeated expensive UI updates per simulation step.
- [ ] Preserve effect hierarchy, source-relative transforms, scale/texture/mesh animation and separate overlapping effects.
- [ ] Measure idle/capture/playback frame-time and memory before/after using the same scene. Report results, not an unqualified “lag fixed.”

## Motion, visibility and studs

- [ ] Timestamp invisible/visible changes from observed part Transparency/LocalTransparencyModifier and available character flags. Record changes, not only key presses.
- [ ] Continue root/joint sampling while invisible; invisible does not mean absent.
- [ ] Replay recorded visibility on ghosts and restore only preview-owned changes.
- [ ] Track cumulative 3D path distance, horizontal path distance and displacement in studs.
- [ ] Break distance into action intervals: flashstep/dash, fallback, uppercut and user markers. Use observed flags/track evidence; do not infer server acceptance from input alone.
- [ ] Include hidden-phase movement and each flash's start/end, duration and studs.
- [ ] Label sample gaps, streaming loss, respawns and possible teleports so they do not silently inflate ordinary movement.
- [ ] Compare preview root/joint timing and jumps to raw samples; never invent a fixed jump arc.

## Combined take and actor settings

- [ ] ANIM, VFX and synchronized ANIM+VFX modes with one monotonic timestamp origin and one start/stop operation.
- [ ] Settings switch: record local player animation.
- [ ] Settings switch: record selected NPC animations, default off.
- [ ] Settings switch: record selected other players, default off.
- [ ] Explicit actor picker and maximum actor count; no map-wide automatic actor harvesting.
- [ ] Distinct actor IDs, root/joint frames, track timing and effect ownership. Missing actors do not stop the remaining capture.
- [ ] Preview labels: local player's username, each other player's username, NPC model name. Keep labels readable even when ghost body is hidden.
- [ ] Actors retain their original relative positions; play back together using the session clock.
- [ ] Do not hide/anchor or take control of the user's live character to show previews.

## Validation before calling the update complete

- [ ] All visibility states, including initially invisible characters, quick flashes and repeated flashes.
- [ ] Known-distance paths, reversing direction, fallback travel, hidden travel, jumps and discontinuities.
- [ ] Two actors with different animation rates; NPC stream-out/respawn.
- [ ] Combined animation and multiple simultaneous VFX with distinct pivots.
- [ ] Capture stop/shutdown cleans listeners and does not change gameplay speed/stun.
- [ ] Export/import + preview round trip and old take compatibility.
- [ ] Runtime tests in a controlled authorized Studio place; static compilation alone is insufficient.
