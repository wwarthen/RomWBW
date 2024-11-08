This is a generic CP/M 3 adaptation for RomWBW.

There are two ways to launch CP/M 3.  First, you can run the command
CPMLDR from a CP/M 2.2 or Z-System command line.  Alternatively, you can
boot directly into CP/M 3 by choosing the CP/M 3 disk from the RomWBW
loader prompt.  The CP/M 3 disk must be bootable in this case.

With the following exceptions, the files in this directory came from
the CP/M 3 binary distribution on "The Unofficial CP/M Web site" at
http://www.cpm.z80.de/binary.html.

The included files have been
patched with all applicable DRI patches per CPM3FIX.PAT.

ZSID.COM is the original DRI ZSID distribution, but patched to use 
RST 6 instead of RST 7 to avoid conflicting with mode 1 interrupts.

CP/M 3 is now fully Year 2000 compliant. This affects the programs
DATE.COM, DIR.COM and SHOW.COM.

Dates can be displayed in US, UK or Year-Month-Day format. This is set by
SETDEF:

Press RETURN to Continue
      SETDEF [US]
      SETDEF [UK]
      SETDEF [YMD]  respectively.

The CCP has a further bug fix: A command sequence such as:

  C1
  :C2
  :C3

will now not execute the command C3 if the command C1 failed.
