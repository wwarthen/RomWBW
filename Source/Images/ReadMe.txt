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
create disk images using an equivalent process using a Makefile.

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

You will see that for each of the d_xxx directories, there is a
corresponding hd_xxx.txt file and usually also an fd_xxx.txt file.
These .txt files contain supplemental instructions for creating
the image.  For each of the fd_xxx.txt and hd_xxx.txt files, the
build process will generate a binary file system image.

The resultant disk images (.img files) can be written to the start of
a disk using your Windows/Linux/Mac computer and will then be usable
in your RomWBW computer.  On Windows, you can use Win32DiskImager to
do this (see Tools\Win32DiskImager).  On Linux/Mac, you can usee dd.

The fd_xxx.txt and hd_xxx.txt files may contain the following:

 - File specifications of additional files to add to the image in
   addition to the d_ directory contents.
 - An @Label directive to specify the label to apply to the image.
 - An @SysImage directory to specify the boot system binary to
   place in the boot tracks of the image.

At present, the scripts assume that the floppy media is 1.44MB.  You 
will need to modify the scripts if you want to create different media.

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
"Build" to build all of the disk images including both hard disk
and floppy images.

After completion of the script, the resultant image files are placed 
in the Binary directory with names such as fd144_xxx.img, hd512_xxx.img,
and hd1k_xxx.img.

Be aware that the script always builds the image files from scratch.  
It will not update the previous contents. Any contents of a 
pre-existing image file will be overwritten.

Hard Disk Slices
----------------

A RomWBW CP/M filesystem is fixed at 8MB.  This is because it is the 
largest size filesystem supported by all common CP/M variants. Since 
all modern hard disks (including SD Cards and CF Cards) are much 
larger than 8MB, RomWBW supports the concept of "slices".  This 
simply means that you can concatenate multiple CP/M filesystems (up 
to 256 of them) on a single physical hard disk and RomWBW will allow 
you to assign drive letters to them and treat them as multiple 
independent CP/M drives.

The disk image creation scripts in this directory will create a 
single CP/M file system (i.e., a single slice).  However, you can 
easily create a multi-slice disk image by merely concatenating 
multiple images together (the 1024 directory entry format requires a
prefix file, see below).  For example, if you wanted to create a 2 
slice disk image that has ZSDOS in the first slice and WordStar in 
the second slice, you could use the following command from a Windows 
command prompt:

  | C:\RomWBW\Binary>copy /b hd512_zsdos.img + hd512_wp.img hd_multi.img

You can now write hd_multi.img onto your SD or CF Card and you will 
have ZSDOS in the first slice and Wordstar in the second slice.

The concept of slices applies only to hard disks.  Floppy disks are 
not large enough to support multiple slices.

The build process will create aggregate hard disk images automatically
based on the .def files found in the directory.  You will see a file
called combo.def which contains a list of the slices to concatenate
to create the hd512_combo.img and hd1k_combo.img files.  You may
create your own .def files to define your own hard disk aggregates.
The build script will automatically find the .def files and build
aggregates for each.  For each .def file, both hd512 and hd1k
format aggregates are created.

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
 
  | C:\RomWBW\Binary>copy /b hd1k_prefix.dat + hd1k_zsdos.img + hd1k_wp.img hd_multi.img

Since the hd512 format does not utilize a partition, you do not
prefix the hd512_xxx.img files with anything.  You can simply
concatenate the desired hd512_xxx.img files together and write the
resulting file to the start of your hard disk media.

In general, the hd1k format is considered the preferred format to use. 
It provides double the directory space and places all slices inside 
of a hard disk partition that DOS/Windows should respect as "used" 
space.

Aggregate Hard Disk Images
--------------------------

The standard RomWBW build process builds the disk images defined
in this directory.  The resultant images are placed in the Binary
directory and are ready to copy to your media.

Additionally, a "combo" aggregate disk image is created in both the 
hd512 and hd1k formats that contains a multi-slice image that is handy 
to use for initial testing.  The combo disk image contains the 
following slices:

  | Slice 0: CP/M 2.2 (bootable)
  | Slice 1: ZSDOS 1.1 (bootable)
  | Slice 2: NZCOM (bootable), requires configuration
  | Slice 3: CP/M 3 (bootable)
  | Slice 4: ZPM3 (bootable)
  | Slice 5: WordStar 4

Aggregate disk images are defined using .def files.  You will see there
is a combo.def file in the directory that defines the slices for the
Combo disk image.  You can create your own .def files as desired to
automatically create custom aggregate disk images.  There is an example
of this in the directory called all.def.example.  You can remove the
".example" suffix to cause this aggregate to be built.  This example
creates an aggregate with all of the possible slices.

NOTE: The hd1k_combo.img file is already prefixed with 
hd1k_prefix.dat, so you do not need to add the prefix file.  It is 
ready to write to your media.
