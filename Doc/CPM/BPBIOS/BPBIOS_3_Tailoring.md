# 3 Tailoring a B/P Bios

To customize a B/P Bios for your use, or adapt it to a new hardware set, you will need an editor and an assembler capable of producing standard Microsoft Relocatable files. Systems using the Hitachi HD64180 or Zilog Z180 must be assembled with either ZMAC or SLR180 which recognize the extended mnemonic set, or with a Z80 assembler and MACRO file which permits assembly of the extended instructions. For Z80 and compatible processors, suitable assemblers include ZMAC and Z80ASM. For any assembler, failure to produce standard Microsoft Relocatable code will preclude the ability of our Standard utilities to properly install B/P Bios systems.


## 3.1 Theory of Operation

In order to understand the need for, and principles behind B/P Bios, you must understand the way in which CP/M 2.2, as modified by the Z-System, uses the available memory address space of a Z80 microprocessor. For standard versions of CP/M and compatible systems, the only absolute memory addresses are contained in the Base Page which is the range of 0 to 100H. All addresses above this point are variable (within certain limits). User programs are normally run from the Transient Program Area (TPA) which is the remaining space after all Operating System components have been allocated. The following depicts the assigned areas pictorially along with some common elements assigned to each memory area:

```generic
FFFFH /------------------\
      | Z-System Buffers |   ENV, TCAP, IOP, FCP, RCP
      |------------------|
      |       Bios       |   Code + ALV, CSV, Sector Buffers
      |------------------|
      | Operating System |   CP/M 2.2, ZRDOS, ZSDOS1
      |------------------|
      | Command Processor|   CCP, ZCPR3.x
      |------------------|
      |   Transient      |
      |                  |
      |      Program     |
      |                  |
      |          Area    |
0100H |------------------|
      |    Base Page     |   IOBYTE, Jmp WB, Jmp Dos, FCB, Buffer
0000H \------------------/
```

As more and more functionality was added to the Z-System Buffers, bigger drives were added using more ALV space, and additional functionality was added to Bios code in recent systems, the available TPA space has become increasingly scarce.

B/P Bios attacks this problem at the source in a manner which is easily adaptable to different hardware platforms. It uses additional memory for more than the traditional role of simple RAM Disks, it moves much of the added overhead to alternate memory banks. The generic scheme appears pictorially as:

```generic
FFFFH /----------\
      |          |
      |   BNK1   |
      |          |
8000H |----------| /----------\    /----------\   /----------\
      |          | |          |\   |          |\  |          |\
      |   BNK0   | |   BNK2   |    |   BNKU   |   |   BNK3   ||\
      |          | |          ||   |          ||  |          |||
0000H \----------/ \----------/    \----------/   \----------/
                    \- - - - - /    \- - - - - /   \- - - - - /|
                                                    |   BNKM   |
                                                    \----------/
          TPA         SYSTEM           USER          RAM DISK
```

As can be seen from the above diagram, multiple banks of memory may be assigned to different functional regions of memory, with each 32k bank (except for the one defined as BNK1) being switched in and out of the lower 32k of the processor's memory map. The bank defined as BNK1 is ALWAYS present and is referred to as the Common Bank. This bank holds the portions of the Operating System (Command Processor, Operating System, BIOS, and Z-System tables) which may be accessed from other areas, and which therefore must always be "visible" in the processor's memory. It also contains the code to control the Bank switching mechanisms within the B/P Bios.

To illustrate this functional division, the memory map of a basic B/P Bios system is divided as:

```generic
FFFFH /------------------\
      | Z-System Buffers |
      |------------------|
      |    User Space    |
      |------------------|
      |       Bios       |
      |------------------|
      | Operating System |
      |------------------|
      | Command Processor|   /------------------\ 8000H
      |------------------| / |   Bios Buffers   |
8000H |   Transient      |   | Banked Bios Part |
      |                  |   |------------------|
      |                  |   | Banked Dos Part  |
      |      Program     |   |------------------|
      |                  |   | Banked CCP Part  |
      |                  |   |------------------|
      |          Area    |   |  CCP Restoral    |
0100H |------------------|   |------------------| 0100H
      |    Base Page     |   |  Base Page Copy  |
0000H \------------------/   \------------------/ 0000H
        TPA (BNK0/BNK1)       System Bank (BNK2)
```

