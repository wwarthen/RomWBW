This is a generic CP/M 3 adaptation for RomWBW.

There are two ways to launch CP/M 3.  First, you can run the command
CPMLDR from a CP/M 2.2 or Z-System command line.  Alternatively, you
boot directly into CP/M 3 by choosing the CP/M 3 disk from the RomWBW
loader prompt.  The CP/M 3 disk must be bootable in this case.

With the following exceptions, the files in this directory came from
the CP/M 3 binary distribution on "The Unofficial CP/M Web site" at
http://www.cpm.z80.de/binary.html.

As documented in the "README.1ST" file, the included files have been
patched with all applicable DRI patches per CPM3FIX.PAT.

In addition, the following have been added:

- INITDIR.COM was not included.  The copy included is the original
  DRI distribution, with both patches installed.

- ZSID.COM is the original DRI ZSID distribution, but patched to use 
  RST 6 instead of RST 7 to avoid conflicting with mode 1 interrupts. 