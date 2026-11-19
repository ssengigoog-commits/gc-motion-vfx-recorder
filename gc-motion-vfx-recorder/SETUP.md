# Put this folder on GitHub

## Browser setup

1. Open https://github.com/new while signed in.
2. Name the repository **gc-motion-vfx-recorder**.
3. Choose **Private**. Leave README, .gitignore and license initialization unchecked because this folder already contains the first two. Do not choose a license until you decide how to license your code.
4. Click **Create repository**.
5. On the empty repository page, choose **uploading an existing file**. If a file list is already present, choose **Add file > Upload files**.
6. Open the supplied gc-motion-vfx-recorder folder in File Explorer. Drag its contents into the upload area: src, scripts, tests, docs, dist and the top-level files. Upload the contents, not the ZIP and not a containing folder.
7. Check that README.md is at the repository root and that folders retained their names. Include .gitignore and .gitattributes. If the browser skipped them, create those two files using Add file > Create new file and copy their supplied contents.
8. Commit with the message **Add recorder source and reproducible build**. GitHub may label the final button Commit changes or Propose changes depending on the branch.
9. Send the repository link back. Never paste a GitHub password or token into chat.

No server, Codespace, exe or GitHub runtime loader is required to store this code.

## Optional: edit/build in a Codespace

Once uploaded, open the repository's Code menu, choose Codespaces and create a Codespace. This is optional and may consume your GitHub Codespaces allowance.

In its terminal run:

```sh
node --version
node scripts/build.mjs
node scripts/check.mjs
node --test tests/build.test.mjs
```

Use Node 20+ if the first command reports an older version. Commit src changes together with the rebuilt dist release.

## What this first upload includes

The existing recorder separated into seven editable source sections, an already-built single-file release, checks, and an upgrade plan.

**This first upload does not yet fix recorder lag or implement the new visibility, distance, combined-take or NPC/player features.** Those features need the code changes and runtime validation listed in docs/UPGRADES.md.

## Official GitHub instructions

- https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
