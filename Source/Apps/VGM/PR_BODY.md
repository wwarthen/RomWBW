Hi Wayne,

I've developed a small utility called VGMINFO.COM that complements the existing VGM player in RomWBW. It scans .VGM files in the current directory and displays which sound chips they use.

## Features
- Scans all .VGM files in the current directory
- Detects the following chips:
  - SN76489 (PSG - Programmable Sound Generator)
  - YM2612 (FM synthesis chip used in Sega Genesis/Mega Drive)
  - YM2151 (OPM - FM Operator Type-M)
  - YM3812 (OPL2 - FM synthesis chip)
  - YMF262 (OPL3 - Enhanced FM synthesis chip)
  - AY-3-8910 (PSG used in many arcade and home computers)
- Supports dual-chip configurations (e.g., 2xSN76489, 2xAY-3-8910)
- Displays results in a clean, formatted table

## Use Case
This is useful for users to quickly determine which VGM files are compatible with their hardware before attempting to play them with the VGM player.

## Request
If suitable, could you please incorporate this into the RomWBW build process? It would fit nicely alongside the existing VGM utilities in Source/Apps/VGM/.

The tool is written in Z80 assembly, assembles with TASM, and follows the same structure as other RomWBW CP/M utilities.

**Version 1.1** includes YM3812 (OPL2) and YMF262 (OPL3) detection support.

Best regards,
Miguel