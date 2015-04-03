This directory contains the source and assembled versions of the ZSystem Clock Drivers for N8VEM HBIOS.

The hbclk.z80 source file can be compiled using Build.cmd which will produce a relocatable binary (hbclk.rel).

The relocatable binary should be added/updated in the stamps.dat libary.  The stamps.dat file is just a standard LU type library and is easily updated using NULU.  The members are the relocatable binaries, but with the .REL extension removed.

SETUPZST is used to create runnable executable (.COM) files.  An executable has been created for DateStamper (LDDS.COM) and P2DOS (LDP2D.COM).  The executables are all configured for operation as an RSX (resident system extension).
