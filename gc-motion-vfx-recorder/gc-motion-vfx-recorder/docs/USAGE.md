# Recording and measurements

1. Open the v7 generated file using your existing local script workflow. It shuts down an older running GC recorder through the existing shutdown hook.
2. Open SETTINGS before recording.
3. Keep Record my animation on to capture yourself. Turn NPC/other-player switches on only when needed.
4. Optionally enter exact NPC model names or player usernames, separated by commas. Blank selects the nearest enabled actors within 60 studs. Selection happens at take start; it is capped at four actors.
5. Select Balanced 30/20Hz for lower load or 60/30Hz for denser motion. Higher sampling and extra actors cost more CPU/memory.
6. Press F9 for synchronized animation+VFX, F6 for motion, or F8 for effects. Repeat the same key/button to stop.
7. Choose the matching ANIM, VFX or BOTH library tab. PLAY MOTION / BOTH uses all recorded actors and their visibility. VFX-only preview is also available.
8. COPY RAW exports the complete session. EXPORT STUDIO produces per-actor KeyframeSequences and a timed scene package. Standard Roblox animation assets cannot encode root travel, transparency or particles; use the scene preview for those channels.

## Stud fields

Every motion frame has distance.path3D, pathHorizontal, displacement, displacementHorizontal, step, action, sampleGap and discontinuity.

Each actor has distance totals and distance.segments with label/start/finish/duration/path3D/pathHorizontal. Labels can include fallback, flashstep, uppercut, dash and hidden when observed flags/track evidence exist. An ordinary_motion label does not prove that no combat action occurred.

A large sampled jump is excluded from ordinary path sums and retained in discontinuityStuds. Root displacement still describes the recorded endpoints. A gap over 0.25 seconds is marked; movement between those endpoints cannot be reconstructed exactly.

## Visibility

Effective alpha is 1 - (1 - Transparency) * (1 - LocalTransparencyModifier), excluding the normally invisible HumanoidRootPart. Full-body hidden and partial per-part alpha are recorded. Property observers operate only during a take. Timestamped VISIBILITY events drive ghost playback, including brief events between motion samples.

Username/NPC labels remain visible above the ghost while its body is hidden. Previews do not hide, anchor or control your live character.

## Limits and observations

Default limits: 30 seconds, four actors, 7,200 total motion frames, 8,000 motion events per actor, 96 VFX groups, 192 nodes/group, 12,000 VFX events, 768 discovery watchers, 4,096 initial discovery visits, 256 spatial-query parts and 80-stud VFX radius. Settings allow 40/80/120-stud VFX radius.

Radius is measured around the selected actors. One missing/changed rig is marked ACTOR_LOST; remaining actors continue. New spawns are not automatically substituted into an existing actor track.

Watch/scan/frame/event caps are reported in raw metadata. Existing unseen or non-queryable effects outside the bounded seed sources are not guaranteed. Burst estimates remain estimates; asset access remains subject to Roblox permissions.

Recorder peak tick cost is stored as recorderTickMaxMs; this is recorder callback time, not total frame time or an FPS benchmark.