The B/P Bios banking concept defines a one byte Bank Number permitting up to 8 Megabytes to be directly controlled. Certain assumptions are made in the numbering scheme, the foremost of which is that BNK0 is the lowest physical RAM bank, BNK1 is the next incremental RAM bank, with others follow in incrementing sequential order. A couple of examples may serve to illustrate this process. The YASBEC is offered with a couple of options in the Memory Map. Units with the MEM-1, 2 or 3 decoder PALs assign the first 128k bytes of physical memory to the Boot ROM, so BNK0 is set to 4 (Banks 0-3 are the ROM). The MEM-4 PAL only uses the first 32k (Physical Bank 0) for the ROM which means that BNK0 is assigned to 1, BNK1 to 2 and so on up to the 1 Megabyte maximum where BNKM is 31.

The Ampro Little Board equipped with MDISK, on the other hand, completely removes the Boot ROM from the memory map leaving a maximum of 1 MB of contiguous RAM space. In this system, BNK0 is set to 0 and BNKM to 31 of a fully equipped 1 MB MDISK board.

The region beginning after BNK1 is referred to as the System Bank. It begins at the bank number assigned to BNK2 and ends at the bank number immediately before that assigned to the User Bank, BNKU if present, or BNK3 if no User Bank area is defined.

If present, one or more 32k banks of memory may be defined with the BNKU equate for unique user programs or storage areas. This area begins with the bank number set to the label and ends at the bank number immediately before the BNK3 label. BNK3 defines a high area of physical memory which is most often used for a RAM Disk providing fast temporary workspace in the form of an emulated disk drive.

B/P Bios contains protection mechanisms in the form of software checks to insure that critical portions of the memory map are enforced. In the case of Non-banked systems, a check is made to insure that the system size is not so great that the Bios may overwrite reserved Z-System areas in high memory (RCP, IOP, etc). If a possible overflow condition is detected, the message

`++ mem ovfl ++`

will be issued when the system is started. In Banked Bios systems, this message will be displayed if the top of the system portions in the SYStem Bank exceeds the 32k bank size. For most systems, this space still permits drives of several hundred megabytes to be accommodated.

Since the Common portions of the operating system components must remain visible to applications, a similar check is made to insure that the lowest address used by the Command Processor is equal to or greater than 8000H. This factor is checked both in both MOVxSYS and BPBUILD with either a warning issued in the case of the former, or validity checks on entry in the case of the latter.


## 3.2 B/P Bios Files

This BIOS is divided into a number of files, some of which depend highly on the specific hardware used on the computer, and some of which are generic and need not be edited to assemble a working system. Much use is made of conditional assembly to tailor the resulting Bios file to the desired configuration. The Basic file, `BPBIO-xx.Z80`, specifies which files are used to assemble the Bios image under the direction of an included file, `DEF-xx.LIB`. It is this file which selects features and contains the Hardware-dependent mnemonic equates. By maintaining the maximum possible code in common modules which require no alterations, versions of B/P Bios are relatively easy to convert to different machines. The independent modules used in the B/P Bios system are:

| Filename | Description |
| :--- | :--- |
| `BOOTRAM.Z80` | (only needed in BOOT ROM applications) |
| `BOOTROM.Z80` | (only needed in BOOT ROM applications) |
| `BYTEIO.Z80` | Character IO per IOBYTE using IIO-xx routines |
| `DEBLOCK.Z80` | Disk Deblocking routines |
| `DPB.LIB` | 3.5/5.25" Floppy Format Definitions (if AutoSelect) |
| `DPB8.LIB` | 8"/Hi-Density Floppy Format Definitions (if AutoSelect) |
| `DPB2.LIB` | Additional Floppy Definitions (optional if AutoSelect) |
| `DPBRAM.LIB` | Fixed Floppy Format Definitions (if Not AutoSelect) |
| `DPH.LIB` | Disk Parameter Header Table & Floppy definitions |
| `FLOPPY.Z80` | Floppy Disk High-Level Control |
| `SECTRAN.Z80` | Sector Translate routines |
| `SELFLP1.Z80` | Floppy Select routine (if Not auto selecting) |
| `SELFLP2.Z80` | Floppy Select routine (if auto selecting) |
| `SELRWD.Z80` | Generic Read/Write routines |
| `Z3BASE.LIB` | ZCPR 3.x file equate for Environment settings |

Other files are hardware version dependent to varying extents. These modules requiring customization for different hardware systems are given names which end with a generic "-xx" designator to identify specific versions. Tailoring these modules ranges from simple prompt line customization to complete re-writes. Versions of B/P Bios generated to date are identified as:

