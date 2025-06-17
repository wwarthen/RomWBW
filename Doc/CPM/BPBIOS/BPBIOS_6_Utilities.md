# 6. B/P Bios Utilities

We have developed and adapted many support routines to assist you in using and tailoring B/P Bios installations. Many of these follow generally established functions, and their use may be readily perceived. Others are adaptations of routines which we developed to support our earlier ZSDOS operating system, or are adapted from routines available in the Public Domain. The remainder were written specifically to support this product.

Each support routine follows generally-acknowledged practices of Z-System Utilities, including built-in Help, and re-execution with the `GO` command.

Help is accessed by typing the name of the desired routine followed by a double-slash (e.g. `LDSYS //`). Additional information is provided in the following sections of this manual.

Some of the features of B/P Bios are supported with Version-dependent programs. These vary among specific systems and should not be intermingled if you support a number of different computer types. Contact us if you need to create such a specific tailored version of one of these programs. In the following descriptions, the routines which are restricted to a specific system or which require tailoring are so annotated.


## 6.1 BPBUILD - System Image Building Utility

The purpose of BPBUILD is to create a loadable System Image. Input files needed by this utility include the output of assembling the `BPBIO-xx` file (in Microsoft relocatable format), a `.REL` or `.ZRL` image of an Operating System (ZSDOS for unbanked or ZSDOS2 [`ZS203.ZRL` or `ZS227G.ZRL`] for fully banked systems are recommended), and a `.REL` or `.ZRL` image of a Command Processor (`ZCPR33.REL` for unbanked, `Z41.ZRL` for fully banked systems are recommended).

BPBUILD is capable of incorporating many types of operating system components into the executable image. Among systems tested are customized BIOSes, ZRDOS, CP/M 2.2, ZCPR2, ZCPR3x and others. One restriction in any segment occurs in the use of Named COMMONs for locating various portions of the system within the processor's memory map. Most assemblers and linkers are limited in the number of different named COMMON bases which can be supported. The linker incorporated in BPBUILD can handle only the following named COMMONs: `_ENV_`, `_MCL_`, `_MSG_`, `_FCB_`, `_SSTK_`, `_XSTK_`, `_BIOS_`, `BANK2`, `B2RAM`, and `RESVD`.


### 6.1.1 Using BPBUILD

BPBUILD operates with layered Menus and may be invoked to build a replacement for an existing Image file, or with defaults to construct a totally new Image file. All files needed to construct the desired image; Bios, Dos, and CPR must reside in the current Drive and User Area, or be accessible via the PUBlic attribute if operating under ZSDOS. The syntax for BPBUILD is:

| Command | Description |
| :--- | :--- |
| `BPBUILD` | Generate system w/ defaults |
| `BPBUILD fn[.ft]` | Make/Modify a specific system (Default type is `.IMG`) |
| `BPBUILD //` | Display this Message |

It should be noted that if ZSDOS2 is the selected Dos, Bit Allocation buffers for Hard Drives are located in the System Bank.


### 6.1.2 Menu Screen Details

Upon starting BPBUILD, you will be presented with the main menu screen. From this screen, you may select one of the three main categories to tailor the output image. At any point in the configuration, pressing Control-C or ESCape will exit the menu and return to the Command Processor prompt.

```generic
/---------------------------------------------------------------------------\
|  Main                                                                     |
|                                                                           |
|                                                                           |
|         1  File Names                                                     |
|                                                                           |
|         2  BIOS Configuration                                             |
|                                                                           |
|         3  Environment                                                    |
|                                                                           |
|                Selection :                                                |
\---------------------------------------------------------------------------/
```


#### 6.1.2.1 Screen 1 - File Names

Selecting option One from the main menu will present a screen listing the current file names for the three input files needed to build an image, and the name to be applied to the output file. If BPBUILD was executed with the name of an existing Image file, the file names will be those of the files used to build the specified Image file, otherwise it will be default names furnished by BPBUILD. A sample screen for a non-banked YASBEC system might be:

```generic
/---------------------------------------------------------------------------\
|  Files (1.1)                                                              |
|                                                                           |
|                                                                           |
|         1  Command Processor File : ZCPR33  .REL                          |
|                                                                           |
|         2  Operating System File  : ZSDOS   .ZRL                          |
|                                                                           |
|         3  B/P Bios Source File   : B/P-YS  .REL                          |
|                                                                           |
|         4  B/P Executable Image   : BPSYS   .IMG                          |
|                                                                           |
|                Selection :                                                |
\---------------------------------------------------------------------------/
```

Selecting any one of the four options will allow you to change the name of the file to use for the desired segment. Default File types exist for each entry with both the Command Processor and Operating System files defaulting to `.ZRL` if no type is entered. The Bios file defaults to `.REL`, while the Image output file defaults to `.IMG`.


#### 6.1.2.2 Screen 2 - BIOS Configuration

Selecting BIOS Configuration from the Main Menu (Selection 2) presents the basic screen from which the sizes and locations of either existing system segments (if building from an existing IMG file) or default values from within BPBUILD. A sample screen might appear as:

```generic
/---------------------------------------------------------------------------\
|  Environment (2.1)                                                        |
|                                                                           |
|  COMMON (Bank 0) MEMORY              BANK 2 MEMORY                        |
| ----------------------         ------------------------                   |
|  A   Common BIOS  - D400H        E   Banked BIOS  - 0000H                 |
|        Size       -   83               Size       -    0                  |
|  B   Common BDOS  - C600H        F   Banked BDOS  - 0000H                 |
|        Size       -   28               Size       -    0                  |
|  C   Command Proc - BE00H        G   Command Proc - 0000H                 |
|        Size       -   16               Size       -    0                  |
|  D   User Space   - E900H        H   User Space   - 0000H                 |
|        Size       -    6               Size       -    0                  |
|                                                                           |
|                Selection :                                                |
\---------------------------------------------------------------------------/
```

While the ability to dictate locations and sizes for various system sizes is provided at this point, we urge you not to alter the values for Bank 2 Memory unless you are VERY familiar with the potential effects and willing to risk potentially disastrous consequences. The primary reason for including this screen was to allow setting Common Memory base locations and to dictate the size of the Resident User Space. Other than specifying the Common User Space size (the starting location defaults to the address in `Z3BASE.LIB`), the remaining values were included primarily for the few specialized users who require custom system locations.


#### 6.1.2.3 Screen 3 - Environment Configuration

Since the Environment Descriptor is an integral part of the Operating System due to the specification of low-level parameters such as memory allocations, this screen is provided to configure the memory map in a suitable fashion for the system being built. For example, in a Fully Banked system with ZSDOS2, there is normally no need for a Resident Command Processor. Using this screen then, selection D may be used to indicate that no space is used for the RCP by setting its location and size to zero. With this space freed, the IO Package (Selection C) may be raised to F400H, keeping its size at 12 records. Since these are the two lowest segments in the memory map, BPBUILD will use this as the lowest value used in the Environment, and move the Operating System segments (including the Resident User Space) up in memory for an increase of 2k bytes in Transient Program Area.

It is important to note that the Environment Descriptor defined in this screen is stored in a special area within the IMG file produced and placed in memory by LDSYS when activated. Any alteration after loading, for example loading another ENV file as part of the STARTUP script may cause the system to operate incorrectly.

```generic
/---------------------------------------------------------------------------\
|  Environment (3.1)                                                        |
|                                                                           |
|   A  - Environment   - FE00H      F  - Named Dirs    -  FC00H             |
|         Size (# recs)-    2             # of Entries -    14              |
|   B  - Flow Ctrl Pkg - FA00H      G  - External Path -  FDF4H             |
|         Size (# recs)-    4             # of Entries -     5              |
|   C  - I/O Package   - EC00H      H  - Shell Stack   -  FD00H             |
|         Size (# recs)-   12             # of Entries -     4              |
|   D  - Res Cmd Proc  - F200H            Entry Size   -    32              |
|         Size (# recs)-   16       I  - Msg Buffer    -  FD80H             |
|   E  - Command Line  - FF00H      J  - Ext. FCB      -  FDD0H             |
|         Size (bytes) -  208       K  - Ext. Stack    -  FFD0H             |
|                                                                           |
|                 Selection :                                               |
\---------------------------------------------------------------------------/
```

When all configuration or inspection activity is complete at any menu, entering a return with no selection will return to the previous menu screen (Main menu from lower screens), and will start the build activity if a single return is entered from the main menu. All specified files are first read to determine their sizes, and internal memory address calculations are performed. You will be asked if you desire BPBUILD to use optimal addresses for the maximum amount of Transient Program Area (AutoSize), or use the values which were specified in menu 2.1. If you enter N at this point, the build will progress under the assumption that you want to use the values from Menu 2.1. A second prompt will ask you if you want to build a system of "standard" segment sizes. This refers to the CP/M 2.2 standard sizes of 16 records (2k) for the Command Processor and 28 records (3.5k) for the Basic Disk Operating System (BDOS). If you answer Yes, AND the segments are equal to or less than these sizes, the system will be built to reflect these system segment sizes. Since many ill-behaved, but very popular, programs assume the old CP/M segment sizes, this option should generally be used. If the autosize query is selected, BPBUILD automatically executes to completion and returns to the Command Processor prompt.

To obtain the maximum Transient Program Area with "standard" segment sizes, the easiest method is to execute BPBUILD exiting with the Autosize query answered in the affirmative (Yes), then execute BPBUILD again on the produced image answering the first query with N for No Autosizing, and the second query with a Y to adjust the lower segment sizes for "standard" segment locations. While this is a somewhat cumbersome procedure, it results in a much smaller and faster running utility than otherwise possible, and was a design tradeoff in the development process.


## 6.2 BPCNFG - Configuration Utility

The flexibility of the B/P Bios architecture permits customizing to your system and desired methods of operation. This utility consolidates some of the more common and important tailoring features in a single utility. BPCNFG, the B/P Bios Configuration Utility, provides an easy, menu-driven means of tailoring Hard and Floppy Drive Boot Sector images, Relocatable Image (`.IMG`) files, and certain elements in an executing system. Using BPCNFG reduces the need to assemble a new Bios image for simple changes, and increases the speed with which changes can be made.


### 6.2.1 Using BPCNFG

BPCNFG syntax follows the standard conventions summarized in Section 1.2, and responds to the standard help option sequence of two slash characters. The syntax under which BPCNFG is invoked is dictated by the type of system you wish to configure. The BPCNFG Syntax is:

| Command | Description |
| :--- | :--- |
| `BPCNFG //` | Print Built-in Help Summary |
| `BPCNFG` | Run interactive, screen mode |
| `BPCNFG *` | Configure Executing System |
| `BPCNFG d[:]` | Configure Drive "d" |
| `BPCNFG [du:]filename[.typ]` | Configure Image File |

The first form of the syntax is self-explanatory and simply prints a short help file listing the purpose of the utility and the syntax of the program use. The Interactive mode of operation, execution of BPCNFG with no arguments, will first ask you whether you wish to configure a Memory, Disk or Image version of a B/P Bios system, and set internal parameters to that mode, as well as loading the requisite data if needed. If no file type is specified for an Image file, a type of `.IMG` is assumed.

BPCNFG may configure options in the currently operating system with some limitations. The most significant limitation is that Hard Drive partitions may not be altered since space for the required bit buffers (ALV and CSV) is allocated at system load (boot) time and cannot be reset when a system is already installed. With this exception, all other parameters may be varied and will be in effect until another system is loaded by Cold Booting the computer, or loading an Image file with LDSYS.

To abort the BPCNFG without changing current parameters, press either ESCape or Control-C from the main menu display. Option setting will occur if a Carriage Return only is entered from the Main Menu Screen.


### 6.2.2 Menu Screen Details

BPCNFG is a Screen-oriented support routine using the terminal attributes defined in the currently installed Termcap. Five main screens are currently defined at the main menu, with several selections resulting in sub-menu screens. The first is the main menu from which the general category is selected for alteration. The top screen line reflects the level and mode as:

```generic
/---------------------------------------------------------------------------\
| Main Menu  -  Configuring Image File  [A10:T1.IMG      ]                  |
|            Bios Version 2.0                                               |
|                                                                           |
|   1   System Options                                                      |
|                                                                           |
|   2   Character IO Options                                                |
|                                                                           |
|   3   Floppy Subsystem Options                                            |
|                                                                           |
|   4   Hard Disk Subsystem Options                                         |
|                                                                           |
|   5   Logical Drive Layouts                                               |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

Each of the five selections results in a sub-menu screen which depicts the specific elements which may be changed and the current values/settings. Each of the selection screens is detailed below.


#### 6.2.2.1 Screen 1 - System Option Parameters

The System Options may be set from Menu Screen 1 which may appear as:

```generic
/---------------------------------------------------------------------------\
| Menu 1 - System Options                                                   |
|                                                                           |
|                                                                           |
|   1   System Drive    = A:                                                |
|                                                                           |
|   2   Startup Command = "START01 "                                        |
|                                                                           |
|   3   Reload Constant = 23040 (5A00H)                                     |
|                                                                           |
|   4   Processor Speed = 9 MHz                                             |
|                                                                           |
|   5   Memory Waits = 0,  IO Waits = 0                                     |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

The Logical System drive selected by the first entry is used by the Bios Warm boot to load the operating system on a Cold boot, and on Error Exits. The Startup command is normally the name of a `.COM` file which performs additional system initialization when first started. Such a file is normally created by entering a sequence of instructions (file names and arguments) into a script using ALIAS, SALIAS, VALIAS or other similar ZCPR3 tool.
			
The remainder of the entries concern the Physical hardware within the computer and generally do not need to be changed for other than initial installation. The Reload Constant at Selection 3 may be "fine tuned" by slightly varying the value. The normal effect of this is to adjust the speed of the Real Time clock within the computer to allow it to keep proper time. The Processor Speed (Selection 4) should be the CPU Clock speed rounded to the nearest MegaHertz. For example, the rate shown in the sample screen is, in fact, 9.216 MHz. When the Clock Speed is changed, an option is offered to automatically scale the Reload Constant (Selection 3) to scale it by a proper factor based on the amount that the Clock Frequency was changed. This is not always needed, but is generally desirable in HD64180/Z-180 systems using an interrupt clock timer.

The number of Memory and IO Waits at Selection 5 are in addition to any Wait states inserted automatically in the hardware. For example, the Zilog Z180 inserts one wait state into all IO Port addresses. Since BPCNFG is a general purpose utility, it cannot know this. The number set with this selection is therefore in addition to any hardware injected wait states.

A sixth menu also exists, but since inadvertent alteration of its values can result in bizarre and potentially destructive consequences, its existence is hidden and prompted if selected. The interaction to select option 6 is:

```generic
Enter Selection : 6
-- This is DANGEROUS...Proceed? (Y/[N]) :
```

If an explicit Y is entered, the hidden menu is displayed appearing as follows for a YASBEC with the MEM4 addressing PAL which allows the full 1 Megabyte range to be used:

```generic
/---------------------------------------------------------------------------\
| Menu 1.1 - System Bank Numbers                                            |
|                                                                           |
|                                                                           |
|   1   TPA Bank #       = 1                                                |
|                                                                           |
|   2   System Bank #    = 3                                                |
|                                                                           |
|   3   User Bank #      = 4                                                |
|                                                                           |
|   4   RAM Drive Bank # = 5                                                |
|                                                                           |
|   5   Maximum Bank #   = 31                                               |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

The bank numbers should reflect the Physical 32k bank numbers in the system progressing from the lowest, or first available, to the highest. The Bank numbers are Zero-based, and may range from 0 to 255 (0FFH). The User Bank and RAM Drive Banks may be set to Zero if No Banked User area or RAM Drive respectively is desired. It should be noted that the actual control for these two features is in other screens, and setting the Bank Numbers to Zero while the options are active can have adverse consequences.


#### 6.2.2.2 Screen 2 - Character IO Parameters

Screen Menu 2 allows configuration of the Character IO subsystem, to include assignment of logical devices to physical devices. A sample screen for the YASBEC might appear as:

```generic
/---------------------------------------------------------------------------\
| Menu 2 - Character IO Options                                             |
|                                                                           |
|                                                                           |
|   1   IOBYTE Assignment:                                                  |
|                Console   = COM2                                           |
|                Auxiliary = COM1                                           |
|                Printer   = PIO                                            |
|                                                                           |
|   2   COM1 - 9600 bps, 8 Data, 1 Stop, No Parity, [In(8)/Out(8)]          |
|                                                                           |
|   3   COM2 - 19.2 kbps, 8 Data, 1 Stop, No Parity, [In(7)/Out(8)]         |
|                                                                           |
|   4   PIO1 - [Out(7)]                                                     |
|                                                                           |
|   5   NULL - [In(8)/Out(8)]                                               |
|                                                                           |
|   6   COM3 - 38.4 kbps, 8 Data, 1 Stop, No Parity, [In(8)/Out(8)]         |
|                                                                           |
|   7   Swap Devices                                                        |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

Selection 1 determines which of the active devices is assigned to the addressable functions dictated by the IOBYTE. This location in memory is used by the operating system for Character IO normally consisting of the Console, Printer (List Device in CP/M terminology) and an Auxiliary IO (Reader and Punch in CP/M). The exact Devices assigned to these Logical functions depends on the bit-mapped characteristics of the IOBYTE, and positioning within the table portrayed in this Menu.

Early versions of B/P Bios (Versions 1.0 and earlier) distributed as "Starter Systems" and test versions used a fixed number of devices and a different data structure for device access. B/P Bios Production systems with Version numbers of 1.1 through 1.9 will contain only four device drivers, but use the newer data structures. Beginning with Version 2.0, however, many Character Devices may be accommodated, with the first four being directly accessible by the IOBYTE, and the ability to exchange devices to place any four in the first positions for access by applications programs. The above screen depicts a typical display under a Version 2.0 Bios. Smaller systems such as placed on the Boot Tracks will use only four fixed devices with a typical Version Number of 1.1 and will not include selections 6 or 7.
			
Selection 1 offers the opportunity to select which of the first four physical devices is assigned to the three logical IOBYTE defined functions. A secondary menu will prompt you for the exact functions and devices. An example of the interaction with selection 1 is:

