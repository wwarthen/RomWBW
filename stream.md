# Streaming `tune.com`: Moving Beyond Full In-Memory File Loading
## Objective
Evaluate what is required to change `tune.com` from loading an entire input file into RAM to a streaming/paged approach so files larger than available heap/TPA can be supported.
This document captures current behavior, format-specific implications, and practical migration guidance.
## Current Behavior (As Implemented)
`Source/Apps/Tune/tune.asm` currently uses a strict full-load model:
- File is opened via BDOS (`_LD0`).
- DMA target is selected by format:
  - PT2/PT3: `MDLADDR`
  - MYM: `rows` (header), then compressed data at `data`
- Sequential 128-byte reads (`BDOS` function 20) are performed in `_LD`.
- The destination pointer is incremented every record.
- Loading aborts with `ERRSIZ` when destination reaches `HEAPEND` page.
- Playback setup starts only after load completes.
Key code regions:
- Load loop and size guard: `Source/Apps/Tune/tune.asm` (`_LD0`, `_LD`, `ERRSIZ`)
- Heap limit: `HEAPEND .EQU $C000`
- Shared heap layout and format overlays: end of `Source/Apps/Tune/tune.asm` (`HEAP`, `MDLADDR`, `rows`, `data`)
## Why Files Larger Than TPA/Heap Fail
The loader checks high-byte page against `HEAPEND` while reading.
Once reached, it aborts immediately with `ERRSIZ`.
This is not only a loader limitation:
- PT2/PT3 playback logic assumes direct in-memory module access.
- So simply replacing the loader with forward streaming is insufficient for those formats.
## Format-by-Format Streaming Feasibility
## PT2/PT3 (including TurboSound-packed PT3)
### Access Pattern
The Bulba PTx core (`INIT`, `PLAY`, `PTDECOD`, `CHREGS`) performs pointer-driven, non-linear reads:
- Initializes pattern/sample/ornament pointers (`PatsPtr`, `SamPtrs`, `OrnPtrs`, etc.) from module internals.
- Uses dynamic pointer updates and indirect reads (`LD A,(BC)`, stack/pointer manipulation, table indirections).
- Uses mixed forward jumps and references, not a simple linear consume stream.
Relevant areas:
- `START`/`INIT`: `Source/Apps/Tune/tune.asm` around PTx init logic
- Runtime decode/play loops: `PLAY`, `PTDECOD`, `CHREGS`
### Implication
PT2/PT3 require random-like access semantics over module bytes.
Therefore:
- **Simple read-next-chunk streaming is not viable**.
- A viable large-file solution needs either:
  1) full module in RAM (current approach), or
  2) an offset-addressable paged cache / virtual byte-access layer.
## TurboSound Footer Detection Adds Tail Dependency
`TS_DETECT` currently scans loaded PT3 bytes for packed dual-module footer signatures:
- Signature checks include `PT3!`, second `PT3!`, and `02TS`.
- Validation depends on computed offsets and lengths relative to module base.
- Scan uses loaded data buffer (`MDLADDR` .. `LOADBYTES`).
Relevant region:
- `TS_DETECT`: `Source/Apps/Tune/tune.asm`
### Implication
In a streaming design, packed-TS detection needs explicit strategy:
- Tail prefetch/read,
- two-pass parse,
- or deferred/conditional detection logic.
A pure prefix-only stream is insufficient.
## MYM
### Access Pattern
MYM path (`mymini`, `extract`, `readbits`) is bitstream-centric and substantially more stream-friendly:
- Source cursor advances forward through compressed `data`.
- Copy references in decompression refer to previously produced fragment windows, not arbitrary source seeks.
- Playback consumes decoded fragments and updates PSG registers.
Relevant region:
- MYM decode and bit reader: `Source/Apps/Tune/tune.asm` (`extract`, `readbits`, `upsg`)
### Implication
MYM can be adapted to streaming with bounded source buffering/refill.
This is the lowest-risk path to support files beyond heap limits.
## Read-Ahead Requirements
Yes, read-ahead (or equivalent staging) is required.
## PT2/PT3
- Need initial bytes for headers/pointer setup.
- Runtime access is not strictly linear; read-ahead alone is not enough without random-access paging/caching.
## TurboSound PT3
- Footer/signature may be at end; must support tail visibility.
## MYM
- Small upfront parse plus continuous forward refill is typically sufficient.
## Timing and Audio Stability Implications
Playback cadence is timing-sensitive (`WAITQ` in `Source/Apps/Tune/timing.inc`):
- Timer mode uses BIOS timer tick polling.
- Delay mode uses calibrated spin loop.
Any blocking BDOS I/O in the hot playback path can introduce jitter/stutter.
### Consequences for streaming
- Cache miss behavior must be controlled.
- Refill policy must minimize blocking during quark/update windows.
- Slow media needs explicit testing and possibly larger buffer windows.
## Architectural Options
## Option A: MYM-only Streaming (Recommended First)
Keep PT2/PT3 full-load behavior unchanged; stream MYM source data only.
Pros:
- Minimal invasive change.
- Fastest path to real >heap support for at least one format.
- Lower regression risk.
Cons:
- PT2/PT3 still capped by heap.
## Option B: PT2/PT3 Paged Random-Access Layer
Introduce abstract module access by file offset, backed by page cache.
Pros:
- True >heap PT2/PT3 support possible.
Cons:
- Significant refactor in timing-critical assembly paths.
- High complexity and regression/timing risk.
- Requires careful cache/miss design and profiling.
## Option C: Hybrid Staging
Attempt to preload index/control sections and stream only selected sections.
Pros:
- Potentially less than full random-access rewrite.
Cons:
- PTx format/control flow is pointer-rich and brittle for partial assumptions.
- Hard to guarantee correctness across all modules.
## Behavioral Implications to Define Up Front
Before implementation, define expected behavior for:
- End-of-file during active stream/decode.
- Refill failure or media timeout.
- Loop mode with streamed backing (rewind semantics).
- Playlist transitions (`-all`) and per-track state reset.
- TurboSound packed detection fallback policy if tail not immediately available.
## Test Strategy (Minimum)
Validate across:
- Formats: PT2, PT3, PT3 TurboSound packed, MYM
- Sizes: below heap, near heap ceiling, above heap
- Storage: fast and slow media
- Modes: normal, `-loop`, `-all`, TurboSound path
- Timing: timer mode and delay mode
Acceptance criteria:
- No playback correctness regressions on known-good files
- No audible timing instability under expected media conditions
- Correct loop/playlist behavior
- Correct TurboSound packed detection outcomes
## Recommended Migration Sequence
1. Implement MYM streaming first (bounded scope).
2. Add instrumentation for refill/cursor health and timing impact.
3. Validate on slower storage configurations.
4. Decide whether PT2/PT3 should remain full-load or move to paged random-access architecture.
5. If PT2/PT3 paging is pursued, prototype accessor/cache in isolation before broad integration.
## Bottom Line
- **MYM is a practical candidate for streaming.**
- **PT2/PT3 are not simple forward-stream candidates** due to non-linear access patterns.
- Supporting >heap PT2/PT3 requires **paged/random-access abstraction** and careful timing-aware integration.
- TurboSound packed PT3 additionally requires **tail/footer-aware detection strategy**.
