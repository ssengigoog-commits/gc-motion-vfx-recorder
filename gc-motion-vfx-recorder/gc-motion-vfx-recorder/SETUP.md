# Update the existing GitHub repository

Your GitHub repository currently stores the project inside a gc-motion-vfx-recorder folder. Keep that layout.

1. Extract the updated ZIP.
2. Open your repository ROOT page on GitHub.
3. Choose Add file > Upload files.
4. Drag in the extracted gc-motion-vfx-recorder folder itself. This updates the existing folder at the same path.
5. Commit with the message Add v7 recorder telemetry and capture performance improvements.

Do not upload the ZIP itself. Do not upload that folder while already inside the repository's gc-motion-vfx-recorder folder, or you will create another nesting level.

The new runnable release is gc-motion-vfx-recorder/dist/GC_MotionVFX_Baker_v7.luau. The old v6.8 release remains available for rollback.

No Codespace, server, exe, GitHub token or HTTP loader is required. The standalone v7 file supplied with the ZIP is the same generated code.

## Build locally, if you edit source

Node 20+, no install step:

```sh
cd gc-motion-vfx-recorder
node scripts/build.mjs
node scripts/check.mjs
node --test tests/build.test.mjs
```

Optional offline Luau suite:

```sh
node scripts/test-runtime.mjs /path/to/luau
```

Upload rebuilt dist files along with source changes. Runtime controls and limits are in docs/USAGE.md.
