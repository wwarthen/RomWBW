# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Scope

This `WARP.md` is specific to the VGM-related applications under `Source/Apps/VGM/` (VGM player, YM2612 demo, VGM info tool, AY test utility, and associated assets). See the repo-root `WARP.md` for global build and architecture notes.

## Key Commands (VGM module)

### Build all VGM tools (Windows)

- From the repository root:
  - `cd Source\Apps\VGM`
  - `Build.cmd`

`Build.cmd`:

- Sets up the tools path (`Tools/tasm32`)
- Assembles (Windows, using `tasm32`):
  - `aytest.asm` → `aytest.com`
  - `vgmplay.asm` → `vgmplay.com`
  - `vgminfo.asm` → `vgminfo.com`
  - `ymfmdemo.asm` → `ymfmdemo.com`
- Copies outputs to the binary tree:
  - `vgmplay.com` → `Binary\\Apps\\`
  - `vgminfo.com` → `Binary\\Apps\\`
  - All `.vgm` files from `Source\\Apps\\VGM\\Tunes\\` → `Binary\\Apps\\Tunes\\`

Use this when you want to refresh all VGM-related executables and tunes in `Binary/` for image building.

### Build the VGM player (POSIX)

- From the repository root:
  - `cd Source/Apps/VGM`
  - `make`

`Makefile` here uses `Tools/Makefile.inc` and the `$(TASM)` Z80 assembler. It:

- Produces `vgmplay.com` from `vgmplay.asm` and all `*.inc` dependencies
- Ensures `Binary/Apps/Tunes/` exists
- Copies all `.vgm` from `Tunes/` into `Binary/Apps/Tunes/`

The `ymfmdemo` and `aytest` utilities are not wired into the POSIX `Makefile`; build them via Windows scripts or extend the `Makefile` if you need them from a POSIX-only environment.

### Build `vgminfo.com` (Windows)

`vgminfo.com` is a standalone info/inspection tool for VGM files:

- From `Source\Apps\VGM`:
  - `build_vgminfo.cmd`

This script:

- Sets `TOOLS` to `..\..\..\Tools`
- Configures the `tasm32` environment
- Assembles:
  - `vgminfo.asm` → `vgminfo.com` and `vgminfo.lst`

Output stays in `Source\Apps\VGM\` unless you manually copy it into `Binary\Apps\` or onto a disk image.

### Build `aytest.com` (Windows, standalone)

`aytest.com` is a dedicated test for a second AY chip, separate from the full `Build.cmd` flow:

- From `Source\Apps\VGM`:
  - `build_aytest.cmd`

The script:

- Points `TASM` to `Tools\tasm32\tasm.exe`
- Assembles:
  - `aytest.asm` → `aytest.com` (`aytest.lst` also produced)

It prints whether the build succeeded and includes a usage hint for running the resulting `aytest.com` on target hardware.

### VGM-related test assets

- `vgmtest.asm` is a test-oriented VGM-related source; build it the same way as other `.asm` programs by adding a rule to the `Makefile` or a call in `Build.cmd` if needed.

## Outputs and integration

- Main executables:
  - `vgmplay.com` – VGM player
  - `ymfmdemo.com` – YM2612/FM demo
  - `vgminfo.com` – VGM info/inspection tool
  - `aytest.com` – AY sound test utility
- Primary destinations:
  - `Binary/Apps/` – where `Build.cmd` copies `vgmplay.com`
  - `Binary/Apps/Tunes/` – where VGM tune files are copied

These artefacts are then picked up by the higher-level image build steps (`Source/Images`, root `Makefile`, and platform-specific `Source/*` Makefiles) when constructing ROM and disk images that include the VGM tooling.

## How the VGM module fits into the overall architecture

At a high level:

- VGM tools here are **CP/M applications**, not ROM-resident programs.
- They are built as `.COM` binaries using the same Z80 toolchain and `Tools/Makefile.inc` conventions as other `Source/Apps/` programs.
- Once copied to `Binary/Apps/` and included in a disk image, they run under CP/M (or a compatible OS) on top of HBIOS like any other RomWBW app.

The core layers are:

1. HBIOS in ROM (hardware abstraction, banked memory, device drivers)
2. CP/M / Z-System (OS layer, transient program area)
3. VGM tools (`vgmplay.com`, `ymfmdemo.com`, `vgminfo.com`, `aytest.com`) running as standard CP/M executables

The VGM-specific code relies on platform sound drivers and hardware configuration handled by HBIOS and the OS; the VGM utilities themselves are responsible only for parsing VGM data and driving the appropriate sound chips via the established APIs.

## When to modify what

- To **add or change tunes**:
  - Drop or edit `.vgm` files in `Source/Apps/VGM/Tunes/`
  - Re-run `Build.cmd` (Windows) or `make` (POSIX) from `Source/Apps/VGM/` to refresh `Binary/Apps/Tunes/`
- To **tweak the player or YM/FM demo behaviour**:
  - Edit `vgmplay.asm` or `ymfmdemo.asm`
  - Rebuild via `Build.cmd` or `make`
- To **evolve diagnostics** for sound hardware:
  - Edit `aytest.asm` or extend with new test programs
  - Wire them into `Build.cmd` and/or the `Makefile` following the existing assembly patterns

Keep new VGM-related programs and assets under `Source/Apps/VGM/` and use the existing scripts/Makefile for consistency with the rest of the RomWBW build system.