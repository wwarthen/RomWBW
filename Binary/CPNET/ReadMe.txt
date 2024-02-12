***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory contains the CP/NET client packages.  Please refer to 
the RomWBW User Guide for instructions on installing these packages.  
Either the MT011 RCBus module or the Duodyne Disk I/O board is required.

All of these files come from Douglas Miller.  Please refer to
https://github.com/durgadas311/cpnet-z80 for more information, complete
documentation and the latest source code.  Refer to the RomWBW
User Guide for basic installation and usage instructions under RomWBW.

| File         | CP/NET Version | OS       | Hardware              |
+--------------+----------------+----------+-----------------------+
| CPN12MT.LBR  | CP/NET 1.2     | CP/M 2.2 | RCBus w/ MT011        |
| CPN3MT.LBR   | CP/NET 3       | CP/M 3   | RCBus w/ MT011        |
| CPN12DUO.LBR | CP/NET 1.2     | CP/M 2.2 | Duodyne w/ Disk I/O   |
| CPN3DUO.LBR  | CP/NET 3       | CP/M 3   | Duodyne w/ Disk I/O   |

In general, to use CP/NET on RomWBW, it is intended that you will
extract the appropriate set of files into your default directory in
user area 0.  Refer to the RomWBW User Guide for more information.

The libraries include enhanced help files appropriate for the version 
of CP/NET.  Rename the desired topic collection to HELP.HLP on the
target system.

CPM2NET.HLP	CP/M 2.2 basic system with CP/NET 1.2
CPNET12.HLP	CP/NET 1.2 help only
CPM3NET.HLP	CP/M 3 basic system with CP/NET 3
CPNET3.HLP	CP/NET 3 help only

-- WBW 7:14 AM 2/11/2024