# Update your public GitHub repository

1. Extract this repository ZIP.
2. Open https://github.com/ssengigoog-commits/gc-motion-vfx-recorder
3. Upload the **contents of the extracted ZIP** into the root of the repository (src/, dist/, docs/, scripts/, tests/ and top-level files), replacing matching files.
4. Commit the updates to `main`. This package has not been pushed to your account automatically.
5. Verify `dist/GC_MotionVFX_Baker_v7_0_2.luau` exists on the published branch before trying the short loader.

The public repository may contain **source code only**. Do not upload private captures or client account tokens. A public GitHub repository doesn't make the recorded content safe to publish.

## Build from source

With Node.js 20+ run:

```sh
node scripts/build.mjs
node scripts/check.mjs
node --test tests/*.test.mjs
```

See [README.md](README.md) and [docs/GAME_RECORDER_V7.md](docs/GAME_RECORDER_V7.md) for controls and constraints.

## Loader repair
The updated loader checks the root and the common nested repository layout, verifies the expected version marker, and reports download, compilation and startup failures separately. Use the full loader or the single-line text file. A missing loadstring or unavailable HTTP API requires a compatible authorized environment; the loader cannot supply those APIs.
