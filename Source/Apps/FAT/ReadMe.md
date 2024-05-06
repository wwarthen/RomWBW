# RomWBW HBIOS CP/M FAT Utility ("FAT.COM")

Author: Wayne Warthen \
Updated: 6-May-2024

This application allows copying files between CP/M filesystems and FAT 
filesystems (DOS, Windows, Mac, Linux, etc.).  The application runs on 
RomWBW hosted CP/M (and compatible) operating systems. The application 
also has limited file management capabilities on FAT filesystems 
including directory listing, renaming, deleting, and sub-directory 
creation.

### Usage:

```
  FAT DIR <path>
  FAT COPY <src> <dst>
  FAT REN <from> <to>
  FAT DEL <path>[<file>|<dir>]
  FAT MD <path>
  FAT FORMAT <drv>
```

  CP/M filespec: \<d\>:FILENAME.EXT (\<d\> is CP/M drive letter A-P) \
  FAT filespec:  \<u\>:/DIR/FILENAME.EXT (\<u\> is disk unit #)

### Notes:

 - Partitioned or non-partitioned media is handled automatically.
   A floppy drive is a good example of a non-partitioned FAT
   filesystem and will be recognized.  Larger media will typically
   have a partition table which will be recognized by the
   application to find the FAT filesystem.
   
 - Although RomWBW-style CP/M media does not know anything about
   partition tables, it is entirely possible to have media that
   has both CP/M and FAT file systems on it.  This is accomplished
   by creating a FAT filesystem on the media that starts on a track
   beyond the last track used by CP/M.  Each CP/M slice can occupy
   up to 8MB.  So, make sure to start your FAT partition beyond
   (slice count) * 9MB.

 - The application infers whether you are attempting to reference
   a FAT or CP/M filesystem via the drive specifier (char before ':').
   A numeric drive character specifies the HBIOS disk unit number
   for FAT access.  An alpha (A-P) character indicates a CP/M
   file system access targeting the specified drive letter.  If there
   is no drive character specified, the current CP/M filesystem and
   current CP/M drive is assumed.  For example:
   
   `2:README.TXT` refers to FAT file README.TXT on disk unit #2 \
   `C:README.TXT` refers to CP/M file README.TXT on CP/M drive C: \
   `README.TXT` refers to CP/M file README.TXT on current CP/M drive
   
 - FAT files with SYS, HIDDEN, or R/O attributes are not given
   any special treatment.  Such files are found and processed
   like any other file.  However, any attempt to write to a
   read-only file will fail and the application will abort.
 
 - It is not currently possible to reference CP/M user areas other
   than the current user.  To copy files to alternate user areas,
   you must switch to the desired user number first or use an
   additional step to copy the file to the desired user area.
   
 - Accessing FAT filesystems on a floppy requires the use of
   RomWBW HBIOS v2.9.1-pre.13 or greater.

 - Only the first 8 RomWBW disk units (0-7) can be referenced.
   
 - Files written are not verified.
 
 - Wildcard matching in FAT filesystems is a bit unusual as
   implemented by FatFs.  See FatFs documentation.

 - The `FAT FORMAT` command will not perform a physical format on
   floppy disks.  You must use FDU to do this prior to using
   `FAT FORMAT`.

 - Formatting (`FAT FORMAT`) of floppies does not work well.  The    
   underlying FatFs library uses some non-standard fields.  The 
   resulting floppy may or may not be useable on other systems.  It is 
   best to format a FAT floppy on a Windows or DOS system.  You should 
   have no problems copying files to/from such a floppy using `FAT`.

### Known Issues

 - CP/M (and workalike) OSes have significant restrictions on filename
   characters.  The FAT application will block any attempt to create a
   file on the CP/M filesystem containing any of these prohibited
   characters:

|         `< > . , ; : ? * [ ] |/ \`

   The operation will be aborted with "`Error: Invalid Path Name`" if such
   a filename character is encountered.

   Since MS-DOS does allow some of these characters, you can have
   issues when copying files from MS-DOS to CP/M if the MS-DOS filenames
   use these characters.  Unfortunately, FAT is not yet smart enough to
   substitute illegal characters with legal ones.  So, you will need to
   clean the filenames before trying to copy them to CP/M.

 - The FAT application does try to detect the scenario where you are
   copying a file to itself.  However, this detection is not perfect and
   can corrupt a file if it occurs.  Be careful to avoid this.

### License:

  GNU GPLv3 (see file LICENSE.txt)

### Build Notes:

 - Source is maintained on GitHub at <https://github.com/wwarthen/FAT>.

 - Application is based on FatFs.  FatFs source is included.  See
   <http://elm-chan.org/fsw/ff/>.

 - SDCC compiler v4.3 or greater is required to build.  New calling
   conventions introduced in v4.3 are assumed.

 - See Build.cmd for sample build script under Windows.  References
   to SDCC must be updated for your environment.
   
 - Note that ff.c (core FatFs code) generates quite a few compiler
   warnings (all appear to be benign).

### To Do:

 - Allow ^C to abort any operation in progress.
 
 - Allow referencing more than the first 8 RomWBW disk units.
 
 - Handle wildcards in destination, e.g.:

   `FAT REN 2:/*.TXT 2:/*.BAK`
 
 - Do something intelligent with R/O and SYS file attributes
 
 - Support UNA
 
### History:

| Date        | Version | Notes                                                       |
|------------:|-------- |-------------------------------------------------------------|
| 2-May-2019  | v0.9    | (beta) initial release                                      |
| 7-May-2019  | v0.9.1  | (beta) added REN and DEL                                    |
| 8-May-2019  | v0.9.2  | (beta) handle file collisions w/ user prompt                |
| 8-Oct-2019  | v0.9.3  | (beta) fixed incorrect filename buffer size (MAX_FN)        |
| 10-Oct-2019 | v0.9.4  | (beta) upgraded to FatFs R0.13c                             |
| 10-Oct-2019 | v0.9.5  | (beta) added MD (make directory)                            |
| 10-Oct-2019 | v0.9.6  | (beta) added FORMAT                                         |
| 11-Oct-2019 | v0.9.7  | (beta) fix FORMAT to use existing partition table entries   |
|             |         | add attributes to directory listing                         |
| 12-Apr-2021 | v0.9.8  | (beta) support CP/NET drives                                |
| 12-Oct-2023 | v0.9.9  | (beta) handle updated HBIOS Disk Device call                |
| 6-Jan-2024  | v1.0.0  | updated to latest FsFat (v0.15)                             |
|             |         | updated to latest SDCC (v4.3)                               |
| 6-May-2024  | v1.1.0  | improve floppy format boot record                           |
