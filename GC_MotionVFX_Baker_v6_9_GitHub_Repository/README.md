# GC Motion / VFX Recorder v6.9

**Recording modes:** F6 Motion, F8 VFX, F9 Combat Inspector, F7 show/hide. **Max recording length: 120 seconds.**

**Repository upload and short executor loader:** see [`SETUP.md`](SETUP.md) and [`ONE_LINE_EXECUTOR_LOADER.txt`](ONE_LINE_EXECUTOR_LOADER.txt). The loader fetches the current v6.9 single-file build from this repository's `main/dist/` path.

The preserved v6.8 baseline and new v6.9 source are in `dist/`; use `npm run build` / `npm run check` / `npm test` after editing `src/`. Live compatibility remains unverified.

---

## Detailed project notes

**v6.9 feature branch of the original Grand Clover v6.8 recorder.** The original v6.8 release is preserved byte-for-byte under `dist/GC_MotionVFX_Baker_v6_8.luau`.

**NEW:** Up to **120 seconds** per take (F6 motion, F8 VFX, F9 Combat Inspector), adjustable 30/60 FPS for motion/VFX, bounded 10 Hz multi-actor Inspector (selected players/NPCs, evaluated joint poses, animation tracks, client-readable combat-state indicators, inputs, VFX/audio lifecycle and property events). See `docs/INSPECTOR_V6_9.md`.

**Status:** built and statically tested; **not yet runtime-tested in Roblox Player**. The planned broad VFX indexing/idle-lag optimizations and combined ANIM+VFX single-take capture remain pending.

Start with [SETUP.md](SETUP.md). Requested upgrades and acceptance checks live in [docs/UPGRADES.md](docs/UPGRADES.md).

## Files

| Location | Purpose |
| --- | --- |
| src/01-bootstrap.luau | Services, existing settings, property codec and rig discovery |
| src/02-motion.luau | Recording state, input/control observations, joint and motion samples |
| src/03-vfx-groups.luau | Visual grouping, codec, discovery and lifecycle |
| src/03a-inspector.luau | Bounded selected-actor observation, combat state and audio/VFX event capture |
| src/04-capture.luau | Start/stop/save, ground placement and control reports |
| src/05-preview.luau | Take splitting, ghosts and playback |
| src/06-studio-export.luau | Embedded playback templates and Studio import generation |
| src/07-interface.luau | Existing UI, hotkeys, scheduling and shutdown |
| dist/GC_MotionVFX_Baker_v6_9.luau | **New compiled single-file release** |
| dist/GC_MotionVFX_Baker_v6_8.luau | Original archived baseline (unchanged) |
| scripts/ | Dependency-free Node build/check tools |
| tests/ | Build regression tests |
| docs/ | Architecture, scope and upgrade plan |

These are **ordered source sections**, not independently runnable Roblox ModuleScripts. The original code shares local variables across sections; concatenating them preserves its behavior and local-register scope. Do not paste one section by itself. Later refactors can introduce explicit module interfaces after behavior tests exist.

## Build locally or in a Codespace

Node.js 20 or newer is sufficient. No npm dependencies or install step.

```sh
node scripts/build.mjs
node scripts/check.mjs
node --test tests/build.test.mjs
```

Edit src/, rebuild dist/, check it, then commit both. Do not edit dist/ directly.

Tests now check that the archived v6.8 baseline is unchanged and that v6.9 contains the new bounded Inspector feature. `baseline.json` is retained as provenance.

## Performance

GitHub stores source and version history. It does not run Roblox observations on another machine. Splitting this code into files does not itself reduce FPS cost. Existing v6.8 broad indexing/watchers remain in the baseline and must be changed and profiled in the planned performance work.

## Data and ownership

No takes, character recordings, game exports, credentials or VFX media are bundled. Keep captures local. The source includes its existing property/mesh handling and Studio export generation; referenced asset IDs do not grant asset permissions. Only record/use content you own or are authorized to use. No license grant is added by this packaging.

The package does not install or configure an executor, inject into another application, add a network relay, or fetch scripts from GitHub at runtime.
