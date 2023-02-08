***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This directory contains a toolset for RomWBW that builds floppy and 
hard disk media images that can be used with RomWBW by writing the 
image to a floppy or hard disk (including CF and SD cards).

In summary, CP/M files are placed inside of a pre-defined Windows 
directory structure.  A script is then run to create the floppy and 
hard disk images from the directory tree contents.  The resultant 
images may be copied directly to floppy or hard disk media or used as 
SIMH emulator disk images.
 
System Requirements
-------------------

The scripts run on Microsoft Windows XP or greater (32 and 64 bit 
variants of Windows are fine).  You will need to have Microsoft 
PowerShell installed. All variants of Windows XP and later support 
PowerShell. It is included in all versions after Windows XP.  If you 
are using Windows XP, you will need to download it from Microsoft and 
install it (free download).

Although not documented here, the Linux/Mac build process will also
create disk images using a similar process based on Makefiles.

The cpmtools toolset is used to generate the actual disk images.  
This toolset is included in the distribution, so you do not need to 
download or install it.

Preparing the Source Directory Contents
---------------------------------------

The script expects your files to be found inside a specific directory 
structure.  The structure is:

  d_xxx --+--> u0
          +--> u1
	  +--> u2
	  |    .
	  |    .
	  |    .
	  +--> u15

A given disk is represented by a directory named d_xxx where xxx can 
be anything you want.  Within the d_xxx directory, the CP/M user 
areas are represented by subdirectories named u0 thru u15. The files 
to be placed in the disk image are placed inside of the u0 thru u15 
directories depending on which user area you want the file(s) to 
appear.  You do not need to create all of the u## subdirectories, 
only the ones corresponding to the user areas you want to put files in.

To build all the disk images, you run the Build.cmd batch file from a 
command prompt.  Build.cmd in turn invokes a separate script to create 
each floppy and hard disk image.

As distributed, you will see that there are several d_ directories 
populated with files.  If you look at the Build.cmd script, you will 
find that the names of each of these directories is listed.  If you 
want to add a new d_ directory to be converted into a disk image, you 
will need to add the name of your new directory to this list.  Note 
that each d_ directory may be turned into a floppy image or a hard 
disk image or both.
 
At present, the scripts assume that the floppy media is 1.44MB.  You 
will need to modify the scripts if you want to create different media.

The resultant disk images (.img files) can be written to the start of
a disk using your Windows/Linux/Mac computer and will then be usable
in your RomWBW computer.  On Windows, you can use Win32DiskImager to
do this (see Tools\Win32DiskImager).  On Linux/Mac, you can usee dd.

WARNING: The hd1k disk images must be prefixed by the 
hd1k_prefix.dat file before being written to your target media.  
See the Hard Disk Formats section below for more information.

Building the Images
-------------------

The image creation process simply traverses the directory structures 
described above and builds a raw disk image for each floppy disk or 
hard disk.  Note that cpmtools is used to generate the images and is 
included in the distribution under the Tools directory.

Many of the disk images depend upon files that are produced by
building the shared components of RomWBW.  Prior to running
the Build command in the Images directory, you should first
run the BuildShared command in the Source directory.  This produces
several files that are prerequisites for creating the disk images.

The scripts are intended to be run from a command prompt.  Open a 
command prompt and navigate to the Images directory.  Use the command
"Build" to build both the floppy and hard disk images in one run.
You can build a single disk image by running BuildDisk.cmd:

    BuildDisk <disk> <type> <format> [<system>]

