
===== Z3PLUS Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with
RomWBW.  It contains Z3PLUS, which is an implementation of the
Z-System.  You may also see Z3PLUS referred to as ZCPR 3.4.  This is
a powerful replacement for CP/M 3.

The disk is bootable as is (the operating system image is already
embedded in the system tracks) and can be launched from the RomWBW
Loader prompt.  See the Usage and Notes sections below for more
information on how Z3PLUS is loaded.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
User Guide.pdf" document found in the Doc directory of the
RomWBW Distribution.

The primary documentation for Z3PLUS is the "Z3PLUS Users Manual.pdf"
document  contained in the Doc/CPM directory of the RomWBW distribution.
This document is a supplement to the primary documentation.  Additionally,
please review the file called RELEASE.NOT on this disk which contains
a variety of updates regarding the Z3PLUS distribution.

The starting point for the disk content was the final official release of
Z3PLUS which is generally available on the Internet.  A minimal
system generation was done just sufficient to get Z3PLUS to run under
RomWBW.  Z3PLUS is extremely configurable and far more powerful than
DRI CP/M.  It is almost mandatory that you read the Z3PLUS manual to
use the system effectively.

== Usage ==

Z3PLUS is not designed to load directly from the boot tracks of a
disk.  Instead, it expects to be loaded from an already running
OS.  This disk has been configured to boot using CP/M 3 with a
PROFILE.SUB command file that automatically loads Z3PLUS.  So, Z3PLUS
will load completely without any intervention, but you may notice
that CP/M 3 loads first, then CP/M 3 loads Z3PLUS.  This is normal.

== Configration ==

Z3PLUS is distributed in an unconfigured state.  The following was
done to create a ready-to-run setup for RomWBW:

  - Created PROFILE.SUB to launch Z3PLUS at startup.
  - Created STARTZ3P.COM (alias) with
	Z3PLUS /Q
  	PATH /C $$$$ A15 A0
  - Replaced DEFAULT.Z3T (IN Z3PLUS.LBR) with VT100 Term Definiton:
  - Replaced DEFAULT.NDR (IN Z3PLUS.LBR) with new directory names:
  	A0:SYSTEM  A10:HELP  A14:CONFIG  A15: ROOT
  - Copied ARUNZ.COM to CMDRUN.COM
  - Added REN, SAVE, and SP commands to ALIAS.CMD

== Notes ==

One of the bigger changes when deploying this image was the consoliadation
of Files between NZCOM and Z3PLUS. Both of these distributions came
from the same vendor and share the Same DNA, the primary difference being the
underlying OS (and BDOS) being eithe CP/M 2.2 (NZCOM) or CP/M 3 (Z3PLUS)

Thus a new "Common/NZ3PLUS" folder was created and sharded files
move here, to avoid significant duplication. This was done with NZ-COM files (primarily)
to ensure backwards compatability, and any improvements (done in NZ-COM) stick.

Carried over from the NZCOM Changes
  - Extract VT100 TCAP from Z3TCAP.LBR and saved it as TCAP.Z3T.
  - Original TCSELECT.COM was removed and replaced with a newer version
    from the Z3 files. TCAP.LBR and Z3TCAP.TCP were removed and replaced with
    Z3TCAP.LBR from new TCSELECT distribution.
  - Updated HELP.COM to search for help files in A10: instead of A15:
  - Updated LBRHELP.COM to search for help files in A10: instead of A15:

Files Moved
  - Moved all help and documentation files to 10: per ZCPR3 conventions
  - Moved DOCFILES.LBR to 10:
  - Moved all TCJ files to 10:
  - Moved all configuration files to 14: per ZCPR3 conventions
  - Moved executables to 15: per ZCPR3 conventions

Files Removed because newer versions are already included:
  - COPY.COM
  - CRUNCH.COM
  - UNCRUNCH.COM
  - LBREXT.COM
  - ZCNFG.COM

== Files ==

For a description of the files contained in this disk please see the
"Rom WBW Disk Catalog.pdf" document contained in the Doc directory
of the RomWBW distribution.

===========================================

== Suggestions ==

Some of the files currenty in A15 (NZCOM and Z3PLUS) look more like they
should be in A0, as they are part of system definition / config
rather than a general purpose utility .e.g.
  - ALIAS.CMD - this one in particular contains config
  - CMDRUN.COM - effectivly config since it is a copy of one of 2 files
  - ?????
