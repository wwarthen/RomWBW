This directory contains the source and assembled versions of the
ZSystem Clock Drivers for RomWBW HBIOS.

The wbwclk.z80 source file can be compiled using Build.cmd which will
produce a relocatable binary (hbclk.rel).

The relocatable binary should be added/updated in the STAMPS.DAT
library.  The STAMPS.DAT file is just a standard LU type library and
is easily updated using NULU.  The members are the relocatable
binaries, but with the .REL extension removed.

SETUPZST is used to create runnable executable (.COM) files.  An
executable has been created for DateStamper (LDDS.COM), P2DOS
(LDP2D.COM), and NZTime (LDNZT.COM) .  The executables are all
configured for operation as an RSX (resident system extension).

The STAMPS.DAT file here is a version that I cobbled together.  Using
the STAMPS.DAT file included in the ZSDOS distribution results in a
load file that does not work.  It claims to load, but is not
present.  I found a "fixed" version of STAMPS.DAT on the Walnut Creek
CD-ROM which works, but was missing the NZ and NZP2 stamp variants.
So, I added those variants to the working version of STAMPS.DAT which
is included here.
