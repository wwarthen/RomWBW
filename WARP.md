# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Key Commands

### Top-level build and clean (cross-platform)

- Full build (tools + sources, POSIX):
  - `make`
- Full clean (tools + sources + binary tree, POSIX):
  - `make clean`
- Distribution build (POSIX):
  - `make dist`
  - `make distlog` (wraps `make dist` with timing and log capture to `make.log`)

These `make` targets delegate into `Tools/` and `Source/` using `Makefile` in the repo root.

### Windows build and clean entrypoints

- Full build (Windows, uses `Source/Build.cmd`):
  - `Build.cmd`
- Full clean (Windows, clears `Binary/` and `Source/` products):
  - `Clean.cmd`

Both scripts live at the repository root and delegate into the `Source/` and `Binary/` trees.

### Source tree orchestration

`Source/Makefile` is the orchestration layer for all firmware, OSs, and applications. Its main targets are:

- Default (build everything under `Source/`):
  - `cd Source`
  - `make`
- Clean all subcomponents:
  - `cd Source`
  - `make clean`
- Diff Unix vs Windows builds (when a Windows tree is mounted at `../RomWBW.windows`):
  - `cd Source`
  - `make diff`

`Source/Makefile` expands into these major phases (via `$(ACTION)`):

- `prop` – Propeller-related pieces in `Source/Prop/`
- `shared` – common components (diagnostics, CBIOS, CP/M variants, Z-System variants, BPBIOS, CPNET, p-System, apps, Forth, TastyBasic, fonts, ROM disk)
- `images` – disk/ROM image building in `Source/Images/`
- `rom` – HBIOS ROM build in `Source/HBIOS/`
- Platform groups – ZRC, Z1RCC, ZZRCC, ZRC512, SZ80, EZ512, MSX

### HBIOS / ROM-specific build commands

The HBIOS subtree has its own build tooling:

- POSIX:
  - `cd Source/HBIOS`
  - `make` (or `make all`) – build HBIOS ROM and related outputs
  - `make clean` – clean HBIOS outputs
  - `make diff` – compare Unix vs Windows-built HBIOS binaries (when a reference tree exists)
- Windows helper script:
  - `Source\HBIOS\Build.cmd` – Windows wrapper for the HBIOS build

### Disk/image build helpers

The `Source/Images/` directory contains scripts and a Makefile for disk and ROM image generation:

- POSIX image build:
  - `cd Source/Images`
  - `make` – main image build
  - `make clean` – clean image artefacts
- PowerShell helpers (for Windows with POSIX toolchain installed):
  - `Source\Images\BuildDsk.ps1`
  - `Source\Images\BuildImg.ps1`

At the very top level, `Source/BuildImages.cmd` calls into `Source/Images/Build.cmd` and related tooling.

### Application builds

Applications under `Source/Apps/` are managed by `Source/Apps/Makefile` and per-app build scripts:

- Build all applications (POSIX):
  - `cd Source/Apps`
  - `make`
- Clean all applications (POSIX):
  - `cd Source/Apps`
  - `make clean`

Many applications also have their own `Build.cmd`/`Clean.cmd` plus local `Makefile`s. For example:

- `Source\Apps\Test\Build.cmd` – builds the test utilities suite (banktest, inttest, ramtest, etc.)
- `Source\Apps\VGM\Build.cmd` – builds the VGM player and related utilities (see module-specific `WARP.md` in `Source/Apps/VGM/` for details)

### Tests and diagnostics

There is no central unit test framework; instead, the project uses a suite of CP/M-era test programs and diagnostics under `Source/Apps/Test/` and related trees. Typical usage pattern:

- Build the diagnostics suite:
  - `cd Source/Apps/Test`
  - On Windows: `Build.cmd`
  - On POSIX: `make`
- Copy the resulting `.COM` programs from `Binary/Apps/Test/` to a RomWBW disk image or target system and run them from within CP/M/Z-System.

Each diagnostic lives in its own subdirectory with a `Build.cmd` and `Makefile` (e.g., `banktest`, `inttest`, `ramtest`, `vdctest`, `kbdtest`, `testh8p`). To build a single diagnostic:

- `cd Source/Apps/Test/<name>`
- On Windows: `Build.cmd`
- On POSIX: `make`

`inttest` additionally has a `inttest.doc` with usage notes.

## High-Level Architecture

### Distribution layout

RomWBW is structured around a source tree and a distribution layout described in `ReadMe.md` and `Source/Doc/Introduction.md`:

- `Binary/` – final images and binaries:
  - ROM images (`*.rom`)
  - Disk images (`*.img`)
  - Host-side apps and utilities under subfolders like `Binary/Apps/` and `Binary/Apps/Test/`
