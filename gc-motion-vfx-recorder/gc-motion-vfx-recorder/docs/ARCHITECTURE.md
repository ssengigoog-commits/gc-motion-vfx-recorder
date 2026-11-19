# v7 architecture

The build concatenates eight ordered LF-normalized source sections. Core and Group retain their existing shared local scope to avoid a risky complete rewrite. New telemetry functions live in src/03a-telemetry.luau.

## Session lifecycle

startRecord validates the observer and selects a bounded actor set once. All actors share session start and origin. Primary actor data stays in the legacy top-level fields; additional actors live in actors[]. This avoids duplicating the primary frame trace.

Motion, VFX and COMBINED are explicit modes. Each enabled stream samples independently against the same clock. stopRecord flushes effects, closes distance/control intervals, disconnects visibility/property/scene listeners and serializes only plain data. Preview never controls live rigs.

## Performance changes

No global scene subscriptions are attached at load. Group.indexStep exits immediately without an active VFX/combined recording. Initial discovery covers selected actors, nearby queryable parts and exact configured effect containers, not a recursive whole-Workspace walk. Initial visits have node/time budgets; discovery listeners exist only for the take.

VFX refresh rotates through groups under a 4ms between-group budget. Single group/property calls can still exceed it; the cap is not a hard real-time guarantee. Deferred refresh and sampling gaps are reported. Settings/limits trade completeness for client load.

UI updates at 5Hz; default motion/VFX sampling is 30/20Hz. Pose processing is bounded by actor/frame counts. Lightweight per-body-part transparency observers record changes between pose samples and detach on stop.

## Data version and export

Schema 7 retains v4/v5/v6 history loading and existing VFX group format. New actor, visibility, distance and capture-setting fields are additive. Studio importer validation accepts schema 7. Scene export generates per-actor keyframes plus the full synchronized scene data and replay module.

Visibility events are discrete; root/body CFrames interpolate between samples unless a large discontinuity is flagged. Ghost playback applies the final recorded reveal correctly. Jump arcs are not invented.

No network code or executor injection capabilities were added.
