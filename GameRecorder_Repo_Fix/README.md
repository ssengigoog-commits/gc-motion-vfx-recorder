# Grand Clover Motion / VFX / Game Recorder v7.1.2

This repository contains the current7.1.2 recorder with a **combined F3 Game Recorder**. It is a local, client-observation tool; it has no AI, MCP server, remote telemetry, exploit attachment code or server-side access.

## Modes

| Key | Mode | What it records |
| --- | --- | --- |
| **F6** | ANIM | Existing evaluated body joints, root movement, camera/root timing, animation tracks and control observations |
| **F8** | VFX | Existing grouped client-visible VFX with hierarchy, properties, transforms and playback |
| **F3** | GAME | **One synchronized take**: F6 motion + F8 grouped VFX + selected players/NPCs + status, input, camera, HUD visibility, audio, **Highlight appearance/properties**, and runtime instance changes |
| **F7** | UI | Toggle the recorder window |

Maximum duration **120 seconds**. F3 captures Highlight initial/add/change/remove with fill and outline colors/transparencies, Enabled, depth mode, and Adornee target. The raw JSON stores these in `game.highlights` and `events`. Highlights are **not yet rendered in the separate VFX ghost preview**. F3 defaults to 30Hz motion, 15Hz grouped VFX sampling, 10Hz selected-actor pose samples and 5Hz scene/camera/HUD snapshots. F6/F8 retain their 30/60 FPS switch. Event/frame limits are documented in [docs/GAME_RECORDER_V7.md](docs/GAME_RECORDER_V7.md).

## Run the recorder

The built, single-file script is **[`dist/GC_MotionVFX_Baker_v7_1_2.luau`](dist/GC_MotionVFX_Baker_v7_1_2.luau)**. It can be loaded in an **existing authorized** client-side Luau environment that provides the required file/clipboard APIs. This repository does not supply an injector or executor.

With this repository publicly available at the stated URL and the v7 file committed to `main`, the optional short loader is in [`LOADER.txt`](LOADER.txt). Only use scripts and assets you have permission to inspect and reproduce.

Inside the recorder select the **GAME** tab, choose up to four nearby actors in **CHOOSE ACTORS**, and press F3 (or **REC GAME F3**). Press again to stop. Select the saved take to view its combined event timeline and source actors. **COPY RAW** exports one JSON document containing `frames`, `vfx`, `inspector`, `game`, `events`, and track metadata. The existing **PLAY MOTION GHOST** and **PLAY VFX AHEAD** previews work on GAME takes as separate previews. **EXPORT STUDIO** exports motion; **VFX STUDIO** exports grouped VFX for GAME takes.

Save files are created locally only when the running client environment supports `writefile`; otherwise the recorder keeps data in memory and supports clipboard/manual export. **Do not publish captures of other players without permission.** The history loader continues to recognize saved v4/v5/v6/v7 file names.

## Source, build and tests

Sections in `src/` are concatenated in [`build-manifest.json`](build-manifest.json) order. They share top-level Luau locals and are **not** independent ModuleScripts. Do not run individual source sections.

```sh
node scripts/build.mjs
node scripts/check.mjs
node --test tests/*.test.mjs
```

Only Node.js 20+ is required; no npm dependencies. Commit the rebuilt `dist` file and checksum alongside your edited sources.

## Status / limits

The Node build, checksum, regression and structural capture checks have passed. **Native Luau compilation and offline UI construction/settings tests have passed. No live Roblox Player test or real 120-second stress run has been completed.** F3 records the readable client state only; it cannot directly observe server scripts, unseen server-side mechanics, private script locals/closures, remote calls' payloads, or exact `ParticleEmitter:Emit(n)` counts. Numeric stun/status fields are stored as evidence and **not** interpreted as authoritative server acceptance.

See [docs/GAME_RECORDER_V7.md](docs/GAME_RECORDER_V7.md) and [docs/VALIDATION.md](docs/VALIDATION.md) for capture details and test steps.

## New Capture / Library / Settings interface

- **Capture:** choose Game F3, Motion F6 or VFX F8; large Start/Stop button, elapsed time, live subject summary.
- **Other players** and **NPCs** are independent toggles, available on Capture and Settings. They control Game actor motion/animation/combat-state tracks. Your local character is always included.
- With no manual choices, Game selects the nearest enabled actors, up to **four including self**. Choose actors overrides automatic fill. Disabled actor types are excluded even if selected earlier.
- Changes apply to the next take; changes during recording are rejected. The take stores its filter snapshot and selection mode.
- Nearby world VFX are a separate stream and are not globally suppressed by actor toggles. Motion/VFX standalone modes are unchanged.
- Settings use the allowlisted local file `GC_BAKER_SETTINGS_v7.json` when file APIs exist; otherwise they persist in the same client session.
- Capture quality, history search, raw/Studio export, ghost playback, loop, estimated bursts and legacy take loading remain available.
- The native window scales to the viewport. Page switches reuse one UI rather than restoring an old interface. F7 hides/shows it; Close stops and cleans up recorder listeners.

The visual reference was produced with ImageGen and implemented with native Frames/TextButtons. No new Roblox asset upload is needed. See `design/ui-reference.png`.

Run interpreter-backed tests by setting `LUAU_BIN` to your local official Luau CLI executable, then running `node --test tests/*.test.mjs`. Such tests are mocked, not live game telemetry.

## Current-only package
LOADER.txt is exactly five lines. Prior release scripts and redundant loader copies have been removed from this package. Legacy take import remains supported; deleting old script distributions does not delete recordings.

## Idle-performance fix (7.1.2)
No idle world scanning or world/property subscriptions. Start VFX/Game capture to enable them; Stop disconnects them. History is metadata-only, take files load on selection, and hidden Library rows are not constructed. Replace the repository GameRecorder_Repo_Fix folder with this folder, including dist, then run LOADER.txt again. The loader remains five lines and automatically shuts down the older instance through its existing shutdown hook. This package is offline-tested, not a measured live FPS result.

## Automatic nearby capture (7.1.2)
Choose Actors is removed. Record players/Record NPCs switches select types; actors within60studs are automatically discovered while Game/Inspector recording runs. Local character always included. Discovery refreshes once/second; nearest32 total actor safety budget and query-limit flags are documented in docs/AUTOMATIC_CAPTURE.txt. Previous idle-performance fixes remain. Replace the repository GameRecorder_Repo_Fix folder (including dist), then rerun the five-line LOADER.txt. No live FPS claim.