```generic
Set [C]onsole, [A]uxiliary, or [P]rinter : C
  Set Com[1], Com[2], [P]io, or [N]ull ?
```

Selections 2, 3 and 6 in this sample screen allow configuration of the serial ports included in this B/P Bios. If you are making hardware changes in the Bios, please follow the specifications in the source code to insure that this utility will function as described. For most system installations covered to date, one or more of these options will have no effect, but the capability still exists to configure the option. This selection results in a series of options being presented for verification or alteration. Current settings are listed as default values which will remain selected if no entry is made before the ending Carriage Return (Enter key). A Sample interaction on a YASBEC is:

```generic
Configuring COM1 [In(8)/Out(8)]:
    Baud Rate  (Max=38.4 kbps) =   Selections are:
        1-134.5 bps     2-50 bps        3-75 bps        4-150 bps
        5-300 bps       6-600 bps       7-1200 bps      8-2400 bps
        9-4800 bps      10-9600 bps     11-19.2 kbps    12-38.4 kbps
    Select      [10]    :
    Data = 8-bits.      Change? (Y/[N]) :
    Stop Bits = 1-bits. Change? (Y/[N]) :
    Parity = None       Change? (Y/[N]) :
    XON/XOFF Flow = No  Change? (Y/[N]) :     * Defaults selected
    RTS/CTS Flow = No   Change? (Y/[N]) :
    Input is 8-bits.    Change? (Y/[N]) :
    Output is 8-bits.   Change? (Y/[N]) :
```

Selection four tailors the default parallel port, normally a Centronics printer interface. As with previous selections, not all options may be active, but will appear in the configuration sequence to retain the generality of BPCNFG. Current settings (in braces) will be retained if a Carriage Return is entered.

```generic
Configuring PIO1 [Out(7)]:
    XON/XOFF Flow = No  Change? (Y/[N]) :
    RTS/CTS Flow = No   Change? (Y/[N]) :
    Output is 7-bits.   Change? (Y/[N]) :
```

The final selection (only appearing in Bios Versions 2.0 and later) allows the exchange of devices. In the sample Menu 2, Selections 2-5 are active devices, with Selection 6 existing in the Bios, but not accessible. Using the last selection, COM3 could be exchanged with one of the first four making it an active device upon exiting BPCNFG which calls the Device Configuration function. The interaction may appear as:

`Exchange Device : 3   With Device : 6`

After this choice, active devices will be COM1, COM3, PIO1 and NULL.


#### 6.2.2.3 Screen 3 - Floppy Disk Parameters

Extensive tailoring of the Floppy Disk subsystem is possible at this Screen. While many popular systems do not support all options (mainly due to the Controller logic), all options and respective settings will appear to be set at this point. Also, while such items as the Step rate will accept increments of a set size (1 mS for Step Rate), many systems have discrete increments that do not match allowable values. For example, the SMS 9266 used in MicroMint's SB-180 will only accept 2 mS increments with 5 1/4" Floppy Drives, the WD 1770 used in the Ampro Little Board only steps at 6, 12, 20 and 30 mS, while the 1772 used in the YASBEC permits 2, 3, 5, and 6 mS Steps. The rates set with BPCNFG are suitably rounded up to the most appropriate rate within the Bios code during drive selection to allow tailoring of drives in a generalized manner. Options tailorable for Floppy Disk drives as seen on a YASBEC are:

```generic
/---------------------------------------------------------------------------\
| Menu 3 - Floppy Disk Options                                              |
|                                                                           |
|                                                                           |
|   1   Floppy Drive Characteristics:                                       |
|        Drv0 = 3.5" DS, 80 Trks/Side                                       |
|                Step Rate = 3 mS, Head Load = 4 mS, Unload = 240 mS        |
|        Drv1 = 5.25" DS, 40 Trks/Side                                      |
|                Step Rate = 4 mS, Head Load = 24 mS, Unload = 240 mS       |
|        Drv2 = 5.25" DS, 80 Trks/Side                                      |
|                Step Rate = 3 mS, Head Load = 24 mS, Unload = 240 mS       |
|        Drv3 = 5.25" DS, 80 Trks/Side                                      |
|                Step Rate = 6 mS, Head Load = 24 mS, Unload = 240 mS       |
|                                                                           |
|   2   Motor ON Time (Tenths-of-Seconds) : 100                             |
|                                                                           |
|   3   Motor Spinup (Tenths-of-Seconds)  : 5                               |
|                                                                           |
|   4   Times to Try Disk Operations : 4                                    |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

Selecting one of the four items on this menu will prompt you for the information needed, allowing you to retain current settings as a default. An example of the additional prompts resulting from selection one on the above screen is:

```generic
Configure which unit [0..3] : 2
    Size  8"(1),  5.25"(2),  3.5"(3)?       [2]     :
    Single or Double-Sided Drive ?          (S/[D]) :
    Motor On/Off Control Needed ?           ([Y]/N) :
    Motor Speed Standard or Hi-Density      ([S]/H) :
    Tracks-per-Side (35,40,80)              [80]    :
    Step Rate in Milli-Seconds              [3]     :
    Head Load Time in Milli-Seconds         [24]    :
    Head Unload Time in Milli-Seconds       [240]   :
```


#### 6.2.2.4 Screen 4 - Hard Disk Parameters

The B/P Bios Hard Disk Subsystem is centered around the Small Computer Systems Interface (SCSI) standard. Backward compatibility with the earlier Shugart Associates System Interface (SASI) is also provided to allow older controllers to be used. During the course of B/P Bios development, several controller types were incorporated, with unique features accommodated in a transparent way within the utilities. As a compromise between flexibility and program size, a limit of three physical hard drive units was placed on the system. This limit does not impact the 16 possible logical drives which the computer may handle. A sample Menu for a single Conner CP-3100 SCSI Drive of 100 Megabytes is:

```generic
/---------------------------------------------------------------------------\
| Menu 4 - Hard Disk Options                                                |
|                                                                           |
|   1   Hard Drive Controller = Conner SCSI                                 |
|                                                                           |
|   2   First Drive  :  Physical Unit 0,  Logical Unit 0                    |
|         No. of Cylinders = 776,        No. of Heads   = 8                 |
|                                                                           |
|   3   Second Drive : - inactive -                                         |
|                                                                           |
|   4   Third Drive  : - inactive -                                         |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

The first available selection allows you to select the type of controller installed or used in the system. The controller definition applies across all three physical drives, so some care must be applied in mixing different controller types on the same system. For example, a Shugart 1610-3 controller is incompatible with a Seagate SCSI or SCSI-2 drive attached directly to the SASI bus since initialization information is required of drives on the 1610-3 which must not be sent to the SCSI due to the differing commands. The controller types defined in the initial release of B/P Bios appear in Selection 1 as:

```generic
  Select Controller Type as:
        (0) Owl
        (1) Adaptec ACB-4000a
        (2) Xebec 1410a/Shugart 1610-3
        (3) Seagate SCSI
        (4) Shugart 1610-4/Minimal SCSI
        (5) Conner SCSI
        (6) Quantum SCSI
                                       
Enter Selection :
```
(more added in later versions)

Selections two, three and four from Menu 4 allow you to specify the physical parameters of one of the three possible drives. As with other options, some of the parameters do not apply, such as Reduced Write and Precompensation with SCSI drives, but appear here to allow a general configuration tool. Current settings appear in square braces and are selected if only a Carriage Return is entered. A sample entry configuring the Conner CP-3100 is:

```generic
Activate Drive ([Y]/N) ?
Physical Unit (0..7)            [0]     :
Logical Unit Number (0..7)      [0]     :
Number of Physical Cylinders    [776]   :
Number of Heads                 [8]     :
Reduced Write Starting Cylinder [0]     :
Write Precomp. Start Cylinder   [0]     :
```


#### 6.2.2.5 Screen 5 - Partition Parameters

Menu 5 permits arranging the physical drive complement into Logical Drives, and dividing physical units into multiple logical Partitions.

```generic
/---------------------------------------------------------------------------\
| Menu 5 - Logical Drive Layout                                             |
|                                                                           |
| A: = Unit 0, 64 Sctrs/Trk, 4k/Blk, 7984k (998 Trks), 1024 Dirs            |
| B: = Unit 0, 64 Sctrs/Trk, 4k/Blk, 20000k (2500 Trks), 1024 Dirs          |
| C: = Unit 0, 64 Sctrs/Trk, 4k/Blk, 20000k (2500 Trks), 1024 Dirs          |
| D: = Unit 0, 64 Sctrs/Trk, 4k/Blk, 54432k (6804 Trks), 2048 Dirs          |
| E: = Floppy 0                                                             |
| F: = Floppy 1                                                             |
| G: = Floppy 2                                                             |
| H: =    -- No Drive --                                                    |
| I: =    -- No Drive --                                                    |
| J: =    -- No Drive --                                                    |
| K: =    -- No Drive --                                                    |
| L: =    -- No Drive --                                                    |
| M: = RAM                                                                  |
| N: =    -- No Drive --                                                    |
| O: =    -- No Drive --                                                    |
| P: =    -- No Drive --                                                    |
|                                                                           |
|      1  Swap Drives,  2  Configure Partition 3  Show Drive Allocations    |
|                                                                           |
|                                                                           |
|        Enter Selection :                                                  |
\---------------------------------------------------------------------------/
```

Selection 1 allows for swapping two specified logical drives. For example, the above screen shows a system which will boot from a hard drive. If the system were being configured for a Floppy-based system you might swap drive A with drive E with Selection 1 as:

```generic
              Enter Selection : 1
Swap drive [A..P] : A  with drive [A..P] : E
```

Selection 2 permits defining logical partitions on a Hard drive, and of the RAM drive, if active. It queries you for the needed information from which to set internal Bios values. If converting from an existing system, SHOWHD (See 6.19) will display the values to enter for a specified Partition. An example of the interaction is:

```generic
Configure which Drive [A..P] : D
Allocation Size (1, 2, 4, 8, 16, 32k)   [4]     :
        Number of Dir Entries   [2048]  :
        Starting Track Number   [6000]  :
        # Tracks in Partition   [6804]  :
        Physical Unit Number    [0]     :
```

Selection 3 from Menu 5 may be used in conjunction with the allocation to view the existing allocations for a given Hard Drive Unit. Selecting 3 prompts you for the Desired Hard drive as:

`Display Allocations for which Hard Drive [0..2] :`

and will show the current Partitions and allocations. As an example, the four partitions on the Conner CP-3100 depicted in the Menu 5 screen are reported here on a separate screen as:

```generic
/---------------------------------------------------------------------------\
| Partition Data Hard Drive Unit : 0                                        |
|                                                                           |
|       Drv       Start Trk       End Trk                                   |
|                                                                           |
|         A       2               999                                       |
|         B       1000            3499                                      |
|         C       3500            5999                                      |
|         D       6000            12803                                     |
|         [any key to continue]                                             |
\---------------------------------------------------------------------------/
```


### 6.2.3 NOTES Spring 2001

A new menu item was added to the primary screen to allow configuration from a script configuration (`.CNF`) file. The format is explained in the built-in help.


## 6.3 BPDBUG - B/P Bios Debug Utility

This utility provides a low-level tool patterned after Digital Research's DDT, but extended to provide a more useful user interface, the ability to handle Z80 and Z180 mnemonics in disassembly, and memory banking using B/P Bios interfaces. While the description is primarily oriented to screen output, the Operating system permits also sending output to the defined Printer by toggling Control-P which may be enabled and disabled within BPDBUG.

### 6.3.1 Using BPDBUG

The syntax for BPDBUG is simple with only three variants as:

| Command | Description |
| :--- | :--- |
| `BPDBUG //` | Print a short help message |
| `BPDBUG` | Execute BPDBUG |
| `BPDBUG [fn[.ft]]` | Execute BPDBUG, Loading named file |

When executed, BPDBUG relocates the majority of the code to high memory immediately below the BDOS, overwriting the Command Processor. If a file load is specified as in the third method of invocation shown above, and the file type is `.HEX`, then a file in Intel HEX format is assumed and it is converted to binary form at the specified address.

In addition to the short help message available with the double-slash option, a built-in command summary is available at all times from the main BPDBUG prompt by entering a Question Mark. The summary appears as:

```generic
/---------------------------------------------------------------------------\
| B/P Bios DBug  V 0.3                                                      |
| -?                                                                        |
|                                                                           |
| Available commands:                                                       |
|   B{ank}  Bank#                                                           |
|   D{ump} [From  [To]]                                                     |
|   E{nter}  Addr                                                           |
|   F{ill}  Start  End  Byte                                                |
|   G{o}  Addr                                                              |
|   H{ex sum/diff}  Word1  Word2                                            |
|   I{nput}  Port#                                                          |
|   L{ist}  [From  [Thru]]                                                  |
|   M{ove}  Start  End  Dest                                                |
|   N{ame}  FN[.FT]  {for Read/Write}                                       |
|   O{utput}  Port#  Byte                                                   |
|   R{ead file}  [Offset]                                                   |
|   T{race}   {Trace mode On}                                               |
|   U{ntrace} {Trace mode Off}                                              |
|   W{rite file}  Number_of_128-byte_blocks                                 |
|   X {set breakpoint}  Addr                                                |
|   Z{ero breakpoints}                                                      |
|   ?  {Show this msg}                                                      |
\---------------------------------------------------------------------------/
```

Square braces in the summary indicate optional parameters, while text strings and abbreviated names indicate parameters and types.


### 6.3.2 BPDBUG Commands


#### 6.3.2.1 Select Memory Bank _[ B ]_

To select a memory bank in the range of 0..255, simply enter the Command "B" followed by the bank number in Hexadecimal. Optional spaces may be placed between the command letter and the Bank number. The syntax for this command is:

`B[ ]nn`

The Bank number selected by this command will be made the current bank for Display (D), Enter (E) and List (L) commands. If the specified bank number exceeds the largest bank number physically existing in the system, the bank number will be set to the last bank defined in the B/P Bios Header.


#### 6.3.2.2 Dump (Display) Memory in Hex and Ascii _[ D ]_

This command displays memory contents in both hexadecimal and ascii form. Where the current byte in the display is a control character (less than 20H), a period character is printed in the ascii column.

Defaults for this command are 100H and the TPA bank as the starting address, and 256 as the number of bytes to display if no End Address is specified. For subsequent uses of the Dump command, the Starting address will be one more than the ending address of the last Dump. The Bank Number will remain that last specified, or the TPA bank if never changed in a session. The syntax is:

`D[ ][Start_Addr] [End_Addr]`

A sample of the output appearing on the screen is:

```generic
-d100 12f
01:0100   ED73 FE03 31FE 0321 5D00 7E23 FE2F 2006   .s..1..!].~#./ .
01:0110   BE11 AD01 2825 2A01 002E 5A7E FEC3 2018   ....(%*...Z~.. .
01:0120   CDAC 0121 FAFF 197E FE42 200C 237E FE2F   ...!...~.B .#~./
```


#### 6.3.2.3 Enter Values in Memory _[ E ]_

This command permits entering values into memory. A period terminates entry.

`E[ ][Start_Addr]`

```generic
-e100
:41 43 44
:.
```


#### 6.3.2.4 Fill Memory with Constant Value _[ F ]_

Entire memory areas may be set to a single constant value with this command. All three arguments (Start, End and Value) must be specified, and the command will not be executed if fewer arguments are given. The syntax is:

`F[ ]Start End Value? 

As an example, the following command sets the sixteen bytes from 100H through 10FH in the currently selected bank to binary Zero;

```generic
-f100 10f 0
```


#### 6.3.2.5 Go (Execute) Program in Memory _[ G ]_

Execution may be started at any arbitrary address with the "Go" command. If no target address is specified, 100H is assumed since it is the normal starting address of programs loaded into the Transient Program Area. The syntax of the command is:

`G[ ][Address]`


#### 6.3.2.6 Hex Sum and Difference _[ H ]_

Simple Hexadecimal addition and subtraction is performed with the "Hex" command. When the command is executed with two addresses, both their sum (modulo 65536) and difference (also modulo 65536) are displayed in that order. The syntax of this command is:

`H[ ]Value1 Value2`

For example, if an offset of 45H from a base of 0ED3FH was desired, the resulting g positive and negative address could be determined as:

`-hed3f 45` <-- Entered
`ED84 ECFA` <-- ..returned Sum and Difference


#### 6.3.2.7 Display Value from Input Port _[ I ]_

This command will read the desired Input Port in the range of 0 to 0FFFFH and display the resulting byte. Since 16-bit address calculations are used, this command will properly read the built-in ports of the HD64180 and Z180. The syntax of the Input command is:

`I[ ]Port_num`


#### 6.3.2.8 List (Disassemble) Memory Contents _[ L ]_

Disassembly of executable instructions in memory is accomplished with this command. As with the "Dump" command, the starting address defaults to 100H when first loaded, and is assumed to be the instruction following the last one disassembled for subsequent uses of this command if no address is explicitly entered. If no Ending address is specified, 23-26 bytes will be contained in the listing depending on the length of the last instruction. The syntax is:

`L[ ][Start] [End]`

A sample of an entry and the resulting output with an arbitrary program is:

`-l120 127` <-- Entered

```generic
0120  CDAC01            CALL    01AC   
0123  21FAFF            LD      HL,FFFA
0126  19                ADD     HL,DE
0127  7E                LD      A,(HL)
```
..displayed

Note that the actual bytes included in the disassembled instructions are also listed in contrast to other similar programs to provide additional information for you. Additionally, an extra blank line is displayed after all unconditional jumps and returns to serve as a visual representation as an absolute change in control flow. The mnemonics are standard Zilog Z180 codes.


#### 6.3.2.9 Move Memory Contents _[ M ]_

This command permits blocks of data to be moved within memory. Memory address bounds checking is performed to insure that overlapping addresses are handled correctly so that minor shifts in blocks of data may be accomplished. The syntax for this command is:

`M[ ]Start End Destination`


#### 6.3.2.10 Set File Name for Read/Write _[ N ]_

This command is used to set the file name and optional type prior to a read or write operation. The name remains active until changed or BPDBUG is exited. The syntax is:

`N[ ]FileName[.FileTyp]`


#### 6.3.2.11 Send Value to Output Port _[ O ]_

This command forms the complement of the Input command covered above. It sends a specified byte to the addressed Output port. The syntax is:

`O[ ]Port_num Value`

As with all arguments, if more digits than the number needed are specified, only the last two (for a Byte) or four (for an address) are used in the expression.


#### 6.3.2.12 Read a File into Memory _[ R ]_

This command reads the file specified by the Name command into memory at the default address of 100H (if no offset is specified), or at a starting address of Offset+100H. The Offset value must be specified in Hexadecimal. The syntax of the Read Command is:

`R[ ][Offset]`

When the file is loaded, you will be informed of the current setting of the default address for the base of current memory (PC value) and the byte after the last one loaded by the Read Command (Next). The display might appear as:

```generic
Next  PC
0880 0100
```

#### 6.3.2.13 Activate Trace Mode _[ T ]_

To assist in debugging programs, a Trace function is included which is activated with this command. Upon encountering a breakpoint (See X Command below) the program enters the Trace mode in which each instruction is trapped and the state of the processor displayed along with a Disassembled listing of the instruction. Entering a single letter "T" activates the Trace Mode.

A fragment of a program run with Trace On is:

```generic
S0Z0H0P0N1C0  A=00 BC=0000 DE=0000 HL=0000 SP=0100
     IX=A4AE IY=FFFE           0100  C30B01            JP      010B