- `Doc/` – user-facing documentation and reference manuals (PDFs and generated artifacts)
- `Source/` – all firmware, OS, and application sources
- `Tools/` – cross-development toolchain and scripts used by the build system

The main workflow is: **build tools** → **build sources** → **generate ROM/disk images** → **deploy images to target hardware**.

### Firmware / OS layering

The conceptual layering (outlined in `Source/Doc/SystemGuide.md`) is:

1. **Hardware** – specific Z80-family hardware platform
2. **HBIOS (Hardware BIOS)** – hardware abstraction layer in ROM, with a fixed 512-byte proxy at the top of Z80 address space and banked driver code
3. **CBIOS / OS** – CP/M-family operating systems and Z-System variants adapted to call into HBIOS
4. **Applications** – CP/M executables and ROM-hosted apps using the OS and/or HBIOS API

Key points:

- HBIOS provides a well-defined API for hardware services: disk I/O, serial, video, keyboard, RTC, CP/NET networking, memory banking, and interrupts.
- All OSes are adapted to HBIOS rather than to specific hardware, so the same disk images can boot on multiple hardware platforms with compatible HBIOS builds.
- Bank-switched memory is used to keep most hardware-dependent code out of the conventional CP/M 64K memory map; a small proxy in upper memory handles bank switches into driver banks.

### Memory model and banking

`Source/Doc/SystemGuide.md` describes the runtime memory strategy:

- 64K Z80 address space is split into:
  - Lower 32K: banked window (maps any 32K bank of physical RAM/ROM)
  - Upper 32K: fixed bank (never swapped; contains OS and HBIOS proxy)
- Physical memory is organized into 32K banks with **Bank Ids**:
  - ROM banks: Bank Ids 0x00–0x0F (0x00 is always first ROM bank)
  - RAM banks: Bank Ids 0x80–0x8F (0x80 is always first RAM bank)
- HBIOS APIs use Bank Ids to abstract away platform-specific MMU implementations.

This design allows multiple OSes, RAM disks, and ROM disks to coexist while maximizing the TPA (transient program area) available to CP/M applications.

### Source tree structure (high level)

Within `Source/`, most subdirectories correspond to functional subsystems:

- `HBIOS/` – core ROM and hardware abstraction layer
- `CBIOS/` – CP/M BIOS implementations targeting HBIOS
- `CPM22/`, `CPM3/`, `ZPM3/`, `ZSDOS/`, `ZSDOS2/`, `QPM/`, `ZCPR/`, `ZCPR-DJ/` – CP/M-family operating systems and Z-System layers
- `BPBIOS/` – BPBIOS components and utilities
- `CPNET/` – CP/NET networking support (including platform-specific cpnet variants)
- `RomDsk/` – ROM disk content and build machinery
- `Apps/` – applications and utilities (system tools, diagnostics, games, VGM player, etc.)
- `Forth/`, `TastyBasic/` – language runtimes hosted by RomWBW
- `Images/` – image composition (combining ROM/OS/apps into deployable binaries)
- Platform-specific top-levels (e.g., `ZRC/`, `Z1RCC/`, `ZZRCC/`, `ZRC512/`, `SZ80/`, `EZ512/`, `MSX/`, `Prop/`) – tie a specific hardware platform to the core components and images

Each subtree has its own `Makefile`, reusing `Tools/Makefile.inc` to standardize:

- Object naming and suffix rules (`.asm`, `.z80`, `.azm`, `.rel`, `.com`, `.rom`, `.bin`, `.hex`)
- How to invoke the Z80 assemblers (`uz80as`, Z80ASM, MAC, RMAC, ZSM, etc.) via `zxcc`
- Cross-platform behaviour (copying built artefacts into `Binary/`)

### Applications and ROM-hosted programs

The `Source/Doc/Applications.md` describes the RomWBW-specific applications, split into:

- **ROM Applications** – programs launched directly from ROM at the boot menu (monitor, CP/M 2.2, Z-System, BASIC variants, Forth, game launcher, flash updater, user app slot, etc.)
- **CP/M Applications** – programs loaded from disk under CP/M/Z-System (many RomWBW-specific tools, e.g., `SYSCONF`, `ASSIGN`, `SLABEL`, diagnostics, FAT utilities)

The bootloader menu allows selecting OS and ROM apps, configuring autoboot, adjusting console and diagnostics verbosity, and starting network boots.

Most new utilities or applications should be added under `Source/Apps/` with a `Makefile` and optional `Build.cmd` that follow the patterns already established. The build system will place resulting binaries into `Binary/Apps/` (or a subfolder) for inclusion in images.