| ID | Computer system |
| :---: | :--- |
| `-18` | MicroMint SB-180 | (64180 CPU, 9266 FDC, 5380 SCSI) |
| `-YS` | YASBEC | (Z180 CPU, 1772 FDC, DP8490 SCSI) |
| `-AM` | Ampro Little Board | (Z80 CPU, 1770 FDC, 1MB MDISK) |
| `-CT` | Compu/Time S-100 board set | (Z80 CPU, 1795 FDC, 1MB Memory) |
| `-TT` | Teletek | (Z80 CPU, 765 FDC) |

Files associated with specific hardware versions or require tailoring are:

| Filename | Description |
| :--- | :--- |
| `BPBIO-xx.Z80` | Basic file, tailored for included file names |
| `CBOOT-xx.Z80` | Cold Boot routines, Sign-on prompts |
| `DEF-xx.LIB` | Equates for option settings, mode, speed, etc. |
| `DPBHD-xx.LIB` | Hard Drive Partition Definitions (optional) |
| `DPBM-xx.LIB` | Ram Drive Definition (optional) |
| `DPHHD-xx.LIB` | Hard Drive DPH definitions (optional) |
| `DPHM-xx.LIB` | Ram Drive DPH Definition (optional) |
| `FDC-xx.Z80` | Floppy Disk Low-Level interface/driver routines |
| `HARD-xx.Z80` | Hard Drive Low-Level interface/driver routines (optional) |
| `IBMV-xx.Z80` | Banking Support Routines (if banked) |
| `ICFG-xx.Z80` | Configuration file for speed, Physical Disks, etc. |
| `IIO-xx.Z80` | Character IO definitions and routines |
| `RAMD-xx.Z80` | Ram Drive interface/driver routines (optional) |
| `TIM-xx.Z80` | Counter/Timer routines and ZSDOS Clock Driver |
| `WBOOT-xx.Z80` | Warm Boot and re-initialization routines |


## 3.3 B/P Bios Options

The most logical starting point in beginning a configuration is to edit the `DEF-xx.LIB` file to select your desired options. This file is the basic guide to choosing the options for your system, and some careful choices here will minimize the Bios size and maximize your functionality. Some of the more important options and a brief description of them are:

**MOVCPM** - Integrate into MOVCPM "type" loader? If the system is to be integrated into a MOVCPM system, the Environment descriptor contained in the CBOOT routine is always moved into position as part of the Cold Start process. If set to NO, a check will be made to see if an Environment Descriptor is already loaded, and the Bios copy will not be loaded if one is present.

NOTE: When assembling a Bios for Boot Track Installation (MOVCPM set to YES), many options are deleted to conserve space and the Bios Version Number is forced to 1.1.

**BANKED** - Is this a banked BIOS? If set to YES, the Bank control module, IBMV, is included in the assembly, and much of the code is relocated to the system bank. Note that a Banked system CANNOT be placed on the System Tracks, or integrated into a MOVCPM image.

**IBMOVS** - Are Direct Inter-Bank Moves possible? If set to YES, direct transfer of data between banks is possible such as with the Zilog Z180/Hitachi 64180. If NO, a 256-byte transfer buffer is included in high Common Memory and Interbank moves require transfer of bytes through this buffer.

**ZSDOS2** - Assemble this for a Banked ZSDOS2 system? If YES, the ALV and CSV buffers will be placed in the System bank invisible to normal programs. This has the side effect that many CP/M programs which perform sizing of files (Directory Listers, DATSWEEP, MEX, etc) which do not know about this function will report erroneous sizes. The advantage is that no sacrifice in TPA is required for large Hard Disks. Set this to NO if you want strict CP/M 2.2 compatibility.

**FASTWB** - Restore the Command Processor from the System Bank RAM? If set to YES, Warm Boots will restore the Command Processor from a reserved area in the System RAM bank rather than from the boot tracks. For the maximum benefit of B/P Bios, always attempt to set this to YES. In systems without extended memory, it MUST be set to NO.

**MHZ** - Set to Processor Speed in closest even Megahertz (e.g. for a 9.216 MHz clock rate, set to 9). The value entered here is used in many systems to compute Timing values and/or serial data rate parameters.

**CALCSK** - Calculate Diskette Skew Table? If NO, a Skew table is used for each floppy format included in the image. Calculating Skew is generally more efficient from a size perspective, although slightly slower by factors which are so small as to be practically unmeasurable.

**HAVIOP** - Include IOP code into Jump table? If the IOPINIT routine satisfies your IOP initialization requirements, you may turn this off by setting to NO and save a little space. This typically will be turned off when generating a system for MOVCPM integration to conserve space.