S0Z0H0P0N1C0  A=00 BC=0000 DE=0000 HL=0000 SP=0100
     IX=A4AE IY=FFFE           010B  2A0500            LD      HL,(0005)
S0Z0H0P0N1C0  A=00 BC=0000 DE=0000 HL=52C3 SP=0100
     IX=A4AE IY=FFFE           010E  CDBD07            CALL    07BD
S0Z0H0P0N1C0  A=00 BC=0000 DE=0000 HL=52C3 SP=00FE
     IX=A4AE IY=FFFE           07BD  7C                LD      A,H
S0Z0H0P0N1C0  A=52 BC=0000 DE=0000 HL=52C3 SP=00FE
     IX=A4AE IY=FFFE           07BE  B5                OR      L
S1Z0H0P0N0C0  A=D3 BC=0000 DE=0000 HL=52C3 SP=00FE
     IX=A4AE IY=FFFE           07BF  C8                RET     Z
```


#### 6.3.2.14 De-Activate Trace Mode _[ U ]_

This command turns the Trace Mode Off so that subsequent execution occurs at full speed with no trapping. Entering a single letter "U" deactivates the Trace Mode.


#### 6.3.2.15 Write File to Storage _[ W ]_

This command is the complement to the Read command covered above. It assumes that the data to be written starts at 100H and writes the specified number of 128-byte blocks to the file last specified with a "Name" command. The syntax of this command is:

`W[ ]#Blocks`


#### 6.3.2.16 Set Breakpoint _[ X ]_

This command is used to tag locations within the program to be executed under BPDBUG which, when executed, will temporarily stop executing and either return to the BPDBUG prompt or print information for the Trace output. Up to two breakpoints may be active at any point in time. The syntax is:

`X[ ]Address`


#### 6.3.2.17 Clear Breakpoints _[ Z ]_

This command clears all breakpoints set with the X command cited above. Entering the single letter "Z" clears all breakpoints.


#### 6.3.2.18 Display On-Line Help _[ ? ]_

Entering a single Question Mark ("?") as a command displays the Build-In help display containing a summary of the commands available from within BPDBUG.


## 6.4 BPFORMAT - Floppy Disk Format Utility

BPFORMAT is the general-purpose format routine for Floppy Disk Drives in the B/P Bios system. It automatically adapts to the specific hardware used in your computer to present a single interface across a wide range of platforms, and incorporates the ability to format disks in formats not implemented in your computer. This capability allows you to format disks for exchange with other users in their native disk format using the same library of alien disk formats used by the EMULATE program (see 6.8).

This program is B/P Bios-specific and will not function under other Bios systems. Its operation is the same under banked or unbanked systems, and with the many types of physical Disk Controller integrated circuits available. In the initial version, the following Controller types are supported:

- 765
- 1692
- 1770
- 1771
- 1772
- 1790
- 1791
- 1792
- 1793
- 1795
- 2790
- 8473
- 9266

### 6.4.1 Using BPFORMAT


#### 6.4.1.1 Built-in Formats

The simplest way of formatting diskettes is to use one of the formats included in the currently running B/P Bios. BPFORMAT may be invoked by simply entering the program name, or by following it with a drive letter and colon as:

`BPFORMAT D:`

Optionally, a Named directory may replace the drive letter and will format the drive associated with the named directory. For example, if a directory named WORK: is defined to be Drive C:, User 10, the command WORK:

`BPFORMAT WORK:`

would format Drive C:. When invoked in either of the above manners, BPFORMAT will list the built-in formats available for this drive from those included in the file `DPB.LIB` (and optionally `DPB2.LIB`, see sections 4.1 and 4.2). Only those formats which exactly match the drive characteristics will be presented, so only 80-track formats will be offered for an 80-track drive and so forth. For example, the offerings for a 40-track 5.25" disk drive may result in:

```generic
Available formats are:

    A - Ampro DSDD    B - Ampro SSDD

Select format (^C to exit) :
```

As precautions against inadvertently formatting diskettes, confirmation prompts are included as the program progresses, and the opportunity exists to escape from the format program to Command processor. An example appears at this point where a Control-C aborts the format operation.


#### 6.4.1.2 Library Formats

If formatting of a diskette is desired in a format not supported by the built-in selections featured in the executing Bios, the library of formats used by EMULATE (see 6.8) may be used. Reasons for using the library may range from the need to format in a mode used on another type of computer to a choice made internally unavailable by sizing constraints, as when tailoring a system for Boot Track installation. Whatever the reason, this flexibility is offered as an inherent feature of B/P Bios and is specified by specifying the L Option when invoking BPFORMAT. If specifying the desired drive on the command line as in either example above, simply add the option character at the end (with optional slash) as:

`BPFORMAT D: L`

If you wish to be prompted for the drive letter as part of the program flow, the slash becomes mandatory to inform BPFORMAT that you are specifying the Library option instead of Drive L:. The invocation thereby becomes:

`BPFORMAT /L`

When executed with the Library option, you will be presented with a menu of formats which may be used with the physical drive as defined in the Bios header. A sample display appears as:

```generic
Available formats are:

    A - Actrx SSDD    B - Ampro SSDD    C - VT180 SSDD    D - H-100/4 1D
    E - H89/40  1S    F - H89/40  1D    G - H89/40  1X    H - Kaypro 2
    I - Osborne 1S    J - Osborne 1D    K - Ampro DSDD    L - H-100 DSDD
    M - H89/40  2D    N - H89/40  2X    O - QC-10 DSDD    P - Kaypro 4
    Q - MD-3  DSDD    R - PMC-101       S - Sanyo 1000    T - TV 802/803
    U - XBIOS-3 2D    V - XL-M180 T2

Select format (^C to exit) :
```

Entering one of the letters corresponding to a format will set all parameters and proceed with the format operation. Entering a Control-C at this point will return you to the Command Processor at this point avoiding any inadvertent disk formatting.

The Assembly source to the Format library is provided in the B/P Bios package as an aid in accepting formats not included in the default distribution package, or to experiment with new formats.


### 6.4.2 Configuration

Two options exist for custom tailoring BPFORMAT to operate in a method you find most comfortable. The first is a Quiet option which will minimize extraneous output to the Console. It is set by a Boolean flag consisting of a Byte at an offset of 22 (16H) bytes from the beginning of the program. A Zero byte in this location signifies Verbose operation where all defined prompts and status information is displayed. A Non-Zero value (normally 0FFH) indicates that Console output should be minimized with only essential output displayed.

The second option is for selection of the File Name and Type to be used for the Library of formats used with the L option. The default value of this entry is `ALIEN.DAT` (in formatted FCB form) which is also used with the EMULATE program. This field begins at an offset of 23 (17H) bytes from the beginning of the program.


### 6.4.3 BPFORMAT Error Messages

`Must be wheel to FORMAT!!!`

As a safety feature, only users with Wheel privileges may format diskettes. This error message identifies an attempt without the proper authorization.

`*** ERROR ! Not B/P Bios, or Old Version !`

In most cases, this error will be seen if an attempt is made to format a disk under a Bios other than B/P Bios. If some of the mandatory data structures have been altered, or if an attempt is made to run the release version of B/P Bios under one of the early test versions of B/P Bios, this message will also be displayed.

`*** ERROR ! The selected format is not supported by FORMAT!`

This error will be displayed if a format from a library of formats is incompatible with the specified drive, such as if a 5.25" format is selected for an 8" drive.

`*** ERROR ! The detected FDC is not supported by FORMAT!`

The Bios reported a Floppy Disk Controller (FDC) that is not in the list of Controllers supported by BPFORMAT. To view the list of controllers supported, view the internal Help by using the double-slash option.

`*** ERROR ! Disk is Write Protected!`

