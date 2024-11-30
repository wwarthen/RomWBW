===== NZ-COM Disk for RomWBW =====

This disk is one of several ready-to-run disks provided with
RomWBW.  It contains NZ-COM, which is an implementation of the
Z-System.  You may also see NZ-COM referred to as ZCPR 3.4.  This is
a powerful replacement for CP/M 2.2 w/ full backward compatibility.

The disk is bootable as is (the operating system image is already
embedded in the system tracks) and can be launched from the RomWBW
Loader prompt.  See the Usage and Notes sections below for more
information on how NZ-COM is loaded.

The remainder of this document describes the usage and contents of
this disk.  It is highly recommended that you review the "RomWBW
User Guide.pdf" document found in the Doc directory of the
RomWBW Distribution.

The primary documentation for NZ-COM is the "NZCOM Users Manual.pdf"
document  contained in the Doc/CPM directory of the RomWBW distribution.
This document is a supplement to the primary documentation.  Additionally,
please review the file called RELEASE.NOT on this disk which contains
a variety of updates regarding the NZ-COM distribution.

The starting point for the disk content was the final official release of
NZ-COM which is generally available on the Internet.  A minimal
system generation was done just sufficient to get NZ-COM to run under
RomWBW.  NZ-COM is extremely configurable and far more powerful than
DRI CP/M.  It is almost mandatory that you read the NZ-COM manual to
use the system effectively.

== Usage ==

NZ-COM is not designed to load directly from the boot tracks of a
disk.  Instead, it expects to be loaded from an already running
OS.  This disk has been configured to boot using ZSDOS with a
PROFILE.SUB command file that automatically loads NZ-COM.  So, NZ-COM
will load completely without any intervention, but you may notice
that ZSDOS loads first, then ZSDOS loads NZ-COM.  This is normal.

*** TODO: Date stamping ***

== Notes ==

NZ-COM is distributed in an unconfigured state.  The following was
done to create a ready-to-run setup for RomWBW:

  - Ran MKZCM and saved default configuration to NZCOM.ZCM and
    NZCOM.ENV.
  - Extract VT100 TCAP from Z3TCAP.LBR and saved it as TCAP.Z3T.
  - Created PROFILE.SUB to launch NZCOM at startup.
  - Original TCSELECT.COM was removed and replaced with a newer version
    from the Z3 files.
  - TCAP.LBR and Z3TCAP.TCP were removed and replaced with
    Z3TCAP.LBR from new TCSELECT distribution.
  - Z3LOC.COM and LBREXT.COM were removed because more recent
    versions are provided from Common files.
  - Replaced ZRDOS with ZSDOS in NZCOM.LBR.  The standalone
    ZRDOS.ZRL and ZSDOS.ZRL files were saved.
  - Copied ARUNZ.COM to CMDRUN.COM
  - Moved all configuration files to 14: per ZCPR3 conventions
  - Moved all help and documentation files to 10: per ZCPR3 conventions
  - Moved executables to 15: per ZCPR3 conventions
  - Updated HELP.COM to search for help files in A10: instead of A15:
  - Updated LBRHELP.COM to search for help files in A10: instead of A15:
  - Updated STARTZCM with
  	ZPATH /C=A0:,$$:,A15: /D=A0:,A15:
	NZCOM TCAP.Z3T
  - Updated NZCOM.NDR in NZCOM.LBR with new directory names:
  	A  0: SYSTEM    A 10: HELP      A 14: CONFIG    A 15: ROOT
  - Moved DOCFILES.LBR to 10:
  - Moved all TCJ files to 10:
  - Added REN, SAVE, and SP commands to ALIAS.CMD

The following additional customizations were also performed:

  - The following files from the original distribution were removed
    because newer versions are included:

    - COPY.COM
    - CRUNCH.COM
    - LBREXT.COM
    - TCSELECT.COM
    - UNCRUNCH.COM
    - Z3LOC.COM
    - ZCNFG.COM

While including Z3PLUS disk image the SHOW.COM and HELP.COM
files were renamed to ZSHOW.COM and ZHELP.COM for consistency
with Z3PLUS, and ZPM3

== NZ-COM Files ==

For a description of the files contained in this disk please see the
"Rom WBW Disk Catalog.pdf" document contained in the Doc directory
of the RomWBW distribution.

-- WBW 7:14 PM 8/17/2024
