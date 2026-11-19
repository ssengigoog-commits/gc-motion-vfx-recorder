# GC Motion / VFX Recorder

Repository setup package for the existing Grand Clover v6.8 recorder.

**Status: baseline packaging. The lag fixes and new recording options are planned, not implemented in this release.** Your original recorder is unchanged. The generated release reconstructs it byte for byte.

Start with [SETUP.md](SETUP.md). Requested upgrades and acceptance checks live in [docs/UPGRADES.md](docs/UPGRADES.md).

## Files

| Location | Purpose |
| --- | --- |
| src/01-bootstrap.luau | Services, existing settings, property codec and rig discovery |
| src/02-motion.luau | Recording state, input/control observations, joint and motion samples |
| src/03-vfx-groups.luau | Visual grouping, codec, discovery and lifecycle |
| src/04-capture.luau | Start/stop/save, ground placement and control reports |
| src/05-preview.luau | Take splitting, ghosts and playback |
| src/06-studio-export.luau | Embedded playback templates and Studio import generation |
| src/07-interface.luau | Existing UI, hotkeys, scheduling and shutdown |
| dist/GC_MotionVFX_Baker_v6_8.luau | Generated single-file baseline release |
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

The baseline-equality test intentionally protects this initial packaging. When implementing a new release, replace that baseline-only assertion with the appropriate new behavior tests and update release-status.json; retain baseline.json as provenance.

## Performance

GitHub stores source and version history. It does not run Roblox observations on another machine. Splitting this code into files does not itself reduce FPS cost. Existing v6.8 broad indexing/watchers remain in the baseline and must be changed and profiled in the planned performance work.

## Data and ownership

No takes, character recordings, game exports, credentials or VFX media are bundled. Keep captures local. The source includes its existing property/mesh handling and Studio export generation; referenced asset IDs do not grant asset permissions. Only record/use content you own or are authorized to use. No license grant is added by this packaging.

The package does not install or configure an executor, inject into another application, add a network relay, or fetch scripts from GitHub at runtime.
