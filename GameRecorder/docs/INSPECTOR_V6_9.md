# v6.9 — Two-minute recorder + Combat Inspector

## What stays unchanged

- **F6 Motion**: original high-detail root/camera/joint motion, user input, animation-track timing, and ghost preview.
- **F8 VFX**: original grouped VFX capture, mesh/attachment playback, splitting and Studio export.
- Saved takes, history manifests, v4/v5/v6 import compatibility, search, deletion and raw JSON export remain supported.
- The original v6.8 release is preserved in `dist/GC_MotionVFX_Baker_v6_8.luau`.

## What's new

- **Maximum take length: 120 seconds** for every recording mode, rather than 30.
- A **RATE 60 FPS / 30 FPS** toggle on the right. Default 60 FPS preserves legacy motion and VFX fidelity; use 30 for lower resource usage during long sessions. This does **not** change the Inspector's 10 Hz data rate.
- **F9** or **REC INSPECT F9** starts/stops a separate Combat Inspector take.
- Choose the **INSPECT** saved-take tab, then **CHOOSE ACTORS**. Select up to **four** locally visible players or nearby NPCs within **90 studs**. If none is selected, record only your local character. Refresh the actor picker after NPC spawning/streaming.
- Inspector samples selected actor positions/velocities, health, Humanoid states, WalkSpeed, active animation IDs/speeds/times and evaluated joint transforms at a capped 10 Hz. Captured transforms are from visible character parts; private Motor6D.Transform and hidden animation code are not captured.
- Inspector records relevant client-visible attributes and ValueBase flags, including possible **stun/block/action-lock indicators**, as *observations*, not server-confirmed status. Numeric flags may be timestamps/deadlines; do not interpret them as proof of stun.
- Records input **down/up** events and nearby **new/removed VFX and sound** objects, plus selected property changes where readable. Initial effects under chosen actor hierarchies are sampled within a bounded budget.
- Inspector takes are searchable, scrollable, deletable, and export as **RAW JSON**. They do **not** generate a Studio animation importer or ghost playback; those features remain reserved for ANIM/VFX takes.
- Bounded: 1,200 inspector sample frames, 6,000 events, 120 observed effect-property connections; limits and dropped samples are flagged.

## How to use

1. Use your already-installed, permitted client scripting environment to execute `dist/GC_MotionVFX_Baker_v6_9.luau`. **This package does not provide an executor, attachment method, injector, or anti-cheat bypass.**
2. Press **F7** to show/hide the recorder UI.
3. Press **F6** to record motion, **F8** for grouped VFX, or **F9** for a Combat Inspector take. Press the same key to stop early, or recording automatically ends at 120 seconds.
4. Open the matching ANIM / VFX / INSPECT library tab. Choose a saved take. The right panel shows a synchronized timeline of events and/or selected actors.
5. **COPY RAW** exports the take data. **DELETE** removes a take from recorder history and, when file APIs are available, its corresponding on-disk JSON file. Backup important takes first.

## Important limits

- Still **client-side only**. Cannot inspect server scripts, private script source, hidden calls or private runtime variables; observed input is not proof the server accepted an action.
- No network connection or AI/MCP requirement. No user character control or gameplay action automation.
- The existing broad VFX warm index and Changed watchers can still cause frame-time spikes. The warm index is paused during ANIM/INSPECT recording, and UI status text refreshes about eight times per second while capture/preview timing remains independent. 120-second captures may consume considerably more memory; test at 30 FPS if necessary. The VFX event cap may truncate high-effect sessions; the export indicates this.
- Runtime compatibility and FPS performance in your installation **have not been verified** by this package. Test a short take before attempting two minutes.
