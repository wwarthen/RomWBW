# LargeMem Journey for tune.com

## Objective
Implement a PT3-first memory architecture for tune.com that delivers:

- Minimal delay when moving between tracks.
- Support for PT3 files larger than TPA/heap.
- Future Previous/Next playback controls.
- Playlist visibility at all times.

This effort prioritizes PT3. MYM support is out of scope unless needed for regression safety.

## Current Constraints

- The loader reads sequential 128-byte records into RAM and stops at HEAPEND.
- PT3 playback expects direct byte access into a contiguous module image.
- TurboSound packed PT3 detection scans loaded bytes and requires footer visibility.

Current hot spots in Source/Apps/Tune/tune.asm:

- _LD0/_LD/ERRSIZ for file load and size gate.
- MDLADDR + PT3 core (INIT/PLAY/PTDECOD/CHREGS) for module access.
- TS_DETECT for packed TurboSound footer scan.

## Key Findings

1. Forward-only streaming is not enough for PT3 because access is pointer-driven and non-linear.
2. Full-load in TPA is simple but hard-limits module size and track-switch performance.
3. RomWBW already exposes bank/memory primitives that can back a virtual module layer.
4. Best long-term design is a Virtual Module Manager (VMM): logical contiguous module space over banked memory.

## Architecture Decision

Use a phased hybrid plan:

- Phase 1: playlist/navigation and prefetch foundations with no PT3 decoder rewrite.
- Phase 2: bank-backed next-track cache to reduce transition latency.
- Phase 3: PT3 VMM accessor port for true >TPA playback.
- Phase 4: optimize cache policy and complete always-visible playlist UX.

## PT3 VMM Concept

Expose module access as offset-based API instead of direct HL/BC dereference assumptions:

- vm_open(track)
- vm_get8(track, offset)
- vm_get16(track, offset)
- vm_prefetch(track, offset, len)
- vm_close(track)

Back this with APP bank pages and a small active decode window in visible RAM.

## Performance Strategy

1. Keep current track decode window hot in visible RAM.
2. Preload next track metadata and data pages in background-safe checkpoints.
3. Avoid blocking BDOS calls in the quark hot path.
4. Add lightweight counters for cache misses and refill time.

## UI and Control Targets

- Always show full playlist in playlist mode with a current-track marker.
- Add explicit Next and Previous controls.
- Keep ESC abort behavior.

## Detailed Plan

### Phase 1 (Now)

Scope:

- Add explicit playlist key controls for Next and Previous.
- Show full playlist persistently in playlist mode.
- Add phase-1 prefetch hooks and state placeholders (no PT3 decoder rewrite yet).
- Keep binary behavior stable for single-file mode.

Deliverable:

- New tune.com build with revision increment.

### Phase 2

Scope:

- Implement bank-backed next-track cache staging.
- On track boundary, prefer cache-to-active load over disk read.
- Preserve existing PT3 decoder memory model.

### Phase 3

Scope:

- Port PT3 decoder access points to VMM read accessors.
- Support modules beyond TPA with paged lookup.
- Integrate TurboSound footer/tail-safe logic against VMM reads.

### Phase 4

Scope:

- Improve replacement policy (LRU/clock) for multi-track residency.
- Add robust previous-track replay from cache.
- Tune timing and refill behavior on slow media.

## Validation Matrix

- Formats: PT3, PT3 TurboSound packed (PT2 regression check).
- Sizes: below heap, near heap, above heap.
- Modes: single file, -all, loop, next, previous.
- Devices: at least one slow storage path and one fast path.
- Audio: verify no new stutter in timer and delay modes.

## Revision Policy

- Every new test build increments the tune banner build tag bXXX.
- This journey starts from v3.2b020.
