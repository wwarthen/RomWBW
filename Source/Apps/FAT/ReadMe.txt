RomWBW HBIOS CP/M FAT Utility ("FAT.COM")

Author: Wayne Warthen
Updated: 12-Apr-2021

Application to manipulate and exchange files with a FAT (DOS)
filesystem.  Runs on any HBIOS hosted CP/M implementation.

USAGE:
  FAT DIR <path>
  FAT COPY <src> <dst>
  FAT REN <from> <to>
  FAT DEL <path>[<file>|<dir>]
  FAT MD <path>
  FAT FORMAT <drv>

  CP/M filespec: <d>:FILENAME.EXT (<d> is CP/M drive letter A-P)
  FAT filespec:  <u>:/DIR/FILENAME.EXT (<u> is disk unit #)
	
LICENSE:
  GNU GPLv3 (see file LICENSE.txt)

NOTES:
 - Partitioned or non-partitioned media is handled automatically.
   A floppy drive is a good example of a non-partitioned FAT
   filesystem and will be recognized.  Larger media will typically
   have a partition table which will be recognized by the
   application to find the FAT filesystem.
   
 - Although RomWBW-style CP/M media does not know anything about
   partition tables, it is entirely possible to have media that
   has both CP/M and FAT file systems on it.  This is accomplished
   by creating a FAT filesystem on the media that starts on a track
   beyond the last track used by CP/M.  Each CP/M slice on a
   media will occupy a little over 8MB.  So, make sure to start
   your FAT partition beyond (slice count) * 8MB.

 - The application infers whether you are attempting to reference
   a FAT or CP/M filesystem via the drive specifier (char before ':').
   A numeric drive character specifies the HBIOS disk unit number
   for FAT access.  An alpha (A-P) character indicates a CP/M
   file system access targeting the specified drive letter.  If there
   is no drive character specified, the current CP/M filesystem and
   current CP/M drive is assumed.  For example:
   
   "2:README.TXT" refers to FAT file README.TXT on disk unit #2
   "C:README.TXT" refers to CP/M file README.TXT on CP/M drive C
   "README.TXT" refers to CP/M file README.TXT on current CP/M drive
   
 - FAT files with SYS, HIDDEN, or R/O only attributes are not given
   any special treatment.  Such files are found and processed
   like any other file.  However, any attempt to write to a
   read-only file will fail and the application will abort.
 
 - It is not currently possible to reference CP/M user areas other
   than the current user.  To copy files to alternate user areas,
   you must switch to the desired user number first or use an
   additional step to copy the file to the desired user area.
   
 - Accessing FAT filesystems on a floppy requires the use of
   RomWBW HBIOS v2.9.1-pre.13 or greater.
   
 - Files written are not verified.
 
 - Wildcard matching in FAT filesystems is a bit unusual as
   implemented by FatFs.  See FatFs documentation.

BUILD NOTES:
 - Source is maintained on GitHub at https://github.com/wwarthen/FAT

 - Application is based on FatFs.  FatFs source is included.

 - SDCC compiler is required to build (v4.0.0 known working).

 - ZX CP/M emulator is required to build (from RomWBW distribution).

 - See Build.cmd for sample build script under Windows.  References
   to SDCC and ZX must be updated for your environment.
   
 - Note that ff.c (core FatFs code) generates quite a few compiler
   warnings (all appear to be benign).

TO DO:
 - Allow ^C to abort any operation in progress.
 
 - Handle wildcards in destination, e.g.:
     "FAT REN 2:/*.TXT 2:/*.BAK"
 
 - Do something intelligent with R/O and SYS files on FAT
 
 - Support UNA
 
HISTORY:
   2-May-2019: v0.9   (beta) initial release
   7-May-2019: v0.9.1 (beta) added REN and DEL
   8-May-2019: v0.9.2 (beta) handle file collisions w/ user prompt
   8-Oct-2019: v0.9.3 (beta) fixed incorrect filename buffer size (MAX_FN)
  10-Oct-2019: v0.9.4 (beta) upgraded to FatFs R0.13c
  10-Oct-2019: v0.9.5 (beta) added MD (make directory)
  10-Oct-2019: v0.9.6 (beta) added FORMAT
  11-Oct-2019: v0.9.7 (beta) fix FORMAT to use existing partition table entries
                             add attributes to directory listing
  12-Apr-2021: v0.9.8 (beta) support CP/NET drives
		      