An attempt was made with the Write Protect Tab ON (for 5.25"), OFF (for 8") or in the Protect position (3.5") for the specified disk. Set the disk to Read/Write by altering the physical setting and try to format the disk again.

`*** ERROR ! Disk won't recalibrate`

The drive heads could not be restored to Track 0 position. Thiserror is often due to a failure in the drive mechanism, but can also be caused by deformed diskettes or loose drive cable.

`Format Error : xx`

An error was detected during the format process. The "xx" will be the Hexadecimal byte returned by the Bios portion of the format routine, and bits set to a "1" value should represent an error code decipherable from the FDC Data or programming sheet.

`+++ Can't Open : fn.ft`

BPFORMAT could not open the format library file. To access a format library, it must either be in the default library, or accessible from it either via the PUBlic bit or along the ZSDOS path.

`No formats available for this drive!`

This error will be reported if no formats (internal or from a format library, depending on how it was invoked) are supported on the specified drive. For example, if all internal formats are for 5.25/3.5" drives and the target drive is specified as an 8" drive, then no formats will be available if BPFORMAT is invoked using the internal format method of operation.


## 6.5 BPSWAP - Logical Disk Swap Utility

This utility allows you to exchange the drive letters defining two logical drives or partitions within the system. It performs any operations necessary to properly adjust the Operating System to account for drive redefinition, and relogs both drives using Dos Function 37 to force rebuilding of the Allocation Bit Map.

BPSWAP is a B/P Bios utility and will not execute under any other system. It may be operated in an interactive mode, fully "expert" mode with arguments passed on the command line, or a combination where the first drive letter is passed on the command line and the second entered in response to a query. If running in the interactive mode, entering a Control-C instead of a drive letter will interrupt the program and return to the Command Processor. BPSWAP is re-executable under ZCPR with the `GO` command.


### 6.5.1 Using BPSWAP


#### 6.5.1.1 Interactive Operation

To execute BPSWAP in the interactive query/response mode, simply invoke the program by entering its name as:

`BPSWAP`

The program will insure that the system is running a B/P Bios, gather internal data from the operating environment, and display the prompt:

`First Drive to Swap [A..P] :`

At this point, a drive letter (upper or lowercase) should be entered within the specified range of "A" through "P". All invalid characters, except for Control-C which aborts the program, will result in repeated prompts for the first drive letter. When a valid drive letter is detected, the second is likewise requested with the prompt:

`Second Drive to Swap [A..P] :`

BPSWAP responds to entries at this point in an identical manner to the first, repeatedly prompting for a valid letter, or the abort character. When a valid letter is received, each logical drive is reassigned to the physical definitions of the other.


#### 6.5.1.2 Command Line Operation

BPSWAP can accept and parse drive letters passed to it on the Command Line in order to include drive exchanges in Startup scripts or other alias commands. To invoke the program in this manner, enter the program name with two drive letters in the range of "A" through "P" with a delimiter between each field. Each of the drive letters may be followed by an optional colon. Delimiting characters are Tab, Space, and Comma. A summary of the complete syntax is:

`BPSWAP d1[:] <Tab> | <Space> | <Comma> d2[:]`

To illustrate, the following are valid commands executing BPSWAP:

| Command | Description |
| :--- | :--- |
| `BPSWAP A: E:` | Exchange E drive with A |
| `BPSWAP D,H` | Exchange D drive with H |

If an invalid character is detected for either or both of the drive letters when called in the Command Line mode, operation automatically reverts to the Interactive mode and the respective prompt(s) will be given for valid drive letter(s). This feature permits a hybrid mode of operation to be specified wherein the first drive letter is passed on the Command Line, and the second entered in response to the second drive prompt.


### 6.5.2 BPSWAP Error Messages.

The only error message which may be printed by BPSWAP is in response to internal routines which validate the presence of a B/P Bios. Any attempt to run this utility on other Bioses results in the error:

`+++ Not B/P Bios ... aborting +++`

after which point the program aborts and control returns to the Command Processor. No effect on drive allocations will occur if this error is displayed.


## 6.6 BPSYSGEN - System Generation Utility

BPSYSGEN is our generic version of the classic SYSGEN program used to place an executable system image onto the boot sectors of a Floppy or Hard Disk. It uses information provided by the Bios in the form of DPB/XDPB data (see 5.2.3) which defines the physical and logical drive characteristics to write system information from the system tracks of one drive to another, or from an image produced by MOVxSYS (see 6.16) to the boot tracks of a drive.


### 6.6.1 Using BPSYSGEN


#### 6.6.1.1 Interactive Operation

The basic Interactive mode is initiated by simply entering the program name at the Command Line prompt as:

`BPSYSGEN`

You will first be prompted for the source drive from where to obtain a bootable system image, then for a destination drive to save the image. To provide a visual clue that the program is executing, a series of periods is printed on the screen with each period representing a physical sector of data. At the conclusion of the operation, the program exits to the Command Processor prompt.

A binary file produced by MOVxSYS (see 6.16) may be placed on the system tracks of a hard or floppy disk by specifying the file name as a command line argument as:

`BPSYSGEN B:ZSDOS64.BIN`

When activated in this manner, you will be prompted for the destination drive letter after BPSYSGEN loads the image file and validates it as a valid system image. Alternatively, you may replace the file name with a drive letter followed by a colon to automatically load the image from a specific drive, and be prompted for the destination drive.


#### 6.6.1.2 Command Line Operation

A single operation may be completely specified from the command line arguments thereby avoiding drive prompts. When invoked in this manner, the first argument specifies the source for the system (drive designator or file) with the second argument being the drive specification on which to place the bootable system image. The syntax for the Command Line method of operation is:

`BPSYSGEN {d: | fn[.ft]} d:`


### 6.6.2 BPSYSGEN Error Messages

`*** Read Error`

An unrecoverable error was encountered reading either the boot tracks of a drive, or a specified bootable file.

`*** Bad Source!`

The source drive does not exist or could not be selected.

`*** Write Error`

An unrecoverable error was encountered writing the boot tracks of the specified destination drive.

`*** Bad Destination!`

The destination drives does not exist or could not be selected.

`*** No System!`

There are no valid System Tracks on the Source or Destination Drive, or an anomalous condition (more than 3 reserved tracks) was detected.

`*** Can't Open Source File!`

The specified boot image file could not be located, or an error occurred during the attempted File Open.


## 6.7 COPY - Generic File Copy Utility

`COPY.COM` is a file copy program derived from the ZCPR3 MCOPY tool written by Richard Conn. It blends the many modifications by Bruce Morgen, Howard Goldstein and others in MCOPY48 with further enhancements in the spirit of the ZSDOS environment. File date stamping is supported for the full range of stamping capabilities provided by ZSDOS. A user-definable "Exclusion list" is now supported to prevent copying of specific files or file groups, and two options to ease file backups with the Archive bit have been added. COPY is also more user-friendly than MCOPY, and provides increased error checking and user feedback.

COPY only operates in the Command Line Driven or Expert mode. As with the other utilities provided with ZSDOS, COPY displays a short Help message when invoked with a double-slash argument as explained in Section 1.2. The Help message also includes a list of available options along with the effect of each when included as command line arguments.

While COPY is ready to run without special installation procedures, you may wish to change the default parameters to customize it to your operating style. In this manner, you can minimize the number of keystrokes required to perform routine operations by avoiding passing many options on the command line. To set default conditions, insure that `COPY.COM`, `COPY.CFG` and `ZCNFG.COM` are available to the system, and execute ZCNFG as described in Section 4.8 of the ZSDOS 1.0 Manual.


### 6.7.1 Using COPY

The basic syntax for COPY follows the original CP/M format by listing the destination drive/user, an equal sign, then the source drive/user and file name. An alternate syntax added by Bruce Morgen in MCOPY48 permits specifying transfers in the "Source-Destination" form popularized in MS-DOS. In this alternate form, you first enter the source drive/user and filename, a space, and then the destination drive/user and optional filename. Using the normal symbology, the syntax is summarized as:

`COPY dir:[fn.ft]=[dir:]fn.ft,... [/]options`

or

`COPY [dir:]fn.ft dir:,... [/]options`

If no destination filename is specified, a number of unique files may be copied to a specified directory by catenating source files separated with commas. Where a destination file name is specified, both source and destination file names and types must be free of wildcard characters. This popular "Rename" feature in a copy was a much requested addition to the ZSDOS copy utility. Options to tailor the actions of COPY may be appended after the source file list.

Yet another method of transferring files was retained from the original MCOPY roots. If no destination drive/user is recognized in the command line arguments, all referenced files will be copied to a default drive/user location which is contained in the header portion of COPY. The default location is Drive B, User 0 in the distribution program, but may be changed as described below. If options are desired with this syntax, the slash option delimiter is mandatory. The syntax for this method is summarized as:

`COPY [dir:]fn.ft,... /options`

Various configuration options detailed later allow you to customize COPY to suit your operating style. For example, status displays of each operation may be suppressed for a "Quiet" mode, verification that copied files match the original (or at least produce the same error check code) may be enabled or disabled, etc. If a method of Date and Time Stamping is active under ZSDOS, the original Stamp information will be transferred to the destination file. The following examples in the "Verbose" method of operation will serve to illustrate by copying a file from the current Drive and User area to the same drive, User 10.

```generic
   COPY ZXD.COM 10:

COPY  Version 1.71 (for ZSDOS)
Copying C2:ZXD     .COM to C10:
 -> ZXD     .COM..Ok (Dated)  Verify..Ok
 0 Errors
```

In this case, No file of the same name existed in the destination area, but some form of File Stamping was active, so the source Stamp information was successfully transferred to the destination. Performing the same activity with the other syntax now produces:

```generic
   COPY 10:=ZXD.COM

COPY  Version 1.71 (for ZSDOS)
Copying C2:ZXD     .COM to C10:
 -> ZXD     .COM  Replace Same (Y/N)? Y..Ok (Dated)  Verify..Ok
 0 Errors
```

Since COPY now detected a destination file of the same name, and File Stamping as well as duplicate checking (another option flag) were in effect, COPY compared the Last Modified dates for both source and destination files. Finding a match, the prompt "Replace Same" was issued, and received a (Y)es response to copy the file anyway. Other responses, depending on the results of the date comparison are "Replace Older", which means that an older file exists on the destination, and "Replace Newer" which means that you are trying to replace a newer file on the destination with an older version.

A similar error check is made if a duplicate file is found to determine if the file was found with the PUBlic Attribute bit. If a Public file is detected on the destination drive, a warning to the effect is printed. Answering Yes to replacement at this point will result in a Read-Only error unless ZSDOS has been set to permit writes to Public Files (see 2.8.3 of the ZSDOS 1.0 Manual).

As stated earlier, COPY has no Interactive mode of operation per se, but the Inspect option provides a means to select files for transfer in a somewhat interactive manner. In this mode, all files selected by the file specification in the command line are displayed, one at a time, and you may enter "Y" to copy the file, "N" to Not copy the file, or "S" to forget the rest of the selected files. An example copying all files from the current Drive and User to User 10 is:

```generic
   COPY *.* 10: /I

COPY  Version 1.71 (for ZSDOS)
Copying C2:????????.??? to C10:
 Inspect -- Yes, No (def), Skip Rest
BU16    .COM - (Y/N/S)? Y
BU16    .MZC - (Y/N/S)? N
COPY    .COM - (Y/N/S)? Y
COPY    .Z80 - (Y/N/S)? S
```

If operating in the Verbose mode, status on each file will be printed as the copies progress.


### 6.7.2 COPY Options

Several option characters are available to customize COPY operations. Most of these options may be set as default conditions using Al Hawley's ZCNFG Configuration Utility. Alternatively, you may enter any of them on the command line to alter the functions of a single operation. The command line option characters are as follows:

| Option | Description |
| :---: | :--- |
| `A` | Archive |
| `E` | Test for File Existence |
| `I` | Inspect Files |
| `M` | Multiple Copy |
| `N` | No replacement if File exists |
| `O` | Test Existence of R/O Files on Destination |
| `Q` | Quiet |
| `S` | exclude System Files |
| `V` | Verify |
| `X` | Archive Only if File exists |

From the brief syntax summaries listed above, you will note that the standard option delimiter, a slash, is optional if both source and destination specifications are listed on the command line. If only one specification is listed, is when copying to the default drive, the delimiter is Mandatory. Each option is described in the following paragraphs.


#### 6.7.2.1 Archive Option

When this option is active either by specifying in the command line or as a default, only files which do Not have their Archive Attribute set will be selected. After the selected files are copied, the Archive Attribute on the Source file will be Set to indicate that the file has been "Archived". When used in conjunction with the default drive and user settings, the A option provides a simple method of archiving files in a single user area. The default for this option is Off, for No control of selection by the Archive Attribute. Adding the A option to the command line reverses the configured setting.

It should be noted that this option is incompatible with the "M" (Multiple Copy) option. The first copy operation will set the Archive bits on selected files, and they will not appear in subsequent copies.


#### 6.7.2.2 File Existence Option

This option controls the test for an already-existing file on the destination drive by the same name. Adding the E option to the command line argument reverses the configured setting. The default in the ZSDOS distribution version is On, or Check for Existing files. This option does not affect the check for PUBlic files on the destination drive, which is always active.


#### 6.7.2.3 Inspect Files Option

As illustrated previously, the I option provides a means of selectively copying files, without entering the name of each file. The distribution default for this option is Off, or do Not inspect the selected file list. Specifying this option on the command line argument list reverses the configured setting.


#### 6.7.2.4 Multiple Copy Option

This option may be used to copy a file, or group of files to the same drive several times, as when making several copies of the same file group on different disks. A prompt is given before each copy operation begins, and you may abort at the prompt, or change disks before beginning the copy. The distribution default for this option is Off, for No Multiple copying. Adding the M option to the command line argument list reverses the configured setting for this option.


#### 6.7.2.5 No Replacement Option

When added as a command line argument, the N option will not allow replacement of a file which already exists on the destination Drive/User. This option cannot be configured, and always assumes the same initial state when COPY is called. The default initial state for this option is Off to permit replacement of existing files.


#### 6.7.2.6 Read-Only File Test

This option, when added as an argument, reverses the configured setting of a flag which checks for the existence of file(s) satisfying the specified name and type with the Read-Only attribute set. If this flag is active and a Read-Only file is located satisfying the criteria, the file will not be automatically overwritten. The E (File Existence) flag will still dictate how other files are handled.


#### 6.7.2.7 Quiet Option

When used on a system with ZCPR3, this option causes a reversal in operation of the ZCPR3 Quiet flag. If the ZCPR3 Quiet flag is active, COPY with the Q option operates in a Verbose mode. If you do not use ZCPR3, or the ZCPR3 Environment defines the Quiet flag as inactive, this option will disable unnecessary console messages for a Quiet mode of operation. There is no default condition for this option, and it is only effective for a single call of COPY.


#### 6.7.2.8 System Files Option

This option controls whether or not files with the SYStem Attribute set will be located by COPY. The distribution default is Off to include SYStem files in COPY file lists and permit copying of such files. The default may be configured as described below, and the default may be reversed by adding an S in the command line option list.


#### 6.7.2.9 Verify Option

To add a measure of confidence that no errors occurred in a COPY operation, the Verify option may be activated. When active, the destination file is read in order to compute a Cyclic Redundancy Check (CRC) word. This word is then compared to a value calculated when reading the source file. If the two values match, you can be reasonably sure that the destination file is a true copy of the source file. The distribution default for this option is True to verify each file copied. This option may be changed by configuration, or reversed by adding a V to the command line option list.


#### 6.7.2.10 Archive if Only if File Exists Option

Occasionally, you may wish to update frequently archived files to the same destinations in a simpler manner than naming each file, or by using the Inspect option. The X option was created for just this purpose. When this option is added, COPY first searches the source directory for files which have not been archived, then checks the destination directory for each file. If a match is found, the file is copied, and the source file deleted, unless it is marked as Read-Only. There is No configurable setting for this option which is always assumed to be OFF when beginning COPY.


## 6.8 EMULATE - Alien Disk Emulation Utility

EMULATE locks any or all Floppy Disk Drive(s) to specified formats, native or alien, from a Database of formats. It may also be used to display current settings and restore drives to auto-selection if the Bios was assembled with the AutoSelect option (see 4.2). The Floppy Disk format information is contained in a file named ALIEN.DAT whose use is shared with BPFORMAT (see 6.4). This sharing of a common database of formats allows formatting, as well as reading and writing of a large number of the hundreds of formats used by CP/M vendors over the years.


### 6.8.1 Using EMULATE

This utility is only usable with B/P Bioses which have been assembled with the Auto-Select option (`AUTOSEL`) active. This is the normal mode for release versions of B/P Bios, although some versions placed on the boot tracks of floppy disks may have a scaled-down complement of built-in formats to reduce the system image size (see 4.3). EMULATE can be executed either in an interactive query/response mode or in a command line "expert" mode with arguments passed on the command line. The EMULATE syntax is:

| Command | Description |
| :--- | :--- |
| `EMULATE //` | Print Built-in Help Summary |
| `EMULATE [/]X` | List Current Floppy Format Settings |
| `EMULATE [/]U` | Return All Floppies to Autoselect |
| `EMULATE` | Execute in interactive Query/Response mode |
| `EMULATE d[:]` | Select format of Drive d: interactively |
| `EMULATE d[:] [nn]` | Set Drive d: format to entry nn (expert) |

To keep the numbering of formats in the Database file constant, thereby allowing the expert mode of configuration, all formats in the `ALIEN.DAT` file are loaded without validation against the actual drive parameters. Once a format is selected, the required drive characteristics (disk size, number of sides, speed and number of tracks) are compared to the physical drive parameters contained in the B/P Bios header structure (see 5.2.1, `CONFIG+35`). If the selected format can be accommodated by the physical drive, then the format information is loaded into the Extended DPH/DPB fields for the specified drive and the format locked to prevent re-assignment on warm boots.

The following formats are currently included in the ALIEN.DAT file, the source code for which is included in the distribution version of B/P Bios as ALIEN.LIB:

```generic
 1  Actrx SSDD     2  Ampro SSDD     3  VT180 SSDD     4  H-100/4 1D
 5  H89/40  1S     6  H89/40  1D     7  H89/40  1X     8  Kaypro 2
 9  Osborne 1S    10  Osborne 1D    11  Ampro DSDD    12  H-100 DSDD
13  H89/40  2D    14  H89/40  2X    15  QC-10 DSDD    16  Kaypro 4
17  MD-3  DSDD    18  PMC-101       19  Sanyo 1000    20  TV 802/803
21  XBIOS-3 2D    22  XL-M180 T2    23  Ampro SSQD    24  DEC Rainbo
25  Eagle-IIE     26  H89/80  1D    27  H89/80  1X    28  Ampro DSQD
29  Amstrad WP    30  H89/80  2D    31  H89/80  2X    32  XBIOS-4 2Q
33  CCS   SSDD    34  IBM 3740      35  Bower 8"1D    36  TTek  SSDD
37  Bower 8"2D    38  CCS   DSDD    39  TTek DSDD2    40  TTek DSDD1'
```

Current drive format allocations may be examined at any time with the X option which will list the 10-character name the format assigned to each floppy drive in the system, or state that it is Autoselecting. The U option removes all fixed formats, returning them to Autoselecting.


### 6.8.2 EMULATE Error Messages

`+++ Can't Open Database File +++`

EMULATE could not locate the `ALIEN.DAT` file in the currently logged directory. Solutions include setting the PUBlic attribute of `ALIEN.DAT` and insuring that the Dos Path includes the drive containing the file.

`+++ Format Not Supported on this drive!`

Self-explanatory. Common causes of this error are selecting an 80-track format on a 40-track drive, or an 8" format on a 5.25" drive. Check the `ALIEN.DAT` source code to determine any needed data on the exact drive requirements for each format.


## 6.9 HDBOOT - Hard Drive Boot Utility (tailored)

HDBOOT is a specialized routine which is only available for those computers which feature the ability to boot from Hard Drives from a cold start such as the YASBEC and Ampro Little Board computers in the initial version. HDBOOT is a customized utility which is tailored for specific versions and will not execute on B/P Versions which it does not recognize. It modifies the boot record of a Floppy Disk System image placed on a drive by BPSYSGEN (see 6.6) to allow the system to be started from the Hard Drive at power-on or from a system Reset.


### 6.9.1 Using HDBOOT

HDBOOT is extremely simple to use, and accesses the B/P Bios Data structures of the target system for any system-specific data required, such as initialization parameters for the Shugart/Xebec controller types. When invoked, the existing system is checked to insure that it is a valid B/P Bios version. If valid, you will be asked to specify which of the three possible physical SCSI units to access, and from there on the operation is automatic. A sample screen for a successful execution of this utility is:

```generic
/---------------------------------------------------------------------------\
|  B/P HDBOOT Utility  V1.0  31 Aug 92                                      |
|      Copyright 1992 by H.F.Bower/C.W.Cotrill                              |
|                                                                           |
|   Configure which unit for Booting [0..2] : 0                             |
|                                                                           |
|  Target Controller is : Seagate SCSI                                      |
|   ...Reading Boot Record...                                               |
|   ...Writing Boot Record... Ok..                                          |
|                                                                           |
|  A0:BASE>_                                                                |
\---------------------------------------------------------------------------/
```

It should be noted that a system must have been placed on the target unit with BPSYSGEN (see 6.6) before executing this utility, or an error message will be issued and the operation aborted.


### 6.9.2 HDBOOT Error Messages

`*** No System!`

The specified target Unit does not contain a valid Boot System. Place a valid Boot Track system on the unit with BPSYSGEN and execute HDBOOT again.

`*** Invalid Unit Number ***`

The Unit number specified on the command line is invalid. Either it is not "0", "1" or "2", or the unit is not active.

`*** Invalid Boot Record ***`

The Boot Record existing on the specified Unit is not valid for this type of Computer. Normal causes are no system currently exists on the specified unit or the system in place is not a valid one for this system. Both of these may be corrected by placing a system on the first physical partition of the unit with BPSYSGEN (see 6.6)

`+++ Image is Not B/P Bios, or Wrong Version +++`

The image read from the Boot Tracks of the specified system was not a valid version of B/P Bios. The two most common causes of this are; not placing a Boot System on the System Tracks with BPSYSGEN, or altering the fixed data structures of the Bios source code in a way which violates the standard layout resulting in a system which cannot be recognized.

`+++ Unit Not Active! Run BPCNFG to Set Drives.`

The specified Hard Drive Unit (0, 1 or 2) was not tagged as an active unit. This can be changed by first executing BPCNFG (see 6.2) on the executing memory system, then re-invoking HDBOOT.


`+++ Not B/P Bios ... aborting +++`

An attempt was made to execute this utility on a system which was not running under B/P Bios. Boot the system with a B/P Bios-equipped system and try again.


`*** Read Error`

An unrecoverable error occurred while trying to read the target system's Boot Record. This is most often due to media errors on the first cylinder of the target unit and cannot be rectified. Another cause may be an incorrect definition of the physical characteristics of the controller and/or drive.


`*** Write Error`

An unrecoverable error occurred while trying to write the modified Boot Record to the Hard Drive unit. If a second attempt at execution is unsuccessful, it probably indicates either an incorrect physical definition of the Hard Drive unit, or unrecoverable media errors on the first cylinder of the drive.


## 6.10 HDIAG - Hard Disk Format/Diagnostic Utility

HDIAG is a generic B/P Utility program to Run Diagnostics, Format, Verify and examine Hard Drive parameters using any of the defined controller types in a B/P Bios system where such capabilities are defined. The ability to select the controller type in the beginning of the program is allowed to enable you to check and initialize drives using controller types other than that defined in the executing Bios for added flexibility. The following controller types are handled in the initial B/P Bios release:

- Adaptec ACB-4000A
- Shugart 1610-3 / Xebec 1410A
- Seagate SCSI
- Shugart 1610-4 (Minimal SCSI)
- Conner SCSI
- Quantum SCSI
- Maxtor SCSI (others added in later releases)


### 6.10.1 Using HDIAG

This utility tool only operates in an interactive mode, so it is simply invoked with its name and no arguments (other than the standard double-slash Help request). When activated, it reads the controller type from the B/P Bios header structure and asks you if this is the controller type you wish to use. If you wish to use a different controller type, such as diagnosing a Seagate SCSI drive from a system which has an Adaptec controller for normal use, you may alter the controller definition for the remainder of the HDIAG session. The interaction through to the main loop prompt may appear as:

```generic
/---------------------------------------------------------------------------\
|  B/P Bios Hard Disk Utility  V1.3a,  14 Jun 97                            |
|                                                                           |
|  Controller = Adaptec  Ok ([Y]/N) ? : Y                                   |
|                                                                           |
|  Functions:       F  - Format                                             |
|                   V  - Verify                                             |
|                   D  - Run Diagnostics                                    |
|                   P  - Show Disk Parameters                               |
|                                                                           |
|  Select (^C or ESC to Quit) :                                             |
|                                                                           |
\---------------------------------------------------------------------------/
```


#### 6.10.1.1 Show Disk Parameters _[ P ]_

If you are running HDIAG on a Hard Drive Unit which is already defined in the Bios and was previously formatted, or one of the self-identifying SCSI drives, then you may view the current drive parameters with the P command. The display varies with the controller type and the amount and type of information that is available. Some of the data may be from Bios definitions, and other data from either the controller (e.g. Adaptec) or the drive electronics (SCSI or SCSI-2). Samples of the forms of information are:

SCSI1 setting
```generic
Unit : 0     CONNER  CP3100-100mb-3.5

  Total Blocks = 204864   (12804 Eq. Tracks)
  Sctrs/Track  =  33
  Sector Size  =  512
  Interleave   =  1
  # Cylinders  =  776
  Num of Heads =  8
```

Adaptec ACB-4000, Syquest SQ-312 10 MB
```generic
Unit : 0

  Total Blocks = 22140   (1383 Eq. Tracks)
  Sctrs/Track  =  18
  Sector Size  =  512
  # Cylinders  =  615
  Num of Heads =  2
  Reduced Wrt. =  615
  Precomp. Cyl =  615
  Step Rate    =  12 uS Buffered
  Media type   =  Removable
  Landing Zone =  615
```

#### 6.10.1.2 Hard Disk Diagnostics _[ D ]_

Some drives feature built-in diagnostics routines which test the unit's electronics and media. Other systems simply execute the power-up sequence which generally includes a sequence of self-tests. Normally, only the re-initialize function can be relied on, and is included in the standard suite of HDIAG functions with this command. Sample output resulting from this function is:

```generic
  Select (^C or ESC to Quit) : D
  Unit Number [0..2] (^C or ESC to Abort) : 0
Re-Initializing Unit : 0 ..Ok
 ..Waiting for Ready..
```

Pauses may occur in the execution of the sequence, most noticeably after the status prompt stating "Re-Initializing Unit" before the "..Ok" appears. Depending on the exact system, this time is often when the actual controller electronics are being checked, and may involve moving the drive head which can be a time consuming task. There is also a pause very often after the prompt "..Waiting for Ready..", particularly if the heads were moved and must be repositioned over the outer cylinder of the drive. When the drive returns a ready status, then the main selection menu is again displayed and HDIAG is ready for another command.


#### 6.10.1.3 Verify Drive Media _[ V ]_

This function permits evaluating the condition of a formatted drive to identify defects to a varying extent. By using a mix of defeating the Error Correcting code where possible, and enabling or disabling the Individual Sector checks, a relatively extensive, albeit often time consuming, non-destructive status of the drive unit may be obtained.

```generic
  Select (^C or ESC to Quit) : V
  Unit Number [0..2] (^C or ESC to Abort) : 0
  Verify Individual Sectors (Y/[N]) : N
Verifying Unit : 0     CONNER  CP3100-100mb-3.5

Block 891
  ...aborted...
```


#### 6.10.1.4 Format Drive _[ F ]_

Setting all of the data storage areas on the disk to a constant value, and renewing the control information on the drive is the purpose of this function. It is destructive, and any data on the drive will be lost. For this reason, several checks are included in the program to insure that you do not inadvertently activate this command.

While most of the information needed to format a drive is available from either the built-in data which can be read from the drive or controller, or from the Bios data areas, some items are still required from the user. You will therefore be asked to provide any data necessary to format the drive. In the older SASI systems (1610-3, Xebec, etc) this can amount to a considerable number of entries. Fortunately, formatting of drives is not often required, and the method of formatting used in HDIAG is flexible enough to allow a wide range of devices to be connected.


### 6.10.2 HDIAG Error Messages

Several error messages will be presented for specific problems encountered in the operation of HDIAG. Many of the messages will be specific to certain operations, and others will change the specific information depending on the capabilities of the controller type selected. The most general of these concerns the SCSI/SASI Sense command. The Newer SCSI systems use "Extended Sense" which can return more information than the basic Sense values. When Extended Sense is detected, the "Key" value is displayed in many error messages rather than the basic "Sense" byte. Consult the programming manual for the specific controller or drive for the specific meanings of these bytes. Such a message will usually be displayed as:

`Error!  (Comnd = xx)  Sense: xx`

or

`Error!  (Comnd = xx)  Key = xx`

Also, to provide additional information during operation of many of the functions, the raw status byte read from the controller when an error occurs is also displayed as part of an error message as:

`(status = xxH)`

The interpretation of the hexadecimal byte presented may be gathered from the programming manual for your specific drive or controller type.

`+++ Not B/P Bios ... aborting +++`

An attempt was made to execute HDIAG under a Bios other than B/P, or modifications made to the Bios altered the locations or values needed to correctly identify the system.

`**** SCSI Block Length Error !`

This fatal error message will be displayed if the Command Descriptor Block returned from the Bios is too small to allow the extended commands needed for the requested operation. It usually results from alterations to the Hard Driver module which change necessary values.

`**** Controller Not Readable !`

HDIAG could not read parameters from the drive or controller. This will only appear in the R (Read Drive Parameters) function, when the controller type is "Owl".

`**** No Diagnostics for : <contyp>`

The Controller selected cannot perform Diagnostics in a way that HDIAG can access or perform the needed functions. This will only appear in the D (Perform Diagnostics) function.

`**** Verify Not Available !`

The specific drive/controller selected has not been defined adequately to allow verification of the drive. This will only appear in the V (Verify) function when the controller type is "Owl".

`+++ 1610-3 Initialization Error...Sense = xxH`

An error was detected sending the initialization string to a Shugart 1610-3 or Xebec 1410A controller. Insure that this is the correct type of controller setting for your hardware configuration. It will only appear in the V (Verify) function.


## 6.11 INIRAMD - RAM Disk Initialization Utility

INIRAMD is a B/P Bios utility that initializes the Directory of a RAM Drive and optionally initializes it for DateStamper (tm), P2DOS, or both types of file stamps. It contains protective features to preclude inadvertent initialization of an already formatted RAM Disk, and may be command line driven for execution from within STARTUP scripts.


### 6.11.1 Using INIRAMD

This utility is designed to be operated with Command Line arguments, but features built-in defaults which can be configured by either overlaying bytes in the beginning of the program with new default settings, or by configuring with Al Hawley's ZCNFG tool. To execute with the default settings, simply enter:

`INIRAMD`

The complete syntax for INIRAMD is:

`INIRAMD [d:][/][Q][D][P]`


### 6.11.2 Command Line Mode

By entering arguments on the Command Line when INIRAMD is invoked, several internal default values can be set to the specific settings desired at the time. The first argument expected when parsing the Command Line tail is a Drive Letter. This is optional and will override the default drive M: built into the program. To specify a drive other then the default, enter:

`INIRAMD d:`

Extraneous prompt and status messages can be withheld during execution of INIRAMD by either setting the default "Quiet" flag embedded in the program, setting the "Quiet" flag in the Environment, or passing a Q as an argument when invoking the program. Initializing the RAM Drive in Quiet mode using the default drive is then accomplished by entering:

`INIRAMD Q`

You may also specify which types of Date/Time Stamps to add to the RAM drive during preparation with the P (for P2DOS Stamps) and/or D arguments. If not operating in the Quiet mode, INIRAMD notifies you which type(s) of Stamping methods have been added to the RAM Drive after the directory area is initialized to a blank value. Initializing drive M: for both types of Stamps then is initiated by entering:

`INIRAMD M: PD`


### 6.11.3 INIRAMD Error Messages

`+++ Not B/P Bios ... aborting +++`

An attempt was made to execute INIRAMD under a Bios other than B/P, or modifications made to the Bios altered the locations or values needed to correctly identify the system.

`+++ Already Formatted...Proceed anyway (Y/[N]):`

This warning and prompt will be issued if INIRAMD detected the dummy file name used as a tag that the RAM Drive is already formatted. This is most often seen in systems that contain battery backed-up RAM and INIRAMD is invoked either directly or in a Startup alias script. To minimize the appearance of this message if you desire to have the RAM Disk initialized in the Startup script, include the following:

| Command |  |
| :--- | :--- |
| `IF ~EX M:-RAM.000` | Assume RAM Disk is M: |
| `INIRAMD M:` | Assume RAM Disk is M: |
| `FI` |  |

`+++ Drive d: does NOT Exist`

Either the default or explicit drive specified in activating INIRAMD was has not been defined to the system. One possibility is that the RAM Drive was swapped for an undefined drive letter. Check the drive assignments with BPCNFG, Option 5 if you wish to check the Drive assignments.

`+++ Drive d: is Not a RAM Drive!`

Either the default or explicit drive specified in activating INIRAMD was a valid drive, but was not a RAM Drive. As with the previous error, one possibility is that the RAM Drive was swapped for another drive which was of another type. Use BPCNFG, Option 5 to check the Drive assignments.


## 6.12 INITDIR - P2Dos Stamp Initialization Utility

INITDIR prepares disks for P2DOS-type file stamping. It does this by replacing every fourth entry in the disk's directory tracks with a time and date entry which is prefixed with a special character (hexadecimal 21). Existing directory entries in the fourth position are then shifted to the first entry in the next logical sector and the initialized directory sectors are written back to the disk.

| **W A R N I N G** |
| --- |
| INITDIR should not be run on disks containing valid DateStamper file stamps since it rearranges directory data. To install both DateStamper and P2DOS stamping on one disk, start with a blank disk, or one with no datestamps of either type and run both PUTDS and INITDIR on the disk before using it. Doing otherwise will invalidate any existing stamp data. |


### 6.12.1 INITDIR Interactive Mode.

INITDIR can be run in either an interactive mode by simply entering its name at the Command Prompt, or in "Expert Mode" by specifying a drive letter as an argument on the command line. In the interactive mode, you will be asked for a drive letter which will specify the drive to initialize with P2DOS stamps.

If the DateStamper `!!!TIME&.DAT` file is detected on the disk, INITDIR issues a warning and asks if you want to proceed or not (see 6.12.2 below). To avoid the possibility of loss of Time and Date Stamp information from DateStamper, this routine should only be run on freshly-formatted or blank drives. The syntax of INITDIR is summarizes as:

| Command | Description |
| :--- | :--- |
| `INITDIR //` | Print summary help message |
| `INITDIR` | Execute in Interactive Mode |
| `INITDIR d[:]` | Initialize Drive D: |


### 6.12.2 INITDIR Error Messages

`Directory already initialized`

The selected disk is already prepared for P2DOS stamps.

`Illegal drive name`

The character entered was not in the range of "A" thru "P".

`Not enough directory space on disk`

The directory on the selected disk is more than three-fourths full. Not enough space is available to support P2DOS file stamps.

`Directory read error`

An error was encountered in reading the disk directory.

`Directory write error`

An error occurred while writing the initialized directory. It will probably result in loss of file data.

```generic
--> DateStamper !!!TIME&.DAT File Found <--
          Proceed anyway (Y/[N]) :
```

The special DateStamper `!!!TIME&.DAT` file exists on the disk. If other files are also on the disk, most of the DateStamper time and date information will be lost. On freshly-formatted or empty disks, no DateStamper file stamp data exists, so it is safe to answer with a Y and initialize the disk.


## 6.13 INSTAL12 - Boot Track Support Utility


Install CPR, ZSDOS, B/P Bios in a MOVxSYS "type" image from standard size (2k CCP, 3.5k DOS, ~4.375k Bios) files

INSTAL12 is the latest modification to the ZSDOS INSTALOS utility distributed with ZSDOS 1.0 which automatically overlays your computer's System Image file, such as `MOVCPM.COM` (CP/M) or `MOVZSYS.COM` (ZRDOS) program, or Absolute System Model file (e.g., `CPM64.COM`) with ZSDOS or ZDDOS to produce a new file containing ZSDOS/ZDDOS instead of your original Basic Disk Operating System. INSTAL12 also allows you to set the defaults of various ZSDOS parameters during the installation process (these parameters may also be changed later with the ZSCONFIG program).

INSTAL12 is designed to make the installation process as easy as possible. With INSTAL12 you may load files from all drives and user areas from A0: to P31:. Error detection is extensive, and Section 6.13.3 of this manual fully explains all INSTAL12 error messages. Finally, you may safely abort INSTAL12 at nearly all points by pressing Control-C.

Before using INSTAL12, ensure that any necessary files from your B/P Bios and/or ZSDOS Distribution Disk are present:

* Microsoft .REL formatted assembly of B/P Bios (MOVCPM = YES)
* ZSDOS.ZRL (if replacing Operating System)
* ZCPR33.REL, ZCPR34.ZRL or other Comnd Proc (if replacing CPR)
* INSTAL12.COM

The following file from your B/P Bios Distribution Disk, CP/M or ZRDOS System Disk must also be accessible:

* MOVxSYS.COM (B/P Bios), MOVCPM.COM (CP/M), MOVZSYS.COM (ZRDOS), or System Image file for systems such as the Oneac ON!


### 6.13.1 Using INSTAL12

To run INSTAL12, most users should simply enter

`INSTAL12`

at the Command Prompt. This tells INSTAL12 that you are installing a system segment over a System Image relocation file, such as `MOVxSYS.COM`, `MOVCPM.COM` or `MOVZSYS.COM`. If you need to install a segment over an Absolute System Model file such as a `CPM59.COM`, `ZSYSTEM.MDL`, or Oneac ON! file, you should enter

`INSTAL12 /A`

to run INSTAL12 in Absolute mode. INSTAL12 now displays its opening banner and requests the name of a file as:

`System Image file to patch (Default=MOVCPM.COM) :`

in Relocatable mode, or

`Absolute System Model (Default=SYSTEM.MDL) :`

in Absolute mode.

You need not enter all of the information; INSTAL12 will fill in any missing items with the default disk, user, or filename. If you simply hit RETURN, INSTAL12 searches the current directory for the default System Image or Absolute System Model file (`MOVxSYS.COM`, `MOVCPM.COM` or `SYSTEM.MDL`). Here are some sample responses:

```generic
System Image file to patch (Default=MOVCPM.COM) : B3:
       (Selects MOVCPM.COM on drive "B" in user area 3)

System Image file to patch (Default=MOVCPM.COM) : 10:MOVYSYS
       (Selects MOVYSYS.COM on the current drive, user 10)

System Image file to patch (Default=MOVCPM.COM) : C:MOV18SYS.OLD
  (Selects MOV18SYS.OLD on drive "C", current user area)`
```

Once INSTAL12 finds the requested file, it validates your operating system image. If the CCP, BDOS or BIOS portions of the System Image or Absolute System Model file are invalid, INSTAL12 prints an error message and quits at this point. This may occur if an Absolute System Image was loaded but INSTALOS was invoked without the /A suffix. If both methods of calling INSTAL12 fail, first ensure that your system image or generation program is operating properly. If you are sure that you have a working MOVxSYS, MOVCPM, MOVZSYS, or Absolute Model file that INSTAL12 cannot validate, you will need to contact your distributor who will initiate actions to correct your problem.

If all values in your operating system file match expected parameters, a summary of those values is displayed. If you specified a System Image file (e.g., `MOVxSYS.COM`), the display should be similar to:

```generic
Addresses in system image (as seen under DDT) :
     CCP : 0980H        Map @ 3610H
     BDOS: 1180H        Map @ 3710H
     BIOS: 1F80H        Map @ 38D0H
```

The addresses shown will probably differ from these, but if both columns display values other than 0000H, INSTAL12 will correctly overlay the three system segment portions of the image with specified files.

If you specified an Absolute System Model, the display will be similar to:

```generic
Addresses in system image (as seen under DDT) :
     CCP : BC00H
     BDOS: C400H
     BIOS: D200H
```

As above, the addresses will probably differ from those in the example, which are for a 54K system.

If no error message appears, INSTAL12 has properly validated your file. Next, a menu of choices appears:

```generic
     1 - Replace CCP
     2 - Replace DOS
     3 - Replace BIOS
     4 - Save and Exit
Enter Selection (^C Quits) : _
```

To install a new B/P Bios image from your assembly, select option 3. You will be asked to enter the name of the file as:

`Name of BIOS file (Default=CBIOS.REL) : _`

The default file type is `.REL` and the file **MUST** be in Microsoft relocatable format. When a terminating Carriage Return is entered, either the name you entered or the default will be located. If found, the size will be evaluated against the available space in the image file. Often when adding a B/P Bios to an older system generation program, the bit map portion of the program will be relocated. You will be notified with a message signifying the distance in bytes that the map was relocated. This is simply a diagnostic tool, and you should not be alarmed at the message. Following the message "...overlaying BIOS...", INSTAL12 will return to the main menu for the next command.

Replacement of the Command Processor with `ZCPR33.REL` or `ZCPR34.ZRL` is identical to Bios replacement, except that no relocation of the bit map is possible. The specified file will either fit and overlay the original, or it will be too large and the program will exit with an error message to that effect.

For ZSDOS installation, enter a 2. You will be asked for the name of a Disk Operating System file as:

`Name of DOS file (Default=ZSDOS.ZRL) : _`

The default file type at this point is `.ZRL`, but operating systems in Microsoft `.REL` format such as distribution versions of ZRDOS are also accepted. As above, you may respond with a full or partial file specification and INSTAL12 will fill in any missing items with the default disk, user, or filename.

Once the Disk Operating System file is found the following prompt appears:

```generic
ZSDOS.ZRL Size OK...overlaying BDOS..
Examine/Change ZSDOS parameters ([Y]/N)? : _
```

At this point, INSTAL12 allows you to change the startup settings of all ZSDOS options. If this is your initial installation of ZSDOS, we recommend that you press N for "No" to bypass this step, and skip the following paragraph.

If you enter any character other than N or n, the default option in brackets ([Y] for "Yes") is assumed, and INSTAL12 displays the current ZSDOS defaults as:

```generic
     1 - PUBlic Files           : YES
     2 - Pub/Path Write Enable  : NO
     3 - Read-Only Vector       : YES
     4 - Fast Fixed Disk Log    : YES
     5 - Disk Change Warning    : NO
     6 - Path w/o System Attr   : YES
     7 - DOS Search Path        : Disabled
     8 - Wheel Byte Protect     : Disabled..Assumed ON
     T - Time Routine (Clock)   : Disabled
     A - Stamp Last Access Time : Disabled
     C - Stamp Create Time      : Disabled
     M - Stamp Modify Time      : Disabled
     G - Get Date/Time Stamp    : Disabled
     S - Set Date/Time Stamp    : Disabled
Entry to Change ("X" if Finished) : _
```

These options are presented in the same manner by ZSCONFIG, and are fully described in Section 4.10 of the ZSDOS 1.0 manual.

Once you bypass the configuration step or exit by pressing X, one of the following prompts appears depending on whether you are installing an Image or Absolute Model file:

`Name to save new system (Default=MOVZSDOS.COM) : _`

or

`Name to save new system (Default=ZSSYS.MDL) : _`

Again, you may respond with a full or partial file specification and INSTAL12 will fill in any missing items with the default disk, user, or filename. If a file with the same name exists, INSTAL12 prompts you for a new name. When INSTALOS has a valid name, it creates your new system file and exits, displaying one of the following messages:

`..Saving MOVZSDOS.COM` (relocatable)

or

`..Saving ZSSYS.MDL` (absolute)


### 6.13.2 INSTAL12 Error Messages

Occasionally INSTAL12 may issue error messages. Most errors result when the files you specified do not conform to INSTAL12' expectations. Often the solution is to run INSTAL12 again, specifying relocatable mode instead of absolute mode or vice-versa. Many INSTAL12 errors will also result from damaged files. If INSTAL12 gives errors in both absolute and relocatable modes, try recopying the source file from masters, or re-assemble the source program and execute INSTAL12 again.

If all of the above fail, your system files may contain information which INSTAL12 cannot recognize. You may be able to attempt an alternate installation with NZCOM or JetLDR for CPR and DOS segments, but you may need to contact the experts on Ladera Z-Node for assistance with Bios-related problems.

The following is a summary of all INSTAL12 error messages, their meanings, and some possible remedies.

`*** SORRY! ZSDOS will only run on Z80 type computers!`

ZSDOS and its utilities will only operate on processors which execute the Z80 instruction set such as the Z80, NSC-800, Z180 or HD64180. There is no fix for this condition other than to run it on another system.

`*** Unable to open [filename.typ]`

INSTAL12 cannot locate or open the system file you specified. First, ensure that the file is at the default or specified drive/user location. If you have specified the file correctly but this error persists, obtain a fresh copy of your system file and try again.

`*** Can't find CCP/BDOS/BIOS at standard locations !!!`

The operating system contained in your system file is not a standard CP/M system. It contains a CCP which is not exactly 2 kilobytes long, a BDOS which is not exactly 3.5 kilobytes long, or both. If this message appears, first ensure that your system file has not been damaged. If you still receive this message, contact the authors on Ladera Z-Node or your distributor.

`++ Image Vector does not match Calculations ++`

INSTAL12 found an internal error in the image file while installing a MOVCPM-type file. If you did not use the /A option when running INSTAL12, you may be trying to perform a relative installation on an absolute file. Try running INSTAL12 again with the command `INSTAL12 /A`.

`*** Cannot find legal Relocation Bit Map`

INSTAL12 was unable to locate a valid relocation bit map pattern in the MOVCPM-type file when installing in Relocatable mode. Non-standard relocatable image files are the general cause for this error. A workaround is to generate an Absolute Model with MOVCPM first, then use INSTAL12 in Absolute (/A) mode on the Absolute Model file.

`---Can't find [filename.typ].. reenter (Y/[N]) :`

The replacement file (CCP, BDOS or BIOS) specified cannot be located. Ensure that the drive, user and file name are correct.

`*** Error in .REL sizing [filename.typ]
        Err Code : nn`

An error occurred during the sizing operation of INSTAL12 on the `.REL` or `.ZRL` file. The `.REL` or `.ZRL` must be in Microsoft relocatable format. Named Common segments other than `_CCP_`, `_BDOS_`, and `_BIOS_` are not allowed, and code and data segments (if any) must not overlap.

`*** file too large to fit...`

The size of the relocatable CCP or BDOS is greater than the available space in the image file (2048 bytes for the CCP, 3584 bytes for the BDOS). This error may result if the relocatable file is not in proper Microsoft relocatable format, or if a customized file is used. This error should never occur with the distribution `ZSDOS.ZRL` file, which is exactly 3584 bytes (3.5k) long.

`*** Error opening : [filename.typ]`

INSTAL12 could not open the specified relocatable file. Ensure that you selected a valid `.REL` file.

`*** Error reading : [filename.typ]`

INSTAL12 detected an error when reading the specified relocatable file. Try recopying the file.

`*** Error in .REL file : nn`

An error was found in a relocatable input file while attempting to replace the CCP, BDOS or BIOS portions of your operating system. "nn" is a hexadecimal code which may assist in locating the cause of the error. Contact your distributor if you need help in resolving an error of this nature with the code in the error message.

`--- That file already exists. Overwrite it (Y/[N])?`

The file you told INSTAL12 to write to already exists. If you enter "Y" here, INSTAL12 will erase the previous copy and create a fresh file with this name. Enter N to select a new name.

`*** No Directory Space for [filename.typ]`

There was not enough directory space for the output file on the selected disk. Send the output file to a different drive by preceding the filename with a drive specifier, or change the disk in the output drive.

`*** Error writing file. Try again with another disk (Y/[N])? :`

This message usually results from a lack of disk space on the drive you specified for output. Change disks and enter Y to try again.


## 6.14 IOPINIT - IO Package Initialization Utility

IOPINIT initializes an IOP Buffer defined in the Environment Descriptor to the standard Dummy IOP format and patches it into the Bios Jump Table. It serves the same basic function as the older ZCPR3 method of loading a SYS.IOP file, but was added as a stand-alone routine to do essentially the entire installation of the package. In so doing, additional space was freed in the B/P Bios core code allowing other routines to be added which cannot be removed to external programs.


### 6.14.1 Using IOPINIT

This program should be included near the beginning of the initial STARTUP script for any system in which an IOP is defined. **NOTE:** This routine MUST be run before any programs which change the Warm Boot Jump at location 0!

No arguments are expected when calling IOPINIT with all values determined from the executing system Environment. The routine responds to the normal double-slash help request as with all support routines.


### 6.14.2 IOPINIT Error Messages

`--- No IOP Buffer defined in Environment ---`

Self-Explanatory. If the IOP Buffer has been deliberately removed during configuration or assembly, no harm will be caused by executing IOPINIT.

`--- No Z-System Environment Defined ---`

This message should NEVER appear since a valid Environment Descriptor is REQUIRED in B/P Bios equipped systems. If it does, one possible cause is incorrect value(s) at critical points within the Descriptor that are used to validate the Environment.

`*** IOP Already Installed! ***`

Self-Explanatory. No harm is done to the system, this message is simply for information.


## 6.15 LDSYS - System Image File Loader

LDSYS is the primary utility to activate a System Image file prepared by BPBUILD (see 6.1). It first validates the currently-running system, then loads the image file, places the component parts where they belong in the computer's memory, and executes the Bios Cold Boot routine of the newly-loaded system. Image files may be either banked or unbanked and need not be placed in the currently-logged directory, since LDSYS can access files along the system path, or from Z3-style Path specifications.


### 6.15.1 Using LDSYS

This utility provides the only way to install a banked system in a B/P System, and a simple way to test non-banked systems before final conversion to bootable systems to be loaded onto system tracks using INSTAL12, MOVxSYS and BPSYSGEN. LDSYS expects only a single parameter to be passed on the Command Line, that being the name of an Image file to load. If no File Type is explicitly entered, a type of `.IMG` is assumed. The location of the desired file may be explicitly stated in normal ZCPR3 fashion with either DU: or DIR: prefixes. The overall syntax of LDSYS is therefore:

`LDSYS [du|dir:]name[.typ]`

When loading, two summary screens are displayed, the first from LDSYS itself, and the second from the Cold Boot routine in the loaded system after control is transferred from LDSYS to the newly-loaded system. A sample display from a banked system during development when installed on a MicroMint SB-180 is:

```generic
/---------------------------------------------------------------------------\
|  B/P Bios System Loader   Vers 1.0  31 Aug 92                             |
|   Copyright (C) 1991 by H.F.Bower & C.W>Cotrill                           |
|                                                                           |
|   CCP starts at    : CC80  (0F80H Bytes)                                  |
|   DOS starts at    : DC00  (0F00H Bytes)                                  |
|     Banked Dos at  : 1080  (0500H Bytes)                                  |
|   BIOS starts at   : EB00  (0880H Bytes)                                  |
|     Banked Bios at : 1580  (1269H Bytes)                                  |
|                                                                           |
|   ...installing Banked System                                             |
|                                                                           |
|   SB180 B/P 60.25k Bios  Ver 0.6  26 Jan 92 (Banked) with:                |
|                                                                           |
|     ZCPR3+ Env                                                            |
|     ZSDOS Clock                                                           |
|     Hard Disk Support                                                     |
|     Warm Boot from RAM                                                    |
|     RAM Disk (M:)                                                         |
|     Full Error Messages                                                   |
|  _                                                                        |
\---------------------------------------------------------------------------/
```

All messages in the above sample screen through the line "...installing Banked System" are printed by LDSYS. All subsequent lines in the above screen are displayed from the newly-loaded Bios. During alteration, or modification of a new system, this subdivision in the display areas may be a clue to any difficulties encountered. The position of the cursor at the bottom of the sample screen is the point at which the new Bios, now in control, attempts to load the Startup file defined in the B/P Header. If none is found, additional initialization will not be performed, and you will see only the prompt for Drive A, User 0.


### 6.15.2 LDSYS Error Messages

`*** No file specified ! ***`

LDSYS was called without a specifying file to load. You may reinvoke it directly with the ZCPR "GO" command as: `GO filename` or call it in the normal fashion specifying an image file to load.

`--- Ambiguous File: fn[.ft]`

At least one question mark (or expanded asterisk) was detected in the specified file to load. Re-execute with an unambiguous file name.

`--- Error Opening: fn[.ft]`

The specified image file could not be located. Common causes for this are a mismatch in the file name, no file with the default type of `.IMG` or an inability to find the file along the Dos Path or in a PUBlic directory.


## 6.16 MOVxSYS - Boot Track System Utility

This routine is a program to generate a bootable system image for the boot tracks of a Floppy or Hard Disk. It is customized for each type of hardware system using the B/P Bios. The generic name MOVxSYS translates to a specific name reflecting the standard name ID, examples of which are:

| Utility | Description |
| :--- | :--- |
| `MOVYSYS` | YASBEC |
| `MOVAMSYS` | Ampro Little Board |
| `MOV18SYS` | MicroMint SB-180 |


### 6.16.1 Using MOVxSYS

This program is patterned after the original `MOVSYS.COM` distributed with most Digital Research CP/M 2.2 systems, but extensively updated to reflect the Z-System standard Help, entry of a base address or system size in kilobytes, and additional checks needed to insure B/P standards.

Two basic parameters may be passed to this program as arguments on the command line. The first specifies the system size in either the equivalent number of kilobytes in an equivalent CP/M 2.2 system, or as the base address of the Command Processor. MOVxSYS parses the first element to determine if the value is a Hexadecimal number ending in the letter "H", and assumes that the value specifies a starting address if so. Valid addresses must be greater than 8000H to insure that the resident portion of the operating system in the Common Memory area. If the argument is not a Hexadecimal address, it is assumed to be a number of kilobytes in the range of 39 to 63. These sizes are based on the "standard" CP/M component elements of 2k bytes for the Command Processor, 3.5k bytes for the Basic Disk Operating System, and at least 1.5kbytes for the resident Bios portion. Several checks are performed within MOVxSYS and the initial executing portion of the Bios (Cold Boot) to detect invalid locations and incorrectly sized data areas.

The second parameter which may be specified on the command line is an optional asterisk ("*") or File Name and Type after the size specification. If an argument is present, one of two actions will be taken. The Asterisk instructs the program to relocate the system image to the specified size, and simply retain it in memory upon exitting without saving the image to disk. Any other characters will specify the name of a file under which name the image should be written to disk. If no second argument is given, the image will be written under a file name of SYSnnK.BIN where "nn" will be the number of kilobytes in the system size described above rounded down to the nearest even number.

Placing a system image on the Boot Tracks of a disk is done by BPSYSGEN (see 6.6) which may be done by immediately following MOVxSYS (invoked with the asterisk argument) by BPSYSGEN using the "Image in Memory" selection, or by specifying a file output from MOVxSYS, and invoking BPSYSGEN with the name of the resultant file.

If you reconfigure the Bios for your system with the goal of modifying the Boot System, you must assemble B/P Bios in the Non-Banked Mode by setting the `BANKED` equate to NO, and setting the `MOVCPM` equate to YES in the `DEF-xx.LIB` file (see 4.2). The revised Bios may then be added to `MOVxSYS.COM` with INSTAL12 (see 6.13) to produce a customized Boot System reflecting your tailored needs. Refer to Chapter 3 for a more complete description of the installation process.


### 6.16.2 MOVxSYS Error Messages

`**** Start < 8000H !!!`

A size value or CPR Starting address was specified which results in a base address less than 8000H. Since the lower 32k of memory (0..7FFFH) may be banked, the CPR MUST be in the upper half of memory. Execute the program again with an adjusted size specification.

`**** Create Error !`

The program could not create the specified Binary output file. Possible causes are a full directory, Write Protected diskette, or bad media or drive.

`**** Write Error...Exiting`

An error occurred while writing the specified Binary output file. Possible causes are a media or drive error, or a disk with inadequate storage space for the file.

`**** Close Error !`

An error occurred while attempting to close the specified Binary output file. This is usually due to a media or drive error.

`**** Size must be in 39..63 !!`

MOVxSYS was invoked with an invalid size (number of K) specification. Execute the program again with an adjusted size specification.

`**** Bad Syntax !!`

The program became confused and could not properly decide what you wanted it to do. Review the built-in help by entering: `MOVxSYS //` and follow the syntax listed.


## 6.17 PARK - Hard Drive Head Park Utility

PARK is a simple B/P Utility routine that moves the Hard Drive heads on all drives to the designated landing zone (also called shipping or park zone) if defined for the type of Controller/Drive in your system. When all drives are parked, the utility executes a HALT instruction which requires a hardware reset or power-off/power-on sequence to overcome. To avoid the possibility of Hard Drive damage by removing power from drives while the heads are positioned over data storage portions of hard drives, PARK should always be executed prior to turning your computer off. This recommendation is particularly important for drives which do not feature automatic hard parking, or where such hardware features have failed.


### 6.17.1 Using PARK

This utility is simply called with no arguments, and sequentially scans all three possible Hard Drive units, executing the SCSI "Stop Unit" command on each. When all three units have been processed, the processor disables interrupts and executes a HALT instruction to prevent the units from becoming reactivated by subsequent instructions. Normally, only cycling the power or pressing the Reset button on the computer will allow processing to resume. Developing the habit of executing HALT before turning your computer off may result in increased life from your hard drives, and should become routine.

This utility is a specialized version of SPINUP (see 6.20) which permits individual units to be turned off and on during normal operation.


### 6.17.2 PARK Error Messages

`+++ Not B/P Bios ... aborting +++`

An attempt was made to execute PARK under a Bios other than B/P, or modifications made to the Bios altered the locations or values needed to correctly identify the system.

`+++ Can't Park this type of Controller! +++`

PARK was executed with a type of Controller or drive in the Bios that does not implement the "Stop Unit" SCSI function.

`**** SCSI Block Length Error !`

The Bios does not support the Extended Commands necessary to park the heads using the "Stop Unit" SCSI Function. This is most probably due to changes during an edit/assembly of the Bios which altered either the Command Descriptor Block size, or the Hard Drive function which returns the values.


## 6.18 SETCLOK - Real-Time Clock Set Utility

This utility provides a means of setting a B/P Bios clock from a physical clock contained in the ZSDOS CLOCKS.DAT library. It presents a similar interface to the ZSDOS 1 utility TESTCLOK from which it was derived.


### 6.18.1 Using SETCLOK

SETCLOK is invoked by entering its name with an optional Clock Driver Number. For initial testing, or trying different clocks (always a dangerous procedure), simply enter the utility name as:

`SETCLOK`

You will be asked whether to extract clocks from a library. If you are using a custom clock, answer No. If you wish to use a clock from the prepared ZSDOS library, enter Yes which is the default setting if a Carriage Return is entered. You will also be asked for the location (Drive/User) of the clock file or library. This prompt sequence may appear as:

```generic
Extract Clock from Library ([Y]/N) : _
Location of CLOCKS.DAT [B0:] : _
```

Drive B, User 0 illustrated in the above sample prompt will probably differ in your system with the current drive and user always shown as the default location. If the file is on the currently-logged drive and PUBlic, it will also be found without specifying a unique User area. If the default reflects the location of the `CLOCKS.DAT` file, or a location accessible via the PUBlic feature, simply enter a carriage return, otherwise enter the location of `CLOCKS.DAT`, followed by a colon and a carriage return. A list of over 40 available clocks will appear. To select one of these clock drivers, enter the number corresponding to the clock, and the program will do the rest. Various messages will be displayed as the clock driver is loaded, linked and executed. If all goes well, the final message will be the Date and Time read from the clock followed by message that the B/P Bios Clock was Set Ok.

Alternatively, a clock driver may be selected for automatic execution according to a specification on the command line. To use this mode, the `CLOCKS.DAT` file must either be in the currently-logged Drive and User, or on the current drive with the PUBlic Attribute bit set. the syntax for this method of setting the B/P Bios clock is:

`SETCLOK nn`

where "nn" is a number corresponding to one of the clocks in the `CLOCKS.DAT` file. This method of operation may be used to set the Bios clock within an alias script such as `STARTUP.COM` commonly used when the computer is first booted.


### 6.18.2 SETCLOK Error Messages

Some of the errors in the SETCLOK utility are generated by the top-level program. These errors consist of:

`+++ This is only for Z80 type computers!!!`

This routine will only operate with Z80 or compatible processors since it is a B/P Bios utility which is also restricted to these types.

`-- Error in locating Clock file`

This routine could not find the `CLOCKS.DAT` Library. Insure that the library either exists in the currently-logged directory, can be found via the PUBlic feature, or is available along the DOS Path.

Other errors are generated in the process of extracting and validating the driver selected from the `CLOCKS.DAT` library. Such errors consist of:

`-- Error Opening : clockname`

The Selected Clock driver in the Library could not be opened. This is most often due to corruption of the `CLOCKS.DAT` file. Restore it from your ZSDOS backup disks and try again.

`-- Error Reading : fn.ft`

An error occurred while reading the Clock code from the library. This also is most often due to corruption of the `CLOCKS.DAT` file.

`-- Error in : clockname`

An error occurred in the logical relocatable structure of the selected clock driver.

`-- Error initializing DAT file`

An error was encountered in initializing the `CLOCKS.DAT` Library.

`-- Memory overflow in DAT file`

A memory allocation error occurred in the Clock routine which caused the allocated memory to be exceeded. This should not occur in any of the library clock drivers, but may be experienced if the guidelines are not followed when developing a custom clock.

Still other errors relate to the reading and linking of the selected clock routine whether it is from the Clock Library, or loaded as a Standalone driv- er. These errors include:

`+++ Can't find : CLOCKS.DAT`

SETCLOK could not find the referenced Clock file. This error will be seen if an attempt is made to use a standalone clock driver which could not be found in the current Drive/User, via the PUBlic attribute, or along the Dos path.

`+++ Error on file open`

An error occurred while trying to open a standalone clock file. Insure that the file was correctly assembled and try again.

`+++ Error sizing : fn.ft`

The selected clock file contained erroneous or invalid sizing information. If this is reported from the `CLOCKS.DAT` file, reload the file from your ZSDOS backup disk and try again. If it is reported while loading a standalone clock, it is most often due to incorrect specifications of the CSEG/DSEG/Named Common areas within the Clock template. Insure that the clock specifications were followed, reassemble the driver and try again.

`+++ Link Error : nn in file : fn.ft`

An error occurred while linking the relocatable code from a clock driver. The "nn" reported is an indicator to the exact nature of the error. Consult the authors if you cannot resolve the error.

The final two errors are indicators that errors occurred after the clock driver has been loaded, linked, and validated. If either of these occurs, it is most often due to selection of an incorrect clock driver, problems with the hardware controlling the selected clock, or alterations to the B/P Bios code which altered the specified interface.

`-- Clock Not Ticking --`

The selected clock driver could not detect an active clock. This is most often the result of selecting the incorrect driver, or setting incorrect values when asked for specific addresses or values when activated.

`-- Error Setting B/P Bios Clock !!`

The Bios reported an error while attempting to set the B/P Bios clock. This is most often caused by errors when modifying the module `CLK.Z80`.


## 6.19 SHOWHD - Partition Display Utility

SHOWHD is a utility which is furnished with the B/P Bios package as an aid in converting existing systems to B/P Bios without losing data, particularly on Hard Drives. It is not specific to B/P Bios and should properly execute on any CP/M 2.2-compatible system. Its purpose is to display the current Hard Drive Partition settings so that you may configure a B/P Bios in either source code, or image form (with BPCNFG) to reflect the same partitioning data.


### 6.19.1 Using SHOWHD

This routine is a basic utility which is normally infrequently, so frills were not added. It expects no arguments and only operates in an interactive mode. To execute it, simply enter:

`SHOWHD`

You will be prompted to enter a drive letter. When entered, you will be presented with a display listing the logical parameters for the drive. A sample of execution is:

```generic
/---------------------------------------------------------------------------\
|  Show Hard Drive Partition Data - 2 Nov 91                                |
|                                                                           |
|   Enter Drive Letter [A..P] : C                                           |
|                                                                           |
|   Drive: C                                                                |
|           DPH Info                BPCNFG Info                             |
|                                                                           |
|                                                                           |
|     Sectors/Track  = 64           (same)                                  |
|     Blk Shift Fctr = 5            4k/Block                                |
|     Block Mask     = 31                                                   |
|     Extent Mask    = 1                                                    |
|     Disk Blocks-1  = 4999         20000k Total (2500 Tracks)              |
|     Max Dirs - 1   = 1023         1024 Dir Entries                        |
|     Alloc bytes    = FFH, 00H                                             |
|     Check Size     = 0                                                    |
|     Track Offset   = 3500         (same)                                  |
|  _                                                                        |
\---------------------------------------------------------------------------/
```

### 6.19.2 SHOWHD Error Message

Only one message may be displayed from the utility. It is:

`+++ Invalid Drive : d`

The Drive Letter selected was not a valid drive within the Bios.


## 6.20 SPINUP - Hard Disk Motor Control Utility

SPINUP is a generic B/P utility to directly control the heads and motors of newer SCSI drives. It moves the heads on the specified hard drive unit to the designated shipping or park zone and may turn the drive motor off if called to Stop the unit and that feature exists in the drive. If called to Start the unit, the drive motor is turned on (if applicable) for the specified drive unit and the heads are positioned to Cylinder 0. This routine may be used as a power conservation feature where operation can be continued for periods of time from RAM or Floppy drives without need to access the hard drive unit. Attempts to access a unit which has been "spun down" with SPINUP will result in an error. This routine is essentially a generic version of PARK (see 6.17) and is furnished in source code form to demonstrate methods of interfacing to Hard Drives from Application Programs.


### 6.20.1 Using SPINUP

This utility was written for use primarily in battery-operated systems where power conservation is desired. Generally, only the newer SCSI drives respond to the Stop/Start Unit commands by controlling the drive motors and positioning the heads over the designated "Landing Zone". SPINUP is Command-Line driven and expects an argument consisting of a valid Unit Number for the physical Hard Drive unit (see 5.2.1, `CONFIG+61`). Valid Unit Numbers are "0", "1" and "2".

Stopping the unit is indicated by preceding the Unit Number with a minus sign as:

`SPINUP -0`

which will cause Unit 0 to park the heads and remove power from the drive motor if possible. Starting the unit is indicated by simply passing the Unit Number as an argument as:

`SPINUP 0`

Whether starting or stopping a Hard Drive Unit, SPINUP monitors the unit status after issuing the command and reports the status of the drive when results of the operation are received. Results are returned as; the unit is Stopped, Started, or an error has occurred (see 6.20.2 below).

Prior to using SPINUP to stop a hard drive, you must insure that accesses to any logical drive on that unit will not occur while the unit is stopped by either exchanging logical drives with BPSWAP (see 6.5) or altering the Command Processor and Dos Search Paths with the ZSDOS Utility ZPATH. For example, if your system includes a partition on the subject Hard Drive as Drive A:, you have logged onto a RAM Drive as M: and the unit is stopped, ZCPR3 and ZSDOS may attempt to find a file on drive A: which will result in a Read Error. In this example, you may either swap drive A: with M:, insuring that M: is not in either Path, or set both paths to exclude drive A:


### 6.20.2 SPINUP Error Messages

`+++ Not B/P Bios ... aborting +++`

An attempt was made to execute SPINUP under a Bios other than B/P, or modifications made to the Bios altered the locations or values needed to correctly identify the system.

`+++ Can't handle this Controller Type! +++`

The Controller Type within the Bios cannot handle the "Stop/Start Unit" SCSI Commands.

`**** SCSI Block Length Error !`

The Bios does not support the Extended Commands necessary to turn the drive on and off using the "Stop Unit" and "Start Unit" SCSI Functions. This is most probably due to changes during an edit/assembly of the Bios which altered either the Command Descriptor Block size, or the Hard Drive function which returns the values.

`**** Invalid Unit # !`

The specified unit number was not "0", "1" or "2". Only three physical Hard Drive units are recognized in B/P Bios.


## 6.21 TDD - SmartWatch Support Utility

TDD is a customized version of the ZSDOS utility TD. With ZSDOS2 systems, it used to display, set or update the B/P Bios clock. This latter capability only exists with the Dallas SmartWatch (DS-1216E) or JDR No-Slot-Clock in the Ampro Little Board, SB180 or YASBEC.


### 6.21.1 Using TDD

TDD obtains the system Time and Date with a DOS Function 98 and displays the information on your console. Your system Must have an installed clock driver to use this utility. If the clock driver supports a set function, TDD can set the Date and Time using DOS Function 99. When setting the clock, TDD will allow you to operate in either an Interactive or Command Line driven mode.

TDD responds to the standard Help request described in Section 1.7. You may obtain a brief usage description by entering:

`TDD //`

You may obtain the current Date and Time from the system clock by simply entering the program name as:

`TDD`

If you are using a Dallas 1216E-based clock, you can set the B/P Bios clock directly by entering:

`TDD U`

A continuous display may be obtained which will update every second until any key is depressed by entering:

`TDD C`

The system clock may be set in the Interactive mode by entering the program name followed by the "S" parameter as:

`TDD S`

You will then be asked to enter the date. The prompt will display the format in which the date will be accepted (US or European) as either:

`Enter today's date (MM/DD/YY):` (US)

or

`Enter today's date (DD.MM.YY):` (European)

Date fields (month, day, and year) may be either one or two digits in each position. Invalid entries such as an invalid day for the entered month will cause the prompt to be re-displayed for a new entry.

When a valid date has been entered, you will be prompted for the current time.

The prompt will vary depending on whether you are using a Real Time Clock, or the Relative counter substitute for a clock. The two prompts are:

`Enter the time (HH:MM:SS):` (Real Time Clock)
`Enter the relative time (+XXXX):` (Relative Counter)

Time is assumed to be in 24 hour format when a Real Time Clock is being used. Seconds may be omitted when setting the clock. When the relative clock is used, a '+' must prefix the count to which you wish to set the Relative Counter. Counts from +0 to +9999 are permitted.

When the time entry is ended with a carriage return, the date and time will not be automatically set. A message will prompt you to press any key. At this point, the next key depression (other than shift and control) will set the clock. This procedure allows you to accurately synchronize the time with one of the many accurate time sources.

Command Line setting of the clock is initiated by entering the program name followed by the date and optional time. The date must be in the correct form (US or European) for the configured TDD. If an error is detected in a Command Line clock set, TDD switches to the interactive mode and prompts for date and time as described above.


### 6.21.2 Configuring TDD

TDD can be configured to present the time in either the US format of month, day, year as: Sep 18, 1988, or the European and military style as: 18 Sep 1988. Likewise, the set function accepts a US format of MM/DD/YY or the European DD.MM.YY. The default may be set with Al Hawley's ZCNFG utility using data contained in the TDD.CFG file on the distribution disk.


### 6.21.3 TDD Error Messages

Error messages for TDD are simple and are mostly self-explanatory. For clarity, however, they are covered here.

`SORRY! ZSDOS or ZDDOS is required to run this program!`

You tried to run this with someone else's DOS. Use ZSDOS or ZDDOS. This error aborts to the Command Processor.

`*** NO Clock Driver installed!!!`

You tried to read a clock which does not exist. Install a clock with SETUPZST and try again. This error aborts to the Command Processor.

`*** Clock does NOT Support SET!!!`

The clock driver on your computer will not permit you to set the time with TDD. This error aborts to the Command Processor.

`*** Must have B/P Bios to use!!!`

This utility only functions under B/P Bios. If you are using B/P Bios and this message appears, it is most probably due to edit/reassembly of the Bios source which altered critical values in the data structures.

`*** Hardware Type Not Supported ! ***`

Since TDD is integrally tied to specified hardware platforms, it will only function if the running computer is one of the types for which the correct code has been implemented. This error should not appear unless the "U" or "S" command is issued.

`++ Insufficient Memory! ++`

The base of available memory has been reduced below that needed for the portion of TDD which is relocated to high memory. The most common cause of this is the addition of Resident System Extensions (RSXs) which cause the top of the TPA to be reported as below 8100H.

`*** Error in Data Input`

An invalid character or number was entered when trying to set the date and time. This error will cause the Interactive mode to be entered and issue a prompt to re-enter correct date/time.

`*** Must be wheel to set clock!`

An attempt was made to set the clock without Wheel access. Use ZSCONFIG (ZSDOS 1) or ZSCFG2 (ZSDOS2) to set a valid Wheel byte, or disable it (see 6.22 for ZSCFG2 or the ZSDOS 1 manual for ZSCONFIG). This error aborts to the Command Processor.

`*** Must have Z180 Processor!!!`

This error may be received if the ID tag identifies the Bios for a computer with a Z180/HD64180, but the check for this CPU failed. It is probably due to incorrect porting of the Bios or manipulation of the header structure.

`*** Must have Z180 to Set No-Slot-Clock!!!`

Similar to the error above, but will appear when trying to set the clock under al altered system.

`**** Can't find No-Slot-Clock!`

The JDR No-Slot-Clock/Dallas DS-1216E SmartWatch could not be validated in the system. This message will be seen if TDD is executed without the clock installed, or the clock has failed for some reason.


### 6.21.4 NOTES Spring 2001

TDD has been extended to more clocks than the DS-1216E cited in this manual. It handles the clocks in all supported B/P BIOS versions.


## 6.22 ZSCFG2 - ZSDOS2 Configuration Utility

ZSCFG2 is a program to configure various parameters of a ZSDOS2 Operating System. It is included in this manual due to the close interaction of all parts of an operating system, particularly the Banked and Portable BIOS. ZSCFG2 operates in either an interactive (novice) or command line driven (expert) mode for maximum flexibility and ease of use. If your computer is running ZCPR3, the Z3 Environment is automatically detected and ZSCFG2 will use video attributes such as reverse video and cursor addressing to enhance the display.

As in all of our support routines, a brief on-line help message is available by entering the name followed by two slashes as:

`ZSCFG2 //`

This configuration tool automatically tailors itself to the ZSDOS2 system, and all messages, from Help to Interactive prompts will accurately reflect the options and status for the running configuration of ZSDOS2.


### 6.22.1 ZSCFG2 Interactive Use

To start ZSCFG2 in the interactive mode, simply enter the program name as:

`ZSCFG2`

If a valid ZCPR3 environment is located, the screen is cleared, and you will see a screen containing needed addresses from the environment, and a tabular display of the current settings within the operating ZSDOS2 system. Reverse video is used to enhance the display if available. If you are using a computer which is not equipped with ZCPR3, or cannot support direct cursor addressing, the information (less ZCPR3 addresses) is simply scrolled up the screen, one line at a time. The only content differences between the two displays is that no data on the ZCPR3 environment will be displayed. An example of a ZSDOS2 display is:

```generic
/---------------------------------------------------------------------------\
|    ...Configuring ZSDOS Ver 2.0         Z3 Environment at  : FE00H        |
|                                         ZCPR Path Address  : FDF4H        |
|                                              Wheel Byte at : FDFFH        |
|                                                                           |
|         1 - Public Files           : YES                                  |
|         2 - Pub/Path Write Enable  : NO                                   |
|         3 - Read-Only Vector       : YES                                  |
|         4 - Fast Fixed Disk Log    : YES                                  |
|         5 - Disk Change Warning    : NO                                   |
|         6 - Path w/o System Attr   : YES                                  |
|         7 - DOS Search Path        : Enabled - Internal                   |
|         8 - Wheel Byte Protect     : Enabled  Addr = FDFFH                |
|         T - Time Routine (Clock)   : F168H                                |
|         A - Stamp Last Access Time : Disabled                             |
|         C - Stamp Create Time      : EEB2H                                |
|         M - Stamp Modify Time      : EEBCH                                |
|                                                                           |
|  Entry to Change ("X" to EXIT) : _                                        |
\---------------------------------------------------------------------------/
```

The type of Operating system and version number are first displayed, followed by any ZCPR3 Environment information needed. If no environment is located, you will see a message to that effect. In such a case, certain options will be restricted as covered later in detailed descriptions.

Interactive operation consists simply of entering the number or letter in the left of each line to select a function. If you select numbers between one and six, the option is changed from OFF to ON or vice versa, and the menu and status are again displayed. If you select any of the other items, you will be asked for more detailed information. Section 6.22.2 below contains a detailed description of all options.


### 6.22.2 ZSCFG2 Command Line (Expert Mode) Use

Command line entry (or Expert Mode) provides the ability to dynamically set ZSDOS options within STARTUP scripts, ZCPR Alias files, Submit files, or directly from the your console. This permits the operating system parameters to be tailored to specific applications, and restored upon completion. For example, a submit or alias command might feature the following sequence:

```generic
Disable/Enable ZSDOS features and set addresses
...Process application programs
Restore ZSDOS features and addresses and return
```

Tailoring of ZSDOS in this sequence would be via a call to ZSCFG with arguments passed on the command line within the script. In this fashion, you do not have to constantly attend the computer to change DOS parameters.

Settings are passed to ZSCFG as groups of characters separated by one or more tabs, spaces or commas. Each group of characters begins with a Command character which identifies the setting to be changed. In the case of the items related to time and date, a two-character sequence is used. A "+" sign identifies the Command as a Clock, or Time Stamp-related function, and the following Command character tells which parameter of the six is to be changed. Command Identifiers for ZSDOS are:

| Option | Description |
| :---: | :--- |
| `P` | Public File Support |
| `W` | Public/Path Write Enable |
| `R` | Read-Only Drive Sustain |
| `F` | Fast Hard Disk Relog |
| `!` | Disk Change Warning |
| `S` | Path without SYStem Attribute |
| `>` | ZSDOS Search Path |
| `*` | Wheel Byte Write Protect |
| `C` | Clock Routine Address |
| `+A` | Stamp Access Time |
| `+C` | Stamp Create Time |
| `+M` | Stamp Modify Time |

Options which are simply On/Off toggles require no arguments. You enable them merely by entering the Command Identifier(s). To disable such options, you simply append a minus sign ("-") to the end of the Identifier. For example, a command line entry to activate the Fast Relog capability for hard disks, turn PUBlic bit capability on, and disable the Disk Change warning would be:

`ZSCFG2 F,!-`

Certain options require additional parameters which are handled by a secondary prompt in the interactive mode. Since no prompt can be issued in the Command Line entry mode, the added parameters are passed by appending them to the Command Identifier. An example to set the Wheel Byte Write Protect to be the same as the ZCPR3 Wheel Byte, Activate the Internal path and set the Clock address to the standard B/P Bios Clock Vector is:

`ZSCFG2 *Z,>I,CB`

You must remember that NO spaced or other delimiters (spaces, tabs and commas) are permitted between the Command Identifier and added arguments. An "Invalid" error will generally be the result if you forget. When entering ad- dresses or numbers as arguments, they are always in Hexadecimal (base 16) with optional leading zeros. The algorithm used to interpret the number entered only retains up to four digits. Therefore, if you enter the sequence "0036C921045", it would be interpreted as 1045H.

The following section describes each option and what alternatives are available to optimize it for your system.


### 6.22.3 ZSCFG2 Option Descriptions

The two tools which permit tailoring of a ZSDOS2 system to your specific needs, INSTAL12 and ZSCFG, both present the same interactive display. This section, therefore, is applicable to installation as well as "on the fly" customization with ZSCFG2. Each option will also include specific arguments for Command Line entry of the option. Options will be covered in their order of appearance in the INSTAL12 and ZSCFG2 interactive menus.


#### 6.22.3.1 Public Files

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 1 - Public Files |
|                     | (toggle) |
| Command Line Character: | P |
| Enable  | P  |
| Disable | P- |

This flag controls recognition of the Plu*Perfect PUBlic attribute bit (Bit 7 of the second letter in the file name). When set to YES or activated, any file having this bit set will be accessible from any user area on the disk. This means that a search for the file will locate it on the first try, regardless of which User Area is currently selected (see 2.9.4, Public Access). If set to NO, the file will be private and can only be found if the user area matches that of the file. The default setting for this option is YES, to recognize PUBlic files.


#### 6.22.3.2  Public/Path Write Enable

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 2 - Pub/Path Write Enable |
|                     | (toggle) |
| Command Line Character: | W |
| Enable  | W  |
| Disable | W- |

When set to YES or activated in Command Line mode, ZSDOS2 will permit write operations to Public files, and in the case of ZSDOS2, files located along the Path. When set to NO or disabled, attempts to write to the file will result in a "Read-Only" error. The default setting for this option is NO.


#### 6.22.3.3 Read-Only Vector Sustain

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 3 - Read-Only Vector |
|                     | (toggle) |
| Command Line Character: | R |
| Enable  | R  |
| Disable | R- |

When set to YES or activated, the normal Write Protect vector set by ZSDOS2 function call 28 will not be cleared on a warm boot as with CP/M and ZRDOS. If set to NO or disabled, the Write Protect vector will function as in CP/M and ZRDOS. The default setting for this option is YES.


#### 6.22.3.4 Fast Fixed Disk Relog

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 4 - Fast Fixed Disk Log |
|                     | (toggle) |
| Command Line Character: | F |
| Enable  | F  |
| Disable | F- |

When set to YES or enabled, the allocation bit map for a fixed drive (one in which the WACD buffer is zero) will not be rebuilt after the initial drive logon. This results in much faster operation for systems with Hard Disks and RAM disks. If set to NO or disabled, the allocation map will be rebuilt each time fixed disk drives are initially selected after a warm boot. The default setting for this option is YES.


#### 6.22.3.5 Disk Change Warning

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 5 - Disk Change Warning |
|                     | (toggle) |
| Command Line Character: | ! |
| Enable  | !  |
| Disable | !- |

When set to YES or enabled, a warning will be printed whenever ZSDOS2 detects that a disk in a removable-media drive (normally floppy disk drives) has been changed. If you press any key other than Control-C, ZSDOS2 will automatically log in the new disk and continue. If set to NO or disabled, no warning will be given, and the disk will be automatically logged, and the operation in progress will continue. The default setting for this option is NO, for no displayed message.


#### 6.22.3.6 Path Without System Attribute

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 6 - Path w/o System Attr |
|                     | (toggle) |
| Command Line Character: | S |
| Enable  | S  |
| Disable | S- |

When set to YES or enabled, Public files on drives along the Path will be found without the System Attribute being set (see 2.9.2, Path Directory Access mode). If this option is set to NO or disabled, Public files on drives addressed along the Path will not be found unless the System Attribute Bit (bit 7 of the second character in the filetype) is set (see 2.9.3, Path File Access mode). The default setting for this option is NO or Disabled, requiring the Public bit Set on accessible files.


#### 6.22.3.7  DOS Search Path

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 7 - DOS Search Path |
|  Options | (D)isable |
|  | (S)et addr |
|  | (I)nternal |
|  | (Z)CPR3 (only if running ZCPR3) |
| Command Line Character: | > |
| Enable  | >addr |
|         | >I |
|         | >Z (only if running ZCPR3) |
| Disable | >- |

When this option is selected from the Interactive mode, you will be prompted for one of the three options. Contrary to the earlier ZSDOS1 configuration, a ZCPR3 style Environment Descriptor is required, so the following prompt will always be displayed:

`DOS Path [(D)isable, (S)et, (I)nternal, (Z)CPR3] :`

Operating ZSCFG2 in the Command Line mode permits you to select the same options directory from the command line as summarized above. No additional characters are required for Disable, Internal or ZCPR3 path selection. If you choose the (S)et option, you will be prompted for a Hexadecimal address with:

`Enter PATH Address :`

If you Disable the DOS Path option, ZSDOS2 functions just as CP/M 2.2 and ZRDOS for file searches. Requests for files will access only the currently logged disk and user, modified only by the Public capability, if active. This results in the familiar requirement to install utilities such as compilers, word processors and data base management systems to tell them where to go to find their overlays.

Proper use of the DOS Path overcomes the limitation in finding program overlays and other files by simply setting the DOS Path to the drive and user area where the relevant overlays and other files are stored. The Path may be set in three ways.

The first way is to assign a fixed address using the (S)et option from the Interactive Mode, or by appending the address to the Command Character in the Command Line mode. You will be responsible for insuring that any path at that address conforms to proper ZCPR3 path definitions.

The second way to set a DOS Path is to use the three element Internal path by selecting the (I)nternal option from the Interactive Mode, or adding an "I" after the Command Character in the Command Line mode. As distributed, ZSDOS contains a single path entry of "A0:" to direct path searches to User Area 0 on Drive A. An alternative way to activate the Internal Path is with the `ZPATH.COM` utility made available with ZSDOS1. ZPATH will enable you to change the default path, and define up to three drive/user search elements.

The final method of setting a DOS Path is only available if you are operating a ZCPR3 system. It is chosen by selecting the (Z)CPR3 option from the Interactive Mode, or following the Command Character with a "Z" in the Command Line mode. This Path mode will probably see little use, but is made available for systems which need more than three elements in a path.

The principal disadvantage of using the ZCPR3 path is that requests from the command prompt (e.g. `A0>`) may result in n-squared searches where n is the number of elements in the path. The reason is that ZCPR3 will select the first path element, and ZSDOS will sequentially search along the entire path if the file is not found, returning to ZCPR3 with a "file not found" error. ZCPR3 will then select the second element with ZSDOS again searching along the entire file. This situation does not occur once an application program is started, since the ZCPR3 Command Processor is no longer active.

The default setting for the DOS Path is "Internal".


#### 6.22.3.8 Wheel Byte Write Protect

|  | Description |
| ---: | :---: |
| Interactive Prompt: | 8 - Wheel Byte Protect |
|  Options | (D)isable |
|  | (S)et addr |
|  | (Z)CPR3 |
| Command Line Character: | * |
| Enable  | *addr |
|         | *Z |
| Disable | *- |

When you select this option from the Interactive mode of ZSCFG, you will presented with an additional lines containing available choices as:

`Wheel [(D)isable, (S)et, (Z)CPR3] :`

Selecting the (D)isable option by entering a "D" or disabling the Wheel Byte with the "*-" parameter string in the Command Line mode will cause ZSDOS2 to assume that the Wheel byte is always ON giving the user full privileges in file control (Writes, Renames and Erasures). Entering an "S" for (S)et from the Interactive mode will allow you to enter a Hexadecimal address for a Wheel Byte. It is your responsibility to insure that the byte is protected as necessary from unintentional alteration. Setting a Wheel Byte address from the Command line simply requires appending a Hexadecimal address after the Wheel Command Character. Entering a "Z" from the Interactive mode, or a "*Z" parameter string in the Command Line mode will set the address to the address defined for the Wheel byte in the ZCPR3-compatible B/P environment. The default for this option is OFF or Disabled to assume that the user has full privileges.


#### 6.22.3.9 Time Routine (Clock Driver)

|  | Description |
| ---: | :---: |
| Interactive Prompt: | T - Time Routine (Clock) |
| Options | (D)isable |
|         | (S)et addr |
| Command Line Character: | C |
| Enable  | C addr |
| Disable | C- |

This option allows the user to enter the address of a clock driver routine conforming to ZSDOS standards, or disable an existing clock routine. When you enter a "T" at the prompt in the Interactive mode, the following appears:

`Time (Clock) Routine [(D)isable, (S)et, (B)ios+4EH] :`

Entering a "D" in the Interactive mode or the Command Line sequence "C-" will disable any existing clock. The primary effect of this is to cause an error return to DOS function calls 104 and 105 as well as disabling Date/Time Stamping functions. If you enter an "S" at this point in the Interactive mode, you will be further prompted for a Hexadecimal address of a clock driver. The same effect of setting a Clock Driver address is achieved in the Command Line mode by entering the "C" Command character followed by a valid Hexadecimal address beginning with a Number. Selecting "B", or entering "CB" as a command line argument, will Set the Dos Clock Driver address to the base of B/P Bios offset by 4EH which corresponds to the Jump Table entry for the B/P ZSDOS-compatible Clock driver. Do NOT enter unknown values since unpredictable results can occur!


#### 6.22.3.10 Stamp Last Accessed Time

|  | Description |
| ---: | :---: |
| Interactive Prompt: | A - Stamp Last Access Time |
| Options | (D)isable |
|         | (E)nable |
| Command Line Character: | +A |
| Enable  | +A |
| Disable | +A- |

This option is only available with DateStamper type of Date/ Time Stamps. For P2DOS, the function is not defined and is ignored within ZSDOS2. As stated in Section 3.4.4.2, Unless you have a definite need to retain a record of the last time files are accessed, we recommend that you disable this option to reduce unnecessary overhead. To Select the Last Access Time option, enter an "A" at the Interactive main prompt. This will display the following prompt:

`Stamp Last Access Time Routine [(D)isable, (E)nable] :`

If you enter a "D" at this point in the Interactive mode or disable the function with the sequence "+A-" in the Command Line mode, no times will be entered in the "Last Accessed" field in the DateStamper file. This option may be re-enabled by selecting the "E" option in the Interactive mode from this secondary prompt, or the sequence "+A" from the Command Line mode.


#### 6.22.3.11 Stamp Create Time

|  | Description |
| ---: | :---: |
| Interactive Prompt: | C - Stamp Create Time |
| Options | (D)isable |
|         | (E)nable |
| Command Line Character: | +C |
| Enable  | +C addr |
| Disable | +C- |

Entry of a "C" from the main menu in the Interactive mode will allow you to enable or disable the Create Time stamping feature. A secondary prompt will be displayed as:

`Stamp Create Time Routine [(D)isable, (E)nable] :`

To disable the Create time, enter a "D" from the secondary prompt, or the sequence "+C-" in the Command Line mode. To enable stamping of Create Times, enter an "E" from the secondary prompt from the Interactive mode, or by entering the Argument Sequence "+C" from the Command Line mode.


#### 6.22.3.12 Stamp Modify Time

|  | Description |
| ---: | :---: |
| Interactive Prompt: | M - Stamp Modify Time |
| Options | (D)isable |
|         | (E)nable |
| Command Line Character: | +M |
| Enable  | +M |
| Disable | +M- |

The time of last Modification of a file is probably the most valuable of the times offered in a ZSDOS system. As such, you will probably never have a need to disable this feature. Should the need arise, however, enter an "M" at the Interactive main prompt. You will then be presented with:

`Stamp Modify Time Routine [(D)isable, (E)nable] :`

If you enter a "D" at this point in the Interactive mode or disable the function with the sequence "+M-" in the Command Line mode, no times will be stored in the "Modify" field of any active Time Stamp activity.

This option may be re-enabled by selecting the "E" option in the Interactive mode from this secondary prompt, or the sequence "+M" from the Command Line mode.


### 6.22.4 ZSCFG2 Error Messages

Only two error messages exist in ZSCFG2. For the most part, any error you see will deal with invalid parameters or entry mistakes. The two error messages are:

`-- Invalid --`

An invalid address or character was entered in a parameter.

`*** ERROR: DOS is not ZSDOS2!`

An attempt was made to run ZSCFG2 on an Operating system which was not ZSDOS2. This program cannot function under any other operating system.


## 6.23 ZXD - File Lister Utility for ZSDOS2

ZXD Version 1.66 is a modification of an earlier version released with our ZSDOS 1 package. It is the ZSDOS Extended Directory listing program derived from the ZCPR3 tool XD III written by Richard Conn and now modified to properly return disk sizing information from a banked ZSDOS 2 Operating System. Many additional capabilities were added over the original XD III, not the least of which is the ability to display time stamps for each file in a variety of formats. ZXD can display file Dates and times from DateStamper, P2DOS, and Plu*Perfect Systems' DosDisk stamp methods. In ZCPR3 systems, the Wheel byte is used to disable some functions as a security precaution in remote access systems.


### 6.23.1 Using ZXD

ZXD is activated by entering its name at the command prompt, and may be followed by optional drive and user specifications to obtain the directory of another drive or user area. It may also be followed by various parameters which alter the format and/or content of the display. If options are listed without being preceded with a File Specification (drive, user, file name), then they must be preceded by the standard option character, a slash. A help message may be obtained in the standard manner by entering:

`ZXD //`

ZXD accepts directions in a natural form popularized with the ZCPR series of Command Processor replacements. Using the conventions described in Section 1.2, the syntax is summarized by:

`ZXD [dir:][afn] [/][options]`

If ZXD is called with no arguments, a display of only those files satisfying built-in default conditions will be displayed. Normally these defaults select only non-system files in the current drive and user. The default selections may be modified by option parameters detailed below. If option parameters are desired without drive, user or file specifications, then the options must be prefixed with a slash. The slash is optional if any redirection or file specifications are entered.


### 6.23.2 ZXD Options

Option parameters, consisting of one or two characters, allow you to obtain selected information from files on a disk, or to tailor the display to your particular needs. Each of these options is also reflected as a permanent default. After deciding which parameters you use most by using the command line options, we recommend configuring ZXD to reflect those parameters as defaults. The results will be the requirement to enter fewer keystrokes, and consequently faster operation when a directory scan is required.

The option characters are described in alphabetical order in the following sections.


#### 6.23.2.1 Select Files by Attribute

In order to avoid cluttering a directory display with unwanted file names, ZXD features a flag which controls addition of those files marked with the SYStem Attribute Bit. The A Option controls this feature. It requires a second character of S, N, or A. Control offered by these characters is:

| Option | Description |
| :---: | :--- |
| `S` | Include Only Files marked with the SYStem Attribute |
| `N` | Include Only Files Not marked with the SYStem Attribute (this is the defalt condition) |
| `A` | Include All Files |

Since listing of all Non-SYStem files is the default condition, you will probably not use the N option very often. The A option, on the other hand, offers a simple way of viewing All files within the current directory, including SYStem files which are normally invisible due to the Attribute bit.

In a ZCPR3 system where Wheel access has not been granted (Wheel byte is Off), this option is forced to Non-SYStem files only and the A option character is not permitted.


#### 6.23.2.2 Date Display Format

The Dates for a ZXD display may be displayed in either US form of MM/DD/YY or European form of DD.MM.YY. You may override the default form with the D option. Here is an example of the two types of date displays:

US Form:

```generic
ZXD  Ver 1.66      3 Apr 1993  15:43:17
Filename.Typ  Size     Modified      Filename.Typ  Size     Modified
-------- ---  ----     --------      -------- ---  ----     --------
INITDIR .COM    4k  07:01-09/17/88   ZPATH   .COM    4k  07:50-09/17/88
ZXD     .COM    8k  08:01-09/17/88
  C2: -- 3 Files Using 16K (324K Free)
```

European Form:

```generic
ZXD  Ver 1.66      3 Apr 1993  15:43:11
Filename.Typ  Size     Modified      Filename.Typ  Size     Modified
-------- ---  ----     --------      -------- ---  ----     --------
INITDIR .COM    4k  07:01-17.09.88   ZPATH   .COM    4k  07:50-17.09.88
ZXD     .COM    8k  08:01-17.09.88
  C2: -- 3 Files Using 16K (324K Free)
```


#### 6.23.2.3 Disable Date (NoDate) Display

While the display of date and time information is the default mode of ZXD, this may be disabled with the N option to display more file names on a screen.


#### 6.23.2.4 Output Control Option

The O option controls ZXD's printer or screen output, and requires a second character which adds additional control to output formats. The second characters recognized are:

| Option | Description |
| :---: | :--- |
| `F` | Send a Form Feed character at the end of the list |
| `H` | Toggle Horizontal/Vertical display of sorted listing |


#### 6.23.2.5 Output to Printer

Option P controls output to the printer. When this option is given, the sorted directory listing is sent to both the console screen and the printer. This option is disabled and not available in a ZCPR3 system where Wheel access has not been granted (Wheel byte is Off).


#### 6.23.2.6 Sort by Name or Type

The default sort condition for ZXD is to first sort by File Name, then by File Type within matching Names. Option S reverses the sequence.


#### 6.23.2.7 Primary DateStamp

ZXD features an algorithm which will attempt to find one of several types of Date/Time Stamps for each file. The default conditions tell ZXD to first attempt to locate DateStamper type of Stamps. If that fails, a search is made for DosDisk stamps from MS/PC-DOS disks, and finally to check for P2DOS type stamps. The T option causes the DateStamper checks to be bypassed, thereby speeding response if DateStamper type stamping is never used.


#### 6.23.2.8 All User Areas

The distribution version of ZXD will only search a single User area, either the currently logged or the explicitly stated area, for files. The U option will locate files in all user areas on the disk. Combining the U with the AA options will list all files in all user areas, both system and non-system, on a disk. This option is disabled and not available in a ZCPR3 system where Wheel access has not been granted (Wheel byte is Off).


#### 6.23.2.9 Wide Display

ZXD only displays the "Last Modified" Date/Time Stamp. This may be reversed by appending the W option to the Command Line, which generates a Wide of all available Stamps. Only DateStamper has provisions for all three stamp categories; P2DOS contains only Created and Modified stamps, while the single MS/PC-DOS stamp accessed through DosDisk best corresponds to "Modified". A display created with this option is:

```generic
Filename.Typ  Size     Created        Last Access      Modified
-------- ---  ----     -------        ---- ------      --------
BU16    .COm    8k  17:26-06/12/88  08:42-08/21/88  17:26-06/12/88
COPY    .COM    8k  15:06-09/17/88                  15:06-09/17/88
ZPATH   .COM    4k  07:50-09/17/88  15:02-09/17/88  07:50-09/17/88
ZXD     .COM    8k  08:00-09/17/88                  08:01-09/17/88
```


### 6.23.3 Customizing ZXD

The configuration utility ZCNFG.COM is used to alter the default settings in ZXD. Settings and text prompts for ZXD are contained in the file ZXD.CFG which must be accessible to ZCNFG for any configuration change. All options are simple ON/OFF, or reversible settings and correspond to the options discussed in Section 6.23.2 above. See Section 4.8 of the ZSDOS 1.0 User Manual or ZCNFG documentation on the Ladera Z-Node for details on using ZCNFG.


## 6.24 Additional Utilities (NOTES Spring 2001)

Several of the utilities documented in this manual have also matured over the years, and some new ones added. Some of the more significant are:

**HASHINI.COM** - This utility prepares a fresh directory for file accesses via the ZSDOS2 hash algorithm implemented in ZS203.ZRL. See the built-in help for more details on use.

**SIZERAM.COM** - Examine and report memory statistics in a Banked system. This utility uses the inter-bank data movement features of a Banked BPBIOS system and will not execute in a non-banked system.

**TURBO.COM** - When using the Z8S180 CPU, this utility allows you to switch the internal divide-by-two circuit in and out of operation resulting in a doubling or halving of the processor speed.

