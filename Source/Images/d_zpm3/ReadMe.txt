This is a generic ZPM3 adaptation for RomWBW.

There are two ways to launch ZPM3.  First, you can run the command
CPMLDR from a CP/M 2.2 or Z-System command line.  Alternatively, you
boot directly into ZPM3 by choosing the ZPM3 disk from the RomWBW
loader prompt.  The ZPM3 disk must be bootable in this case.

You may notice that there is a ZPMLDR application on the hard disk
image.  This application is equivalent to CPMLDR.  It originally
had some issues that prevented it from booting RomWBW properly,
but those issues are now resolved (I think).  Either ZPMLDR or CPMLDR
can be used to launch ZPM3.

I have not found a way to make ZPM3 start up with any drive other
than A: as the system drive.  So, during the load process, the boot
drive and drive A: are "swapped" so that the boot drive is always
drive A:.  Use the ASSIGN command after starting ZPM3 to see how the
drives get mapped.

Per ZPM3 standard, files are distributed across different user areas
depending on their usage.  Normal applications are in user 15.  Help
files in user 10.  Configuration files in user 14.

In addition to the applications provided in the ZPM3 distribution, the
normal CP/M 3 files are included in user area 15.  A few typical ZCPR
utility programs are also included in user area 15:

 - ALIAS
 - ARUNZ
 - ERASE
 - HELPC (named ZHELP)
 - LBREXT
 - SALIAS
 - SETPATH
 - VERRROR
 - VLU
 - ZCNFG
 - ERASE (named ZERASE)
 - ZEX
 - ZFILER
 - ZP
 - SHOW (named ZSHOW)
 - ZXD
 - EDITNDR
 - SAVENDR
 - SDZ

It is a bit confusing, but the ZPM3 system file is called CPM3.SYS.
This is the ZPM3 default configuration and I guess it is done this
way to maximize compatibility with CP/M 3.  You will notice that the
startup banner will indicate ZPM3.

In 2015, Jon Saxton released a patched version of ZPM3.  The changes
are documented in ZPM3FIX.TXT in the RomWBW distribution in the
Source/ZPM3 directory.  RomWBW uses the patched version of
ZPM3.  However, Jose Luis discovered that named directories do not
work properly with these patches (see RomWBW GitHub Issue #324). I have
subsequently added a small patch to correct this.  The original
unpatched copies of RESBDOS.SPR and BNKBDOS.SPR are included in the 
RomWBW build directory for ZPM3 as RESBDOS.SPR.bak and 
BNKBDOS.SPR.bak.  If you want to revert to the unpatched release of 
ZPM3, just overlay RESBDOS.SPR and BNKBDOS.SPR with the .bak variants 
and regenerate RomWBW.

jduraes reported an inconsistency between the key bindings for the
built-in ZPM3 command line editing vs the key functions documented
in ZPM3.TXT.  Refer to RomWBW Issue https://github.com/wwarthen/RomWBW/issues/533.

When Jon Saxton implemented a his patches to ZPM3, he also updated
the command line history to function a bit more like one would typically
expect (see ZPM3FIX.TXT).  Part of this change included swapping the
functions of ^W and ^X for WordStar compatibility:

Old	New	Function
^A	^A	one word left
^B	^B	to beginning/end of line
^C	^C	reboot if at start of line
^D	^D	right one char
^E	^E	get previous line
^F	^F	right one word
^G	^G	delete char at cursor
^H	^H	destructive backspace
^I	^I	(TAB) ignored here
^J	^J	(LF) exit editor
^K	^K	delete all to the right
^L	^L	ignored
^M	^M	(CR) exit editor
^N	^N	ignored
^O	^O	ignored
^P	^P	toggle printer echoing
^Q	^Q	toggle autoprompt (if enabled)
^R	^R	ignored
^S	^S	left one char
^T	^T	delete word at cursor
^U	^U	add line to history
^V	^V	clear line, delete from history
^W	^X	get next line from history
^X	^W	delete all to the left
^Y	^Y	clear line
