# GC Motion / VFX Recorder — v7

Motion, joint, visibility, stud-distance and VFX recording with independent actor tracks and a synchronized session clock.

**Implemented and offline-tested. Real Roblox/Xeno playtesting and FPS measurements are still needed.** The original v6.8 file remains available as a rollback. No network loader or Codespace is required.

## Controls

| Control | Action |
| --- | --- |
| F6 | Start/stop motion recording |
| F8 | Start/stop VFX recording |
| F9 | Start/stop synchronized animation + VFX |
| F7 | Show/hide UI |
| SETTINGS | Actor switches, exact name filters, sampling profile and VFX radius |
| PLAY MOTION / BOTH | Play the selected motion or combined take |
| PLAY VFX AHEAD | Preview only VFX from a VFX/combined take |
| COPY RAW | Export complete session JSON, including actor/visibility/distance data |
| EXPORT STUDIO | Generate actor keyframe sequences and synchronized scene-preview package |

Use the generated **dist/GC_MotionVFX_Baker_v7.luau** as the complete release. Individual src files are ordered sections, not independent runnable modules. See [SETUP.md](SETUP.md) for GitHub upload/build instructions and [docs/USAGE.md](docs/USAGE.md) for recording options.

## New in v7

- Capture-scoped VFX indexing and listeners; no idle world index.
- Nearby/named-effect-container discovery, bounded counts and refresh budgets.
- UI limited to 5Hz. Balanced 30Hz motion / 20Hz VFX; optional 60Hz / 30Hz.
- Measured 3D/horizontal path, displacement and action/hidden intervals in studs.
- Base Transparency and LocalTransparencyModifier changes recorded, including events between pose samples.
- Root/joint capture continues while invisible. Ghosts replay recorded visibility and retain readable identity labels.
- Local/NPC/other-player switches, exact comma-separated name filter, four-actor cap.
- Actor identity, root/joints/animation tracks, visibility and distance share one monotonic take clock.
- Combined motion + VFX capture and local/Studio scene playback.
- Sample gaps, large discontinuities, actor loss and capture limits reported.

## Build and checks

Node 20+, no npm dependencies:

```sh
node scripts/build.mjs
node scripts/check.mjs
node --test tests/build.test.mjs
```

Optional isolated runtime suite, using a Luau CLI installed on your computer:

```sh
node scripts/test-runtime.mjs /path/to/luau
```

**60 offline checks pass**, plus build regression checks and Luau compilation. Engine doubles do not reproduce rendering, asset permissions, streaming or real client frame rates. See [docs/VALIDATION.md](docs/VALIDATION.md).

## Important measurement limits

Stud totals are sampled root-motion evidence, not server truth. Large position jumps are separated from ordinary path totals; gaps make path length a lower bound. Fallback/flashstep/uppercut names are applied only when observable attributes or track names support them. Hidden movement is counted even if its action name is unknown.

Other actors' keyboard input, server-only state and exact ParticleEmitter:Emit counts are unavailable. NPC discovery uses a bounded spatial query, so non-queryable/streamed-out rigs can be missed. Existing pooled non-queryable VFX outside named effect containers may be missed; new nearby effects are observed during capture. Limits are explicit to protect the client.

No third-party takes/assets, account tokens, injection components or remote relay are included. Only capture content you own or are authorized to use. Keep the repository owner's existing LICENSE.
