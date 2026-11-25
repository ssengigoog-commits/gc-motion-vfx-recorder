# GitHub repository setup — GC Motion/VFX Baker v6.9

Repository: https://github.com/ssengigoog-commits/gc-motion-vfx-recorder

## Upload the v6.9 update

1. Download and extract `GC_MotionVFX_Baker_v6_9_GitHub_Repository.zip`.
2. Open your GitHub repository and select **Add file → Upload files**, or use Git.
3. Upload the **contents of the extracted ZIP into the repository ROOT**, not the ZIP file itself and not an extra containing folder.
4. In particular, check that this exact file exists:
   `dist/GC_MotionVFX_Baker_v6_9.luau`
   It should not be under `gc-motion-vfx-recorder/dist/`.
5. Commit to the `main` branch. GitHub may ask to confirm overwriting existing files; this ZIP updates the source, docs, dist, tests and build manifest. It does NOT delete the old nested `gc-motion-vfx-recorder/` folder already present on GitHub; you may remove that older duplicate separately after verifying the new root.
6. In your browser, open the raw script URL:
   https://raw.githubusercontent.com/ssengigoog-commits/gc-motion-vfx-recorder/main/dist/GC_MotionVFX_Baker_v6_9.luau
   It should return Luau source beginning with `--[[`, not 404 or HTML.

## Short loader

Once you've uploaded the new root `dist/` file, use the single-line script in `ONE_LINE_EXECUTOR_LOADER.txt` or `executor/one_line_loader.lua` in your existing, permitted client script environment.

The loader uses your public GitHub raw file. Every subsequent push to that release file can change what runs next time. Review edits before executing. No executor, injector, bypass or binary is included.

## Building from source

Node 20 or newer, no npm install required:

```bash
node scripts/build.mjs
node scripts/check.mjs
node --test tests/*.test.mjs
```

Only edit `src/*.luau` and rebuild `dist` using `node scripts/build.mjs`. Do not edit `dist` directly. `build-manifest.json` controls source ordering. `dist/GC_MotionVFX_Baker_v6_8.luau` is retained as an unchanged baseline.

## Controls and verification

F6 = Motion; F8 = VFX; F9 = Combat Inspector; F7 = Show/Hide. All recording modes support up to 120 seconds. See `docs/INSPECTOR_V6_9.md` and `GC_Baker_v6_9_Usage.txt`.

Node tests check packaging/structure only. This update has NOT been verified live in Roblox Player; start with a short recording and inspect the UI/logs before running a 120-second recording.
