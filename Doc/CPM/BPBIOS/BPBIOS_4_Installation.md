# 4 Installing a B/P Bios

The Distribution diskette(s) on which B/P Bios is furnished are configured for booting from the vanilla hardware for the version ordered. A 9600 bps serial terminal is standard, and will allow you to immediately bring up a minimal Non-Banked Floppy Disk system. Due to the variety of different system configurations and size restrictions in some versions, only the Floppy Disk Mass Storage capability can be assured on the initial boot disk. Where space remained on the boot tracks, limited Hard Drive support is also provided, and in some configurations, even RAM Drive support exists.

After booting from either an established system, or the boot tracks of the distribution disk, format one or more fresh diskettes and copy the distribution diskette(s) contents to the backup diskette(s). Copy the boot tracks from the master to the copies using BPSYSGEN (see 6.6). Remove the master diskette(s) for safekeeping and work only with the copies you just made.

Using the backup diskette with the B/P utilities on it, execute BPCNFG in the Boot Track configuration mode (see 6.2), adjusting all the options to your specific operating environment. When you have completed tailoring the system, it is ready for booting by placing the diskette in drive A: and resetting the system.

The sample `STARTUP.COM` file on the distribution disk will automatically execute a sequence of instructions when the system is booted. It contains various instructions which further tailor the system and load portions of the operating system which are too big to fit on the boot tracks. The default instruction sequence is:

| Command | Explanation |
| :--- | :--- |
| `LDDS`                        | Load the DateStamper style File Stamp routine and clock |
| `LDR SYS.RCP,SYS.FCP,SYS.NDR` | Load ZCPR 3 Environment segments for Resident Command Processor, Flow Control Pkg and Named Dirs |
| `IOPINIT`                     | Initialize the IO Processor Pkg |
| `TD S`                        | Prompt for Date and Time, Set Clk / Alternatives are to use `TDD` (6.21) or `SETCLOK` (6.18) |
| `IF ~EX MYTERM.Z3T`           | If the file `MYTERM.Z3T` does Not exist... |
| `TCSELECT MYTERM.Z3T`         | ..select which terminal you have creating a `MYTERM.Z3T` file |
| `FI`                          | ...end of the `IF` |
| `LDR MYTERM.Z3T`              | Load the Terminal Definition data |

If you wish to alter any of these initial instructions to, for example, initialize the RAM drive using INIRAMD, add File Time Stamp capabilities to it with INITDIR or PUTDS and copy some files there with COPY, these may be added with ALIAS, VALIAS, SALIAS or other compatible files available from the ZSYSTEM or ZCPR33 areas on Z-Nodes.

After the initial system is up and running from the Default Boot Track system, you may expand the operation by generating systems for different purposes in order to gain the most advantage from your system. Many types of installation are possible, the simplest of which is a Non-Banked system using only 64k of the systems memory, all of which is in primary memory. Such a system uses a normal Command Processor such as the ZCPR3.x family, and a Non-Banked Operating System such as our ZSDOS Version 1. Non-Banked systems may be installed on a Disk's Boot Tracks, or created as an Image File for dynamic loading using the LDSYS Utility (see 6.15).

Banked systems MUST be created with the BPBUILD Utility (see 6.1) and loaded with LDSYS (see 6.15). The techniques to manage different memory banks to form a complete Operating Environment are rather intricate and are best handled by our utilities. Many Image files may be created and loaded as needed to tailor your system for optimum performance. The following sections describe these various types of installations in detail.


## 4.1 Boot Track Installation

For most of the existing CP/M compatible computers to begin executing a Disk Operating System, a program must be placed on a specified area of a Floppy or Hard Disk Drive. Normally, the first two or three tracks on the disk are reserved for this purpose and are referred to as the "Boot Tracks". Since the space so defined is generally restricted, neither a complete B/P Bios nor a Banked installation is possible. Instead, a scaled-down system roughly equivalent to those currently in use is used to start the computer and serve as the Operating System, with larger systems loaded later as needed.

