hbconfig: menu-driven editor for RomWBW board configs.

Opens a config file (Source/HBIOS/Config/<platform>_<config>.asm) in a
text menu like the Linux kernel's menuconfig, and writes what you change
back into that file as .SET lines. Optional: the normal build never
runs it or needs it, and hand-written configs keep working as before.

  make config ROM_PLATFORM=<platform> ROM_CONFIG=<config>
  make showconfig ROM_PLATFORM=<platform> ROM_CONFIG=<config>
  make checkconfig ROM_PLATFORM=<platform> ROM_CONFIG=<config>

On Windows, from the RomWBW root:

  Config <platform> <config>
  Config -show <platform> <config>
  Config -check <platform> <config>
  Config -install

A platform or config left out is asked for. Needs Python 3; on Windows
Config uses its own Python in Tools\python, never the system one. The
first time it asks, then downloads the python.org embeddable Python and
the windows-curses package into Tools\python (about 15 MB, checked
against SHA-256 sums). Nothing outside the RomWBW folder is changed and
deleting Tools\python removes it. "Config -install" does it again.

AI: hbconfig was written with Claude, an AI (LLM) by Anthropic. Claude
wrote the code in hbconfig.py, Config.cmd and install-python.ps1, and the
changes marked "RomWBW:" in menuconfig.py. Willy De la Court directed
it, reviewed every change and tested it on real configs. As agreed on
issue #722, it falls under the applications exception in CONTRIBUTING.md:
a standalone tool for the build machine, never part of the normal build
or of the ROM.

Files:

hbconfig.py         The tool, see its header for usage.
install-python.ps1  Windows only, run by Config.cmd: downloads the private
                    Python and windows-curses into Tools\python.
new_config.asm      Start of a new config ("make config" on a config that
                    does not exist yet). <TITLE> and <PARENT> are filled
                    in from the std picked as its parent.
SPEC.md             What the tool should do.
RULES.md            How to write settings in cfg_MASTER.asm so the menu
                    picks them up right: do's and don'ts.

kconfiglib.py       Unmodified copy of Kconfiglib 14.1.0,
                    https://github.com/ulfalizer/Kconfiglib (tag v14.1.0).
menuconfig.py       Kconfiglib 14.1.0's menuconfig with small RomWBW
                    patches, marked "RomWBW:": a node_hidden hook that
                    hides rows outside show-all mode, and a node_on hook
                    plus an "on-list" style that draw rows green.
LICENSE.txt         Kconfiglib's ISC license, covers those two files.
