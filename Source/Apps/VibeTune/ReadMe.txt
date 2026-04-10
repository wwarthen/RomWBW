VibeTune (VTUNE) for RomWBW
===========================

Overview
--------
VibeTune is the enhanced RomWBW music player for PT2/PT3/MYM and VGM files.
It includes playlist playback, terminal-aware UI behavior, and broader sound
chip support than the classic Tune app.

Key Features
------------
- File format support:
  - PT2, PT3, MYM
  - VGM
- VGM chip support:
  - AY-3-8910 / YM2149 (single and dual-chip)
  - SN76489 (single and dual-chip)
  - YM3812 (OPL2)
  - YMF262 (OPL3)
  - YM2151 (OPM)
- Playlist mode:
  - Enumerates supported files in current directory with -list
  - Keyboard navigation (W/A/S/D), next/previous track, redraw, and loop modes
  - Optional delete confirmation flow in playlist UI
- TurboSound PT3 support:
  - Detects packed dual-module PT3 TurboSound files
  - Uses dual AY port sets when available
- Playback control:
  - Pause/resume (space)
  - Loop track and loop playlist modes
  - Skip/previous control during playback
- Port selection and hardware behavior:
  - Auto-detection for supported targets
  - Manual port options for MSX/RC/Coleco AY mappings
  - Delay mode and HBIOS mode options
- Terminal profile configuration:
  - -config interactive mode
  - Persists terminal settings in TERM.CFG for reuse across applications
  - Stores term type, ANSI preference, and visible rows/columns

Build Outputs
-------------
Build.cmd and Makefile produce these binaries:
- VTUNE.COM (WBW)
- VTUNEZX.COM (ZX)
- VTUNEMSX.COM (MSX)

Build
-----
Windows:
  Build.cmd

POSIX:
  make

Usage
-----
VTUNE <filename>.[PT2|PT3|MYM|VGM] [-msx|-rc|-coleco] [-delay] [--hbios]
      [+tn|-tn] [-list] [-loop] [-config]