If you are using a pre-configured version of B/P Bios for your hardware, you may simply continue to use the Boot Track system from the distribution disk(s) by copying the system as described in Section 4 above using BPSYSGEN (see 6.6). If you elect to alter or otherwise customize the Boot Track system, you must assemble the B/P Bios source setting certain of the equates in the `DEF-xx.LIB` file to insure a correct type of system. To assemble a Boot Track system, the most important equates are:

| Equate |  |
| :---: | :--- |
| `MOVCPM` | Set to `YES` |
| `BANKED` | Set to `NO` |
| `ZSDOS2` | Set to `NO` |

One element of Banked Systems is available in a Boot Track installation if additional memory is available, and your B/P Bios routines support such a feature. This feature reloads the Command Processor from Banked memory instead of from the Boot Tracks of a disk, and generally produces less code (taking less space on the Boot Tracks) and executes faster. It is set with:

| Equate |  |
| :---: | :--- |
| `FASTWB` | Set to `YES` if desired, `NO` if Warm Boot from disk |

Some of the features that generally need to be disabled to scale a smaller system are set as:

| Equate |  |
| :---: | :--- |
| `MORDPB` | Set to `NO` |
| `DPB8`   | Set to `NO` |
| `MORDEV` | Set to `NO` |

When at least these equates and any others you desire to change (see section 4) have been made to the component files of the system, assemble your `BPBIO-xx` file to a Microsoft standard `.REL` file. This output file may be used to overlay the Bios portion of the `MOVxSYS.COM` system generation utility (see 6.16) furnished with your distribution disk, or an equivalent program provided with your computer. MOVxSYS or its equivalent (MOVCPM, MOVZSYS, etc) is a special program customized for your particular hardware containing all the Operating System components which will be placed on the Boot Tracks, along with a routine to alter the internal addresses to correspond to a specified memory size.

To Add the new Bios you just assembled, execute INSTAL12 (see procedures in 6.13) specifying your computer's MOVxSYS or equivalent program and follow the prompts to overlay the new Bios. Once INSTAL12 has saved a relocatable or absolute file, you are ready to create a boot disk containing the modified system.

If you used the command INSTAL12 to install system segments on MOVxSYS or equivalent program, you must first create an Absolute System Model file. Since the functional portion of your new program is identical to the original MOVxSYS or equivalent, use the method explained in your original documentation to generate a new system. With MOVxSYS, the command is:

| Command |  |
| :---: | :--- |
| `MOVxSYS nn *` | replace MOVxSYS with your version |

Where `nn` is the size of the system (typically 51 for a moderate boot system). The asterisk tells the program to retain the image in memory and not write it to a disk file. You may now use BPSYSGEN to write the new image to the system tracks of your boot diskette. Do this by executing BPSYSGEN with no arguments and issue a single Carriage Return when asked for the source of the Image.

If you used the command `INSTAL12 /A` to install replacement system segments over a System Image file, or used a utility which wrote the new image to a disk file, use BPSYSGEN to write the image file to the system tracks of your boot disk. The proper command is

`BPSYSGEN filename`

where filename is the name of the disk file you just created by executing MOVxSYS or equivalent with output to a disk file, or with INSTAL12 on an existing image file.

If the system is written to a Hard Disk, and your system supports booting from a Hard Disk such as the YASBEC, you normally must alter the default Boot Sector from the default Floppy Disk Boot Sector contained in MOVxSYS or equivalent. This alteration is accomplished by HDBOOT (see 6.9) which must be customized to the specific Hardware System used.

After the above actions have been completed as appropriate, tailor the Boot Track system to reflect the desired starting configurations with BPCNFG (see 6.2). Such items as the desired Startup file name, Bank Numbers (critical if FASTWB is used), and drive types and assignments are routinely tailored at this point. When the you have finished this step, test your new system by resetting the system, or cycling the power and you should be up and running!


## 4.2 Non-Banked Image Installation

