# Repository path repair

The uploaded source tree is under GameRecorder/, but the requested loader URL points to dist/ at the repository root. The repaired publication adds the current v7.0.2 distribution and checksum at root dist/ and keeps GameRecorder/ as the reproducible source tree. Loader errors distinguish download, compilation, and startup. Missing debug.traceback no longer hides the original startup error.

No capture behavior or client connection code changed. Local compilation and mocked loader tests are not a live Roblox Player test.
