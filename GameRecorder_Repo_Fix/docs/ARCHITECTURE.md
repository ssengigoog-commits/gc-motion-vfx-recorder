# Baseline architecture and next refactor

The build reads build-manifest.json and concatenates seven LF-normalized source sections in order. It performs no network requests and requires no third-party npm packages. The initial output hash must equal the existing v6.8 source.

Original dependencies flow through shared locals: Core, CFG, recording, playback, Group and UI callbacks. Sections are split only at top-level boundaries. Embedded Studio importer/codec long strings remain intact inside 06-studio-export.luau.

This preserves existing behavior without inventing new runtime loading or rewriting the recorder during repository setup.

## Baseline hot spots, still present

- Global descendant subscriptions and idle Group.indexStep().
- Broad Changed listeners, potentially thousands.
- 60Hz motion/VFX work and UI text/property updates every simulation step.
- Large effect groups and unbounded-radius discovery.

Optimization must reduce actual client work. Moving files to GitHub cannot do that by itself.

## Planned interfaces

A later release should replace shared capture state with one Session clock and explicit actor/effect track ownership. Selected actors need independent rig/joint/root/visibility/distance state. Every spawned visual group needs its own stable ID and transform timeline. Do not pool different simultaneous effects into a single pivot.

Schema additions must be backward compatible or carry a new schema version. Existing v4/v5/v6 history loading and Studio import output require explicit regression checks.