A Non-Banked system may be installed as an Image File as opposed to the basic Boot Track installation covered in 4.1 above. To create an Image File, you must have `.REL` or `.ZRL` versions of a Command Processor (ZCPR3.x or equivalent recommended), an Operating (`ZSDOS.ZRL` recommended), and a REL version of B/P Bios for your system assembled with the MOVCPM equate in `DEF-xx.LIB` set to NO. Other equates in this file may be set as described above for the Boot Track system. Since Image Files are not as constrained in size as is installation for Boot Tracks, more features may generally be activated such as Error Messages, RAM Drive, additional Hard Drive partitions, and complete Floppy Format suites. The main precaution here is that large Hard Drives will rapidly cause significant loss of Transient Program Area since all Drive parameters must be in protected high memory above the Bios.

After the Bios has been assembled, an Image file must be produced. This is accomplished with the BPBUILD Utility (see 6.1). Set the File names in Menu 1 to reflect only Non-Banked files (or minimally banked Bios if FASTWB is set to YES), and let BPBUILD do the work. Since the standard Non-Banked System segments are normally set to the "standard" CP/M 2.2 sizes, you may answer the "autosize" query with a Y to obtain the maximum Transient Program Area in the resulting system. When BPBUILD completes its work, a file, normally with the default type of `.IMG`, will have been placed in the currently logged Drive/User area and you are ready to perform the next step in preparation of the Non-Banked Image.

As with the Boot Track installation covered above, several system items must be tailored before the Image may be safely loaded and executed. This is done by calling BPCNFG with the Image file name as an argument, or specify Image configuration from the interactive menu (see 6.2). Set all items as you desire them in the operating system, particularly the Bank Numbers (if FASTWB is active), and the Disk Drive characteristics and assignments. When this has been satisfactorily completed, you are ready to load and execute the newly-created system.

Installing an Image File (default file type of `.IMG`) is extremely easy. Only the utility `LDSYS.COM` (see 6.15) is needed. If the file type has not been changed from the default `.IMG`, only the basic name of the Image File need be passed to LDSYS when executed as:

| Command |  |
| :---: | :--- |
| `LDSYS IMGFILE` | where IMGFILE.IMG is your Image file name |

The operating parameters of the currently-executing system are first examined for suitability of loading the Image File. If it is possible to proceed, the Image File is loaded, placed in the proper memory locations, and commanded to begin execution by calling the B/P Bios Cold Boot Vector. The Cold Boot (Bios Function 0) performs final installation, displays any desired opening prompt and transfers control to the Command Processor with any specified Startup file for use by a ZCPR3.x Command Processor Replacement.

Since a non-banked Image File will probably closely resemble that contained on the Boot Tracks, the same STARTUP file may generally be used to complete the initial tailoring sequence. If a different file is desired, the Image File may be altered to specify a different file using BPCNFG.


## 4.3 Banked Bios, Non-banked System Installation

With the B/P Bios system, an Image system may be created and loaded which places portions of the Bios Only in the System bank, retaining a non-banked Operating System and therefore maximum compatibility with existing applications software. A few thousand bytes can normally be reclaimed for Transient Programs in this manner, although large and/or increasing numbers of logical drives will still reduce TPA space because of the need to store Allocation Vector information in Common Memory.

To prepare such a system, simply edit the needed Bios files if necessary with particular emphasis on the `DEF-xx.LIB` file where the following equates must be set as:

| Equate |  |
| :---: | :--- |
| `MOVCPM` | Set to `NO` |
| `BANKED` | Set to `YES` |
| `ZSDOS2` | Set to `NO` |

Since banked memory MUST be available for this type of installation, you will probably want the Fast Warm Boot feature available to maximize system performance. To activate this option, set the following equate as:

| Equate |  |
| :---: | :--- |
| `FASTWB` | Set to `YES` |

When the editing is complete, assemble the Bios to a Microoft `.REL` file with an appropriate assembler such as ZMAC and build an Image system with BPBUILD (see 6.1) changing the Bios file name in menu 1 to the name of the newly created Bios file. Next, configure the default conditions if necessary with BPCNFG (see 6.2) and you are ready to activate the new system in the same manner as all Image files by calling LDSYS with the Image file argument as:

| Command |  |
| :---: | :--- |
| `LDSYS BBSYS` | where BBSYS.IMG is your Image File Name |