where:

    <disk> specifies the disk contents (e.g., "cpm22")
    <type> specifies disk type ("fd" for floppy, or "hd" for hard disk)
    <format> specifies the disk format which must be one of:
        - "fd144": 1.44M floppy disk
	- "hd512": hard disk with 512 directory entries
	- "hd1k": hard disk with 1024 directory entries
    <system> optionally specifies a boot system image to place in the
        system tracks of the disk (e.g., "..\cpm22\cpm_wbw.sys"

For example:

  | BuildDisk.cmd cpm22 hd wbw_hd512 ..\cpm22\cpm_wbw.sys

will create a hard disk image (512 directory entry format) with the
CP/M 2.2 files from the d_cpm22 directory tree and will place the
CP/M 2.2 system image in the boot system tracks.

After completion of the script, the resultant image files are placed 
in the Binary directory with names such as fd144_xxx.img, hd512_xxx.img,
and hd1k_xxx.img.

Sample output from running Build.cmd is provided at the end of
this file.

Be aware that the script always builds the image files from scratch.  
It will not update the previous contents. Any contents of a 
pre-existing image file will be overwritten.

Slices
------

A RomWBW CP/M filesystem is fixed at 8MB.  This is because it is the 
largest size filesystem supported by all common CP/M variants. Since 
all modern hard disks (including SD Cards and CF Cards) are much 
larger than 8MB, RomWBW supports the concept of "slices".  This 
simply means that you can concatenate multiple CP/M filesystems (up 
to 256 of them) on a single physical hard disk and RomWBW will allow 
you to assign drive letters to them and treat them as multiple 
independent CP/M drives.

The disk image creation scripts in this directory will only create a 
single CP/M file system (i.e., a single slice).  However, you can 
easily create a multi-slice disk image by merely concatenating 
multiple images together (the 1024 directory entry format requires a
prefix file, see below).  For example, if you wanted to create a 2 
slice disk image that has ZSDOS in the first slice and WordStar in 
the second slice, you could use the following command from a Windows 
command prompt:

  | C:\RomWBW\Binary>copy /b hd512_zsdos.img + hd512_ws4.img hd_multi.img

You can now write hd_multi.img onto your SD or CF Card and you will 
have ZSDOS in the first slice and Wordstar in the second slice.

The concept of slices applies only to hard disks.  Floppy disks are 
not large enough to support multiple slices.

Hard Disk Formats
-----------------

RomWBW supports two hard disk formats: the original format used by 
RomWBW with 512 directory entries per slice and a new format with 
1024 directory entries per slice.  These formats are referred to as
hd512 and hd1k respectively.  You will note that filenames start 
with either hd512_ or hd1k_ to indicate the hard disk format.

WARNING: You **can not** mix the two hard disk formats on one hard 
disk device.  You can use different formats on different hard disk 
devices in a single system though.

RomWBW determines which of the hard disk formats to use for a given 
hard disk device based on whether there is a RomWBW hard disk 
partition on the disk containing the slices.   If there is no RomWBW 
partition, then RomWBW will assume the 512 directory entry format for 
all slices and will assume the slices start at the first sector of 
the hard disk.  If there is a RomWBW partition on the hard disk 
device, then RomWBW will assume the 1024 directory entry format for 
all slices and will assume the slices are located in the defined 
partition.  You cannot mix the hard disk formats on a single disk
device.

WARNNG: The hd1k_xxx.img files (not hd1k_combo.img) **must** be 
prefixed by a partition table before being written to your disk media.  
The hd1k_prefix.dat file is provided for this.  The hd1k_prefix.dat 
defines the required partition table.  Any number of hd1k slice images 
can be concatenated after the prefix.  For example, to make the 
hd1k_cpm22.img file ready to write to your media, you would need to do 
something like this:

  | C:\RomWBW\Binary>copy /b hd1k_prefix.dat + hd1k_cpm22.img hd_cpm22.img
  
and then use the resulting hd_cpm22.img to write to the target media.

For example, if you wanted to create a 2 slice disk image using the 
hd1k entry format that has ZSDOS in the first slice and Wordstar in 
the second slice, you could use the following command from a Windows 
command prompt:
 
  | C:\RomWBW\Binary>copy /b hd1k_prefix.dat + hd1k_zsdos.img + hd1k_ws4.img hd_multi.img

Since the hd512 format does not utilize a partition, you do not
prefix the hd512_xxx.img files with anything.  They are ready to write
to your media as is.

In general, the hd1k format is considered the better format to use. 
It provides double the directory space and places all slices inside 
of a hard disk partition that DOS/Windows should respect as "used" 
space.

Disk Images
-----------

The standard RomWBW build process builds the disk images defined
in this directory.  The resultant images are placed in the Binary
directory and are ready to copy to your media.

Additionally, a "combo" disk image is created in both the hd512 and
hd1k formats that contains a multi-slice image that is handy to
use for initial testing.  The combo disk image contains the following
slices:

  | Slice 0: CP/M 2.2 (bootable)
  | Slice 1: ZSDOS 1.1 (bootable)
  | Slice 2: NZCOM (bootable), requires configuration
  | Slice 3: CP/M 3 (bootable)
  | Slice 4: ZPM3 (bootable)
  | Slice 5: WordStar 4

A description of the specific image files is found in the file
called DiskList.txt in the Binary directory of the distribution.

NOTE: The hd1k_combo.img file is already prefixed with 
hd1k_prefix.dat, so you do not need to add the prefix file.  It is 
ready to write to your media.

Sample Run
----------

Below is sample output from building the hard disk images:

C:\Users\Wayne\Projects\RBC\Build\RomWBW\Source\Images>Build.cmd

  | Building Floppy Disk Images...
  | 
  | Generating cpm22 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_cpm22.img d_cpm22/u0/*.* 0:
  | cpmcp -f wbw_fd144 fd144_cpm22.img d_cpm22/u1/*.* 1:
  | cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_fd144 fd144_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_fd144 fd144_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_fd144 fd144_cpm22.img Common/*.* 0:
  | Moving image fd144_cpm22.img into output directory...
  | Generating zsdos 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_zsdos.img d_zsdos/u0/*.* 0:
  | cpmcp -f wbw_fd144 fd144_zsdos.img d_zsdos/u1/*.* 1:
  | cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_fd144 fd144_zsdos.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_fd144 fd144_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_fd144 fd144_zsdos.img Common/*.* 0:
  | Moving image fd144_zsdos.img into output directory...
  | Generating nzcom 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_nzcom.img d_nzcom/u0/*.* 0:
  | cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_fd144 fd144_nzcom.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_fd144 fd144_nzcom.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_fd144 fd144_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_fd144 fd144_nzcom.img Common/*.* 0:
  | Moving image fd144_nzcom.img into output directory...
  | Generating cpm3 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_cpm3.img d_cpm3/u0/*.* 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/ccp.com 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/gencpm.com 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/genres.dat 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/genbnk.dat 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bios3.spr 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bdos3.spr 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/resbdos3.spr 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3res.sys 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3bnk.sys 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/gencpm.dat 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3.sys 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/readme.1st 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../CPM3/cpm3fix.pat 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_fd144 fd144_cpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_fd144 fd144_cpm3.img Common/*.* 0:
  | Moving image fd144_cpm3.img into output directory...
  | Generating zpm3 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u0/*.* 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u10/*.* 10:
  | cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u14/*.* 14:
  | cpmcp -f wbw_fd144 fd144_zpm3.img d_zpm3/u15/*.* 15:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zpmldr.com 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zpmldr.sys 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/autotog.com 15:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/clrhist.com 15:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/setz3.com 15:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/cpm3.sys 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zccp.com 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/zinstal.zpm 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/startzpm.com 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/makedos.com 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/gencpm.dat 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../ZPM3/resbdos3.spr 0:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/*.com 15:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_fd144 fd144_zpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_fd144 fd144_zpm3.img Common/*.* 15:
  | Moving image fd144_zpm3.img into output directory...
  | Generating ws4 1.44MB Floppy Disk...
  | cpmcp -f wbw_fd144 fd144_ws4.img d_ws4/u0/*.* 0:
  | Moving image fd144_ws4.img into output directory...
  | 
  | Building Hard Disk Images (512 directory entry format)...
  | 
  | Generating cpm22 Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_cpm22.img d_cpm22/u0/*.* 0:
  | cpmcp -f wbw_hd512 hd512_cpm22.img d_cpm22/u1/*.* 1:
  | cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd512 hd512_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd512 hd512_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_hd512 hd512_cpm22.img Common/*.* 0:
  | Moving image hd512_cpm22.img into output directory...
  | Generating zsdos Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_zsdos.img d_zsdos/u0/*.* 0:
  | cpmcp -f wbw_hd512 hd512_zsdos.img d_zsdos/u1/*.* 1:
  | cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd512 hd512_zsdos.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd512 hd512_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_hd512 hd512_zsdos.img Common/*.* 0:
  | Moving image hd512_zsdos.img into output directory...
  | Generating nzcom Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_nzcom.img d_nzcom/u0/*.* 0:
  | cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd512 hd512_nzcom.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd512 hd512_nzcom.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_hd512 hd512_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_hd512 hd512_nzcom.img Common/*.* 0:
  | Moving image hd512_nzcom.img into output directory...
  | Generating cpm3 Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_cpm3.img d_cpm3/u0/*.* 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/ccp.com 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/gencpm.com 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/genres.dat 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/genbnk.dat 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bios3.spr 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bdos3.spr 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/resbdos3.spr 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3res.sys 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3bnk.sys 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/gencpm.dat 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3.sys 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/readme.1st 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../CPM3/cpm3fix.pat 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd512 hd512_cpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd512 hd512_cpm3.img Common/*.* 0:
  | Moving image hd512_cpm3.img into output directory...
  | Generating zpm3 Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u0/*.* 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u10/*.* 10:
  | cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u14/*.* 14:
  | cpmcp -f wbw_hd512 hd512_zpm3.img d_zpm3/u15/*.* 15:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zpmldr.com 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zpmldr.sys 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/autotog.com 15:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/clrhist.com 15:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/setz3.com 15:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/cpm3.sys 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zccp.com 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/zinstal.zpm 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/startzpm.com 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/makedos.com 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/gencpm.dat 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../ZPM3/resbdos3.spr 0:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/*.com 15:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd512 hd512_zpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd512 hd512_zpm3.img Common/*.* 15:
  | Moving image hd512_zpm3.img into output directory...
  | Generating ws4 Hard Disk (512 directory entry format)...
  | cpmcp -f wbw_hd512 hd512_ws4.img d_ws4/u0/*.* 0:
  | Moving image hd512_ws4.img into output directory...
  | 
  | Building Combo Disk (512 directory entry format) Image...
  | ..\..\Binary\hd512_cpm22.img
  | ..\..\Binary\hd512_zsdos.img
  | ..\..\Binary\hd512_nzcom.img
  | ..\..\Binary\hd512_cpm3.img
  | ..\..\Binary\hd512_zpm3.img
  | ..\..\Binary\hd512_ws4.img
  |         1 file(s) copied.
  | 
  | Building Hard Disk Images (1024 directory entry format)...
  | 
  | Generating cpm22 Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_cpm22.img d_cpm22/u0/*.* 0:
  | cpmcp -f wbw_hd1k hd1k_cpm22.img d_cpm22/u1/*.* 1:
  | cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd1k hd1k_cpm22.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd1k hd1k_cpm22.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_hd1k hd1k_cpm22.img Common/*.* 0:
  | Moving image hd1k_cpm22.img into output directory...
  | Generating zsdos Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_zsdos.img d_zsdos/u0/*.* 0:
  | cpmcp -f wbw_hd1k hd1k_zsdos.img d_zsdos/u1/*.* 1:
  | cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd1k hd1k_zsdos.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd1k hd1k_zsdos.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_hd1k hd1k_zsdos.img Common/*.* 0:
  | Moving image hd1k_zsdos.img into output directory...
  | Generating nzcom Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_nzcom.img d_nzcom/u0/*.* 0:
  | cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd1k hd1k_nzcom.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd1k hd1k_nzcom.img ../CPM22/cpm_wbw.sys 0:cpm.sys
  | cpmcp -f wbw_hd1k hd1k_nzcom.img ../ZSDOS/zsys_wbw.sys 0:zsys.sys
  | cpmcp -f wbw_hd1k hd1k_nzcom.img Common/*.* 0:
  | Moving image hd1k_nzcom.img into output directory...
  | Generating cpm3 Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_cpm3.img d_cpm3/u0/*.* 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/ccp.com 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/gencpm.com 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/genres.dat 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/genbnk.dat 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bios3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bdos3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/resbdos3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3res.sys 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3bnk.sys 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/gencpm.dat 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3.sys 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/readme.1st 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../CPM3/cpm3fix.pat 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/*.com 0:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd1k hd1k_cpm3.img Common/*.* 0:
  | Moving image hd1k_cpm3.img into output directory...
  | Generating zpm3 Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u0/*.* 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u10/*.* 10:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u14/*.* 14:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img d_zpm3/u15/*.* 15:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zpmldr.com 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zpmldr.sys 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../CPM3/cpmldr.com 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../CPM3/cpmldr.sys 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/autotog.com 15:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/clrhist.com 15:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/setz3.com 15:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/cpm3.sys 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zccp.com 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/zinstal.zpm 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/startzpm.com 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/makedos.com 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/gencpm.dat 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/bnkbios3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/bnkbdos3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../ZPM3/resbdos3.spr 0:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/*.com 15:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Tunes/*.pt? 3:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img ../../Binary/Apps/Tunes/*.mym 3:
  | cpmcp -f wbw_hd1k hd1k_zpm3.img Common/*.* 15:
  | Moving image hd1k_zpm3.img into output directory...
  | Generating ws4 Hard Disk (1024 directory entry format)...
  | cpmcp -f wbw_hd1k hd1k_ws4.img d_ws4/u0/*.* 0:
  | Moving image hd1k_ws4.img into output directory...
  |         1 file(s) copied.
  | 
  | Building Combo Disk (1024 directory entry format) Image...
  | hd1k_prefix.dat
  | ..\..\Binary\hd1k_cpm22.img
  | ..\..\Binary\hd1k_zsdos.img
  | ..\..\Binary\hd1k_nzcom.img
  | ..\..\Binary\hd1k_cpm3.img
  | ..\..\Binary\hd1k_zpm3.img
  | ..\..\Binary\hd1k_ws4.img
  |         1 file(s) copied.
