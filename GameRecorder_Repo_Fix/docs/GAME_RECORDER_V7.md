# F3 GAME recorder (v7.1.3)

F3 replaces the *recording* entry point of v6.9 Inspector. Old `INSPECT` takes remain searchable under the GAME library tab. It is **not** a new injector, a source extractor, an MCP agent or a remote process controller. The user operates their already-existing authorized client environment.

## Recorded streams (same monotonic `t` clock)

- `frames`: the original ANIM samples for the **local player**, including evaluated Motor6D/AnimationConstraint poses, part transforms, velocity, root, camera, Humanoid state and animation track times, capped at 30Hz in F3 to leave resources for other streams.
- `vfx`: the original grouped VFX codec's spawn/update/remove events for effects discovered within **110 studs** of the local player, sampled at up to 15Hz with a limit of 6,000 VFX events. Includes nodes, meshes, emitter properties, hierarchies and transform changes where readable; `Emit(n)` calls are not captured.
- `inspector.frames`: 10Hz position/velocity, evaluated joints, animation tracks and readable status for up to **4 selected** player/NPC actors, within 90 studs at selection. Maximum 1,200 samples.
- `game.frames`: 5Hz camera transform/field of view, local character root/health, Lighting/Gravity, per-actor readable stun/status flags, and **ScreenGui names/enabled flags only** (not chat content or arbitrary UI text). Maximum 620 snapshots.
- `game.highlights`: timestamped Highlight **initial, added, changed, removed** events, including `Enabled`, `FillColor`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `DepthMode`, and effective `Adornee`/target path. It detects existing highlights on selected actor models, PlayerGui and nearby world parts, plus subsequent observed additions, removals and property changes. Capped at 160 observed Highlight identities and 2,400 highlight events. Not visually replayed by the existing grouped VFX codec; available in JSON and event timelines.
- `events`: key down/up timing, animation/state changes, replicated ValueBase/attribute changes for selected actors, client sound play/stop/end, nearby effect appearance/disappearance and relevant Workspace/ReplicatedStorage instance metadata. Up to **12,000 events**.
- `tracks`, `channels`, `metrics`: the legacy motion/animation metadata. `stateWindows` and `inputObservations` remain available.

Other limits: no more than 160 Highlight listeners and 220 other temporary status/sound listeners, 140 actor objects watched initially, 48 global SoundService sounds and 32 ScreenGuis included per snapshot. Recording can still be truncated if a scene exceeds its budget. Inspect the `truncated`/`dropped` fields, `game.truncatedHighlights`, `game.droppedHighlights`, `game.droppedHighlightEvents`, and `truncatedVFX` before drawing conclusions.

## Workflow

1. Select **GAME** and click **CHOOSE ACTORS**. Your character is always included. If no other actor is manually selected, the nearest enabled actor types fill the remaining slots, up to four actors total.
2. Press **F3**. The combined GAME take starts; F6/F8 remain independent standalone recording modes.
3. Play the game for up to **120 seconds**. Do not expect the recorder to infer whether a server accepted an attack solely from a key press.
4. Press **F3** again, or let the two-minute cap stop it.
5. In the GAME library, select the saved take. The timeline interleaves event and grouped VFX timestamps. Search or delete saved takes using the existing controls.
6. Export **COPY RAW** for the full synchronized JSON. The **PLAY MOTION GHOST**, **PLAY VFX AHEAD**, **EXPORT STUDIO** (motion) and **VFX STUDIO** (grouped FX) buttons can operate on the selected GAME take. These preview/export **separately**; there is not yet a single-click simultaneous preview of both streams.

The recorder does not upload your capture to a public repository. `writefile` capability is optional; the full raw JSON can be large at two minutes. If the client runs out of memory or the JSON encoder fails, reduce the recording length or scene/effects before trying again.

## What 'all client-visible' means

This is a **bounded observational dataset**, not a claim of exhaustive introspection. It can save readable replicated instances, their selected properties, sampled actor/character physics, animation tracks, client-visible visual/audio effects and UI visibility metadata. It does **not** see private LocalScript function bodies/closures, exact function execution, server-side state not replicated to the client, network payloads of arbitrary remote invocations, hidden assets, or private chat text. Preserve permissions and privacy when collecting other players' data.

## Subject filters and new UI
Capture and Settings expose the same NPC/Other players switches. Both OFF means self-only actor tracks. A take stores its settings and selection mode. Local settings persist when file APIs are available. Separate nearby world-VFX discovery remains independent of actor filters.