**INROM** - Is the Alternate Bank in ROM? Set to NO for Normal Disk-based systems. Please contact the authors if you need additional information concerning ROM-based system components.

**BIOERM** - Print BIOS error messages? Set this to YES if you desire direct BIOS printing of Floppy Disk Error Messages. If you are building a BIOS for placement on Boot Tracks, however, you will probably not have room and must turn this Off. Set to NO to simply return the normal Success/Fail error flag with no Message printout.

**FLOPY8** - Include 8"/Hi-Density Floppy Formats? Some systems (SB-180, Compu/Time) can handle both 5.25" and 8" disks. If your hardware supports the capability and you want use 8" disks as well as the normal 3.5 and 5.25" diskettes, setting this to YES will add formats contained in `DPB8.LIB` and control logic to the assembly. Future systems may take advantage of the "High-Density" 3.5 and 5.25" Floppy Disks which use higher data rates. Their definitions will be controlled by this flag as well.

NOTE: If AUTOSL is set to NO, this option will probably cause the BIOS to be larger than necessary since these additional formats may not be accessible.

**MORDPB** - Use more Floppy DPB's (in addition to normal 4-5.25" and optional 8")? If YES, the file `DPB2.LIB` is included. Many of the formats are Dummies and may be filled with any non-conflicting formats you desire.

NOTE: If AUTOSL if set to NO, this option will probably cause the BIOS to be larger than necessary since these additional formats may not be accessible.

**MORDEV** - Include Additional Character Device Drivers? Is set to YES, user-defined drivers are added to the Character IO table, and associated driver code is assembled. Systems featuring expansion board such as the SB-180 and YASBEC may now take advantage of additional serial and parallel interfaces within the basic Bios. Set to NO to limit code to the basic 4 drivers.

NOTE: When assembling a Bios for Boot Track Installation (MOVCPM set to YES), MORDEV is overridden to conserve space, and the Bios Version Number is forced to 1.1 in the distribution files.

**BUFCON** - Use type ahead buffer for the Console? If set to YES, code is added to create and manage a type-ahead buffer for the driver assembled as the console. This device will be controlled by either interrupts (in systems such as the YASBEC and SB-180) or background polling (in Ampro and Compu/Time). This means that characters typed while the computer is doing something else will not be lost, but will be held until requested.

**BUFAUX** - Use type ahead buffer on Auxiliary Port? As with BUFCON above, setting to YES will add code to create and manage a type ahead buffer for the auxiliary device. Since the AUX port typically is used for Modem connections, buffering the input will minimize the loss of characters from the remote end.

**AUTOSL** - Auto-select floppy formats? If set to YES, selection of Floppy disks will use an algorithm in `SELFLP2.Z80` to identify the format of the disk from the DPB files included (`DPB.LIB`, optional `DPB8.LIB`, and optional `DPB2.LIB`) and log the disk if a match is found. There must be NO conflicting definitions included in the various files for this to function properly. See the notes in the various files to clarify the restrictions. If set to NO, the single file `DPBRAM.LIB` is included which may be tailored to contain only the fixed format or formats desired per disk drive. This results in the smallest code requirement, but least flexibility.

**RAMDSK** - Include code for a RAM-Disk? If set to YES, any memory above the System or User bank may be used for a RAM Drive (default is drive M:) by including the file `RAMD-xx.Z80`. Parameters to determine the size and configuration are also included in the files `DPHM-xx.LIB` and `DPBM-xx.LIB`. In systems without extended memory, or to conserve space such as when building a system for the boot tracks, this may be disabled by setting to NO.

**HARDDSK** - Include SCSI Hard Disk Driver? Set to YES if you wish to include the ability to access Hard Disk Drives. In a floppy-only system, a NO entry will minimize BIOS code.

**HDINTS** - (System Dependent) In some systems such as the YASBEC, Interrupt-driven Hard Disk Controllers using DMA transfer capabilities may be used. If you wish to use this type of driver specified in the file `HARDI-xx.Z80` instead of the normal polled routines included in `HARD-xx.Z80`, set this option to TRUE. In most cases, this driver will require more Transient Program Area since the Interrupt Handling routine must be in Common Memory.

**CLOCK** - Include ZSDOS Clock Driver Code? If set to YES, the vector at BIOS+4EH will contain a ZSDOS-compatible clock driver with the physical code contained in the `TIM-xx.Z80` module. If set to NO, calls to BIOS+4EH return an error code.