As with the completely Non-Banked system described above in Section 4.2, no new requirements are established for a Startup file over that used for the initial Boot System, since both the Command Processor and Disk Operating System are unbanked, and no data areas needed by application programs are placed in the System Bank. As with all Image Files, additional features such as full Bios Error Messages, more extensive Floppy Disk Formats and RAM drive may generally be included in the System definition prior to assembly since the size constraints of Boot Track systems do not apply.


## 4.4 Fully Banked Image Installation

To create a system taking maximum advantage of banked memory, a special banked Operating System and Command Processor are needed. These have been furnished in initial form with this package as `ZSDOS20.ZRL` and `Z40.ZRL` respectively. They use the Banking features of B/P Bios and locate the maximum practicable amount of executable code and data in the System Bank. Of significant importance to maximizing the Transient Program Area is that the Drive Allocation Bit maps are placed in the System Bank meaning that adding large hard drives, or multiple drives produce only minimal expansion to the resident portion of the Bios.

NOTE: The latest versions are `ZS203.ZRL`, `ZS227G.ZRL`, and `Z41.ZRL` as included in the public release of B/P Bios. See also sections 7 and 8.

A Fully banked Bios is created by editing the B/P Bios files as needed to customize the system to your desires. Insure that the following `DEF-xx.LIB` equates are set as:

| Equate |  |
| :---: | :--- |
| `MOVCPM` | Set to `NO` |
| `BANKED` | Set to `YES` |
| `ZSDOS2` | Set to `YES` |

Assemble the resultant B/P Bios to a Microsoft `.REL` file, Build an Image file with BPBUILD (see 6.1) and configure the produced Image file with BPCNFG (see 6.2). When you are confident that all default settings have been made, activate the file by entering:

| Command |  |
| :---: | :--- |
| `LDSYS FBANKSYS` | where FBANKSYS.IMG is your Image File Name |

Several differences may exist in the Startup file used for a Fully banked system. Generally the changes amount to deleting items such as a File Stamp module for the Non-banked ZSDOS1 which is not necessary with the fully-banked ZSDOS 2 and Z40. Only the type of clock need be specified for ZSDOS2. Furthermore, since the Z40 Command Processor Replacement contains most commonly-used commands gathered from a number of Resident Command Processor (RCP) packages, there is normally no need to load an RCP. A simple Startup file found adequate during development of the fully-banked B/P system is:

| Command | Explanation |
| :--- | :--- |
| `ZSCFG2 CB`           | Set ZSDOS 2 clock to Bios+4EH |
| `LDR SYS.FCP,SYS.NDR` | Load ZCPR 3 Environment segments for Flow Control and Named Dirs |
| `IOPINIT`             | Initialize the IO Processor Pkg |
| `TD S`                | Prompt for Date and Time, Set Clk / Alternatives are to use `TDD` (6.21) or `SETCLOK` (6.18) |
| `IF ~EX MYTERM.Z3T`   | If the file `MYTERM.Z3T` does Not exist... |
| `TCSELECT MYTERM.Z3T` | ..select which terminal you have creating a `MYTERM.Z3T` file |
| `FI`                  | ...end if the `IF` |
| `LDR MYTERM.Z3T`      | Load the Terminal Definition data |

Since the requirements for a fully-banked system differ significantly from a non-banked one, we recommend that you use a different name for the Startup file. For example, `STARTUP.COM` is the default name used with Boot Track systems for initial operation, and with Non-banked Image Files, while STARTB may be a suitable name for the script to be executed upon loading a fully-banked system. The name of the desired Startup file may be easily altered in either Boot Track or Image systems from Option 1 in BPCNFG (see 6.2).

An option available to start from a large Image File is to configure a Startup file for execution by the Boot Track system containing a single command. The command would simply invoke LDSYS with the desired Banked Image File as an argument such as:

| Command |  |
| :---: | :--- |
| `LDSYS BANKSYS` | where BANKSYS.IMG is your Image file |

In this case, none of the normal initialization sequences cited above would be executed by the Boot Track system, and only those contained in the Startup for `BANKSYS.IMG` would occur. Other options abound and are left to the community to invent new combinations and sequences.


## 4.5 In Case of Problems...

