# Changelog

## 7.1.1 — 2026-11-26
- ImageGen-guided Capture / Library / Settings interface and responsive native controls.
- Independent NPC/player filters, persistent settings and per-take filter metadata.
- Self always included; bounded nearest/manual actor selection.
- Fixed actor-picker forward declaration and kept prior capture/export/playback paths.
- Offline Luau tests and native compilation; live Player acceptance pending.


## 7.0.2 — 2026-11-26 (F3 Highlight stream; live test pending)

- F3 GAME records `Highlight` initial/add/change/remove events and full visual properties: Enabled, fill/outline colors and transparencies, depth mode, and resolved Adornee target.
- Observes existing actor, PlayerGui, and nearby world highlights; watches subsequent client-visible property changes using bounded listeners with cleanup.
- Includes `game.highlights` and `GAME_HIGHLIGHT_*` timeline events in synchronized raw export. Existing F6/F8 functionality and the 120-second limit remain intact.
- Preserves the former v7.0.1 script as rollback; Highlight metadata is not yet reconstructed in the separate VFX preview.

## 7.0.1 — 2026-11-25 (hotkey update; live test pending)

- Changed the combined GAME recorder toggle from **F9** to **F3**.
- Updated button labels, help text, usage docs, and loader to the new `v7_0_1` release.
- **F6**, **F7**, and **F8** are unchanged; **F9**, **F10**, and **F12** are not used by the updated script.
- Original v7.0 and older releases retained as archives.

## 7.0 — 2026-11-25 (local build; live test pending)

- F9 **GAME** unifies the existing ANIM motion, grouped VFX and selected-actor Inspector into one timestamped JSON take.
- Adds bounded camera, HUD visibility, Lighting, gravity, client sound events, selected actor value/attribute watchers and new readable runtime instance metadata.
- Preserves F6, F8, F7, ghost/VFX previews, JSON export, separate Studio motion and VFX export, saved takes, take deletion and old histories.
- Maintains 120-second cap; F9 samples 30Hz motion, 15Hz VFX, 10Hz actors and 5Hz scene; buffers and listeners capped to manage overhead.
- Uses `GC_BAKER_HISTORY_v7.json` for new history, while searching v6/v5/v4 histories.
- Preserves `dist/GC_MotionVFX_Baker_v6_8.luau` and `dist/GC_MotionVFX_Baker_v6_9.luau` for rollback.
- Six structural/build tests passing; real Roblox verification still pending.

## 6.9

Combat Inspector and 120-second duration; prior release retained as archive.

## v7.0.2 packaging repair
- Guarded loader with explicit download, compile and startup diagnostics.
- Root and nested repository path handling.
- Corrected outdated F9 usage instructions to F3.
- Recorder source and historical distributions unchanged.