**TICTOC** - (System Dependent) Use pseudo heartbeat counter? This feature is used in systems such as the Ampro Little Board and Compu/Time SBC880 which do not have an Interrupt scheme to control a Real Time Clock. Instead, a series of traps are included in the code (Character IO Status polls, Floppy Disk Status polls) to check for overflow of a 1-Second Counter. It is less desirable than an Interrupt based system, but suffices when no other method is available. Set to NO if not needed.

**QSIZE** - Size in bytes of type ahead buffers controlled by BUFCON and BUFAUX.

**REFRSH** - Activate Dynamic Refresh features of Z180/HD64180 processors? In some computers using these processors such as the YASBEC, refresh is not needed and merely slows down processing. Set to NO if you do not need this feature. If your processor uses dynamic memory, or needs the signal for other purposes (e.g. The SB180 uses Refresh for Floppy Disk DMA), Set this to YES.

**Z3** - Include ZCPR init code? Since a Z3 Environment is mandatory in a B/P Bios (which now "owns" the Environment), this option has little effect.

For assembly of a Banked version of B/P Bios, the identification of various banks of memory must be made so that the various system components "know" where things are located. Refer to Section 3.1 above for a description of these areas. The BNK0 value should be the first bank of RAM in the System unless other decoding is done. The following equates must be set:

| Equate | Description |
| :--- | :--- |
| BNK0 | First 32k TPA Bank (switched in/out) |
| BNK1 | Second 32k TPA Bank (Common Bank) |
| BNK2 | Beginning of System Bank (BIOS, DOS, CPR) area |
| BNKU | Beginning of Bank sequence for User Applications |
| BNK3 | Beginning of Extra Banks (first bank to use for RAM Disk) |
| BNKM | Maximum Bank Number assigned |


## 3.4 Configuration Considerations

When assembling a version of B/P Bios for integration into an IMG file, size of the resulting image is not much of a concern, so you need not worry about minor issues of size. For integration into a system for loading onto diskette boot tracks, however, the limitation is very real in order to insure that the CPR/DOS/BIOS and Boot Sector(s) can fit on the reserved system tracks. Typically, a limit of slightly under 4.5k exists for the Bios component. When the MOVCPM flag is set to YES for this type of assembly, warnings will be issued when the image exceeds 4352 bytes (the maximum for systems with 2 boot records), and 4480 bytes (the maximum for systems with a single boot record). Achieving these limits often requires disabling many of the features.

The first thing you should do before assembling the BIOS is to back up the entire disk, then copy only the necessary files onto a work disk for any editing. After setting the options as desired, edit the hardware definitions in `ICFG-xx.Z80` to reflect the physical characteristics of your floppy and hard drives, as well as any other pertinent items. Then edit the logical characteristics for your Hard and Ram Drives (if any) in `DPBHD-xx.LIB` and `DPBM-xx.LIB`. If you do not desire any of the standard floppy formats or want to change them, edit `DPB.LIB` and/or `DPB2.LIB` (if using auto selection) or `DPBRAM.LIB` if you are using fixed floppy formats. Finally edit the DPH files to place the logical drives where desired in the range A..P.

Decide whether you want to generate a system using the Image file construct developed in support of B/P Bios (BPBUILD/LDSYS), or for integration on a floppy disk's boot tracks. If the latter, you probably will not be able to have all options turned on. For example, with the MicroMint SB-180, the following options must be turned Off: BANKED, ZSDOS2, BIOERM, FLOPY8, MORDPB, BUFAUX and usually either CLOCK or RAMDSK. As an aid to space reduction, conditional assembly based on the MOVCPM flag automatically inhibits all but double-sided Floppy formats from `DPB.LIB`. If configuring for Floppy Boot tracks (MOVCPM flag set to TRUE), a warning will be printed during assembly if the size exceeds that available for a One or Two-sector boot record. Using the BPBUILD/LDSYS method, you may vary nearly all system parameters, even making different systems for later dynamic loading.

If you are using a version of the B/P Bios already set for your type of computer, you are now ready to assemble, build a system and execute it. The only remaining task would be an optional tailoring of the sign on banner in the file `CBOOT-xx.Z80` and reassembly to a `.REL` file.

For those converting a standard version of the B/P Bios to a new hardware system, we recommend that you begin with a Floppy-only system in Non-Banked mode then expand from there. The easiest way to test out new versions is to use the System Image (IMG file) mode, then advance to boot track installations if that is desired. Enhancements that can be added after testing previous versions may be to add Hard Drives, RAM Drive, and finally Banking.