While We attempted to outline procedures for the majority of installations we considered feasible, there may be occasions where you inadvertently find yourself in a position where you seem to have lost the ability to get your system up and running.

**PROBLEM:** When loading an `.IMG` file with LDSYS, the screen displays the LDSYS banner, system addresses, and halts with the last screen displaying: "...loading banked system".

_SOLUTION:_ Something is not set correctly in the Bios, since all lines after the last one displayed are printed from the newly-loaded Bios. One of the most common causes for this problem is incorrect bank number settings. Use the hidden selection in Menu 1 of BPCNFG (see 6.2) to verify that the correct bank numbers have been set for TPA and SYStem banks. Another common cause of this problem is incorrect settings for the Console port, or a setting in the IOBYTE which directs Console data to a device other than the one intended. Use Menu 2 BPCNFG to properly set the IOBYTE and the console parameters.

**PROBLEM:** You boot from or load a B/P Bios system from a Hard Drive, and immediately after starting, the system attempts to log onto Floppy Drive 0.

_SOLUTION:_ The most common cause for this symptom is that the desired Hard Drive and Floppy Drive definitions were not swapped to define a Hard Drive Partition as the A: drive. Use BPCNFG (see 6.2), Menu 5 to exchange drives to the desired configuration. A similar situation may exist where a Hard Drive is activated immediately after booting when a Floppy drive is desired as the A: Drive.

**PROBLEM:** The computer seems to boot satisfactorily, but after a few programs or any program which executes a Warm Boot (or entering Control-C), the system goes into "Never-never Land" and must be reset.

_SOLUTION:_ This symptom is most often caused by an inability to access and load the Command Processor. This is most probably caused by assembling B/P Bios with the FASTWB equate in `DEF-xx.LIB` set to YES when the system contains no extended memory, or incorrect settings of the Bank Numbers. To check Bank Number settings, use the hidden function in BPCNFG, Menu 1 (see 6.2).

**PROBLEM:** When doing a Cold Boot from a Hard Drive (from Power up or Reset), the system goes to a Floppy Drive before displaying the initial sign on messages, and remains logged on the Floppy.

_SOLUTION:_ This is most often due to your forgetting to run the HDBOOT utility on the Hard Drive Boot system after applying it with BPSYSGEN. Normally, systems created with MOVxSYS contain a Floppy Disk Boot sector which will load the initial Operating System from a Floppy. HDBOOT (see 6.9) modifies this record on a specified Hard Drive Unit so that the Operating System is loaded from a Hard Drive. Run HDBOOT on the Desired Hard Drive, then use BPCNFG (see 6.2) to insure that the logical drives are positioned as desired (Menu 5).

**PROBLEM:** When Booting, the system console either doesn't display anything, or prints strange characters.

_SOLUTION:_ This is most often due to incorrect settings for the current Console, most probably the Data rate, or CPU Clock Frequency. Boot from a good system, then use BPCNFG (see 6.2) to adjust the settings on the problem system. Pay particular attention to Menu 1 (CPU Clock Rate) and Menu 2 (IOBYTE and Serial Port Data Rates).

**PROBLEM:** When running a fully-banked system with ZSDOS 2, some programs seem to "hang" or "lock up" the system on exit.

_SOLUTION:_ One of the most common sources of this symptom is with the application program where the author used code which assumes that the BDOS and Command Processor are of a certain size, or bear a fixed relationship to the addresses in page 0. You may experience this most often when using an IMG system built by answering YES to the Autosizing query in BPBUILD (see 6.1). To compensate for such ill-behaved programs, you may use a two-step build process as:

1. Use BPBUILD to create an IMG file answering YES to Autosizing on exit. This maximizes TPA placing the Resident Bios as high as possible in memory.

2. Execute BPBUILD again with an argument of the name you gave to the file just created above. This loads the definition from the IMG file. Immediately exit with a Carriage Return, and answer NO to Autosizing, and YES to placing system segments at standard locations. This procedure keeps the Bios address constant, but will move the starting addresses of BDOS and Command Processor down, if possible, to simulate "standard" sizes used in CP/M 2.2.


