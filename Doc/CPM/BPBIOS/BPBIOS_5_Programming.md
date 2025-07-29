# 5. Programming for B/P Bios

For most existing purposes, programming for B/P Bios is no different than for standard CP/M 2.2 BIOSes. Even adapting CP/M 3 programs for a B/P Bios should present no great hurdle due to the close similarity retained with the corresponding extended functions. The power of a B/P Bios interface, however, is in using the combined features to produce portable software across a wide variety of hardware platforms by exercising all of the B/P Bios features in concert. This section describes the interfaces available to the programmer of a system using the B/P Bios, and the functions available to ease direct floppy and hard drive accesses for specialized programming in a consistent manner.

One of the architectural flaws which we considered in CP/M Plus was the odd way in which direct BIOS access was handled. We designed B/P Bios to be as compatible with CP/M 2.2 as possible, yet provide the expanded functionality needed in Banked applications. To that end, direct interface with BIOS calls follows CP/M 2.2 conventions as much as possible.

The following pages on programming assume some familiarity with the basic CP/M fundamentals, and with Z80/Z180 assembly language, since it is beyond the intent of this manual, and our literary writing skills, to present an assembly programming tutorial. Should you need additional assistance in this area, please refer to the annotated bibliography for reference material.


## 5.1 Bios Jump Table

The BIOS Jump table consists of 40 Jumps to various functions within the BIOS and provides the basic functionality. It includes the complete CP/M 2.2 sequence, most of the CP/M 3 (aka CP/M Plus) entry points (although some differ in parameter ordering and/or register usage), and new entry points needed to handle banking in a consistent and logical manner.

Bios entry points consist of a Table of Absolute 3-byte jumps placed at the beginning of the executable Image. Parameters are passed to the Bios in registers as needed for the specific operation. To avoid future compatibility problems, some of the ground rules for Bios construction include; No alteration of Alternate or Index registers as a result of Bios calls, and all registers listed in the documentation as being Preserved/Unaffected MUST be returned to the calling program in their entry state.


## 5.2 Bios Reference Card

| Number | Fcn Name | Input Parameters     | Returned Values             | Uses  |
|:------:|:---------|:---------------------|:------------------------    |:------|
|  0     | CBOOT    | None                 | None                        | All   |
|  1     | WBOOT    | None                 | None                        | All   |
|  2     | CONST    | None                 | A= FFH Ready, 0 No Char     | AF    |
|  3     | CONIN    | None                 | A= Char from CON: (masked)  | AF    |
|  4     | CONOUT   | C= Char to send (masked) | None                    | AF    |
|  5     | LIST     | C= Char to send (masked) | None                    | AF    |
|  6     | AUXOUT   | C= Char to Send (masked) | None                    | AF    |
|  7     | AUXIN    | None                 | A= Char from AUX: (masked)  | AF    |
|  8     | HOME     | None                 | _[Status Code]_             | All   |
|  9     | SELDSK   | C= Drive (0=A .. 15=P) | HL= DPH addr, 0 No Drive  | All   |
| 10     | SETTRK   | BC= Track Number     |  None                       | None  |
| 11     | SETSEC   | BC= Sector Number    |  None                       | None  |
| 12     | SETDMA   | BC= DMA Address      |  None                       | None  |
| 13     | READ     | None                 |  _Status Code_              | All   |
| 14     | WRITE    | C= Write Type (0= Unalloc, 1= Dir, Force) |  _<Status Code>_ | All   |
| 15     | LISTST   | None                 | A= FFH Ready, 0 Busy        | AF    |
| 16     | SECTRN   | BC= Logical Sect #   | HL= Physical Sect #         | All   |
| **----** | **----** | **----------** |**<<< End of CP/M 2.2 Vectors >>>** | **----** |
| 17     | CONOST   | None                 | A= 0FFH Ready, 0 Busy       | AF    |
| 18     | AUXIST   | None                 | A= FFH Ready, 0 No Char     | AF    |
| 19     | AUXOST   | None                 | A= 0FFH Ready, 0 Busy       | AF    |
| 20     | DEVTBL   | None                 | HL-> Char IO Table          | HL    |
| 21     | DEVINI   | None                 | None                        | All   |
| 22     | DRVTBL   | None        | HL-> DPH Table if Ok, 0 No Drive     | HL    |
| 23     |          | ***Reserved for MULTIO*** |                        |       |
| 24     | FLUSH    | None                 | _[Status Code]_             | All   |
| 25     | MOVE     | HL= Source adr, DE= Dest adr, BC= Length | None    | All   |
| 26     | TIME     | C= 0(Read) / 1(Set), DE-> 6-byte Time | A= 1 if Ok, 0 Errs, E= Orig 6th byte, D= 1/10th Secs (Read) | All  |
| 27     | SELMEM   | A= Bank Number       | None                        | None  |
| 28     | SETBNK   | A= Bank Number       | None                        | None  |
| 29     | XMOVE    | C= Source bank, B= Dest bank | None                | None  |
| **----** | **----** | **----------** | **<<< End of CP/M 3 "Type" Vectors >>>** | **----** |
| 30     | RETBIO   | None | A= Bios Vers, BC-> Bios base, DE-> Config area, HL-> Device Cnfg Table | A, BC, DE, HL |
| 31     | DIRDIO   | B= Driver Type, C= Fnc # | _see below for Direct Device IO_ |  |
| 32     | STFARC   | A= Bank Number       | None                        | None  |
| 33     | FRJP     | HL= Dest addr        | ??                          | ??    |
| 34     | FRCLR    | HL= Return addr      | ??                          | None  |
| 35     | FRGETB   | HL-> Byte to Get, C= Bank # | A=Byte at (C:HL)     | AF    |
| 36     | FRGETW   | HL-> Word to Get, C= Bank # | DE=Word at (C:HL)    | F, DE |
| 37     | FRPUTB   | HL-> Byte Dest, C= Bank #, A= Byte to Put | None   | F     |
| 38     | FRPUTW   | HL-> Word Dest, C= Bank #, DE= Word to Put | None  | F     |
| 39     | RETMEM   | None                | A= Current Bank Number       | AF    |

_Status Code:_
A= 0, Zero Set (Z) if Operation successfully performed
A <> 0, Zero Clear (NZ) if Errors occured in Operation


**FLOPPY DISK SUBFUNCTIONS (Function 31)**
Input Parameters: B= 1 Floppy, C= Subfcn #
| Number | Fcn Name | Input Parameters     | Returned Values             | Uses  |
|:------:|:---------|:---------------------|:------------------------    |:------|
|  0     | STMODE   | A= 0 (Double Dens), FFH (Single) | None            | AF    |
|  1     | STSIZE   | A= 0 (Normal Speed), 0FFH (Hi capable), D= 0 (Motor On Cont) 0FFH (Motor Contr), E= 0 (Hard), 1 (8"), 2 (5.25"), 3 (3.5") | None | AF |
|  2     | STHDRV   | A= Unit (B0,1) Head (D2) | None                    | AF    |
|  3     | STSECT   | A=Phys Track #, D= 0..3 (128 .. 1024 Sctrs), E= Last Sector # | None | AF |
|  4     | SPEC     | A= Step rate in mS (B7=1 for 8" Drv), D= Head Unload in mS, E= Head Load in mS | None | AF |
|  5     | RECAL    |                     | _[Status Code]_ | AF |
|  6     | SEEK     | A= Desired Trk #, D= 0FFH Verify, E= 0 (Single-step) <>0 (Double) | _[Status Code]_ | AF |
|  7     | SREAD    | HL-> Read Buffer    | _[Status Code]_              | AF, HL |
|  8     | SWRITE   | HL-> Write Buffer   | _[Status Code]_              | AF, HL |
|  9     | READID   |                     | _[Status Code]_              | AF     |
| 10     | RETDST   |  | A= Status Byte, BC= Controller Type, HL-> Status Byte | AF, BC, HL |
| 11     | FMTTRK   | HL-> Format Data, D= Sctrs/Trk, E= Gap 3 Byte Count | _[Status Code]_ | AF |


**HARD DISK SUBFUNCTIONS (Function 31)**
Input Parameters: B= 2 HD, C= Subfcn
| Number | Fcn Name | Input Parameters     | Returned Values             | Uses  |
|:------:|:---------|:---------------------|:------------------------    |:------|
| 0      | HDVALS   | DE-> 512 byte Buff   | A= # Bytes in CDB           | AF, HL |
| 1      | HDSLCT   | A= Device Byte       | A= Physical Device Bit      | AF    |
| 2      | DOSCSI   | DE-> Cmd Desc Blk, A= 0 (No Write Data) | H= Msg Byte, L= Status Byte, A= Masked Status Byte | All  |


## 5.3 Bios Functions

| Function 0 (xx00) | CBOOT Cold Boot |
|---:|:---|
| Enter: | None |
| Exit:  | None |
|        | Execution resumes at CPR |
| Uses:  | All Registers |

Execute Cold Start initialization on the first execution. The jump argument is later overwritten, and points to the IOP Device jump table. The reason for this is that code to perform the initialization is often placed in areas of memory which are later used to store system information as a memory conservation measure. Attempts to re-execute the initialization code would then encounter data bytes instead of executable instructions, and the system would most assuredly "crash".

Among other functions performed during initial execution of the Cold Boot code are; Establishing an initial Z3 Environment if necessary, initializing any Z3 system segments such as an Extended Path, Flow Control Package, Named Directory Buffer and such; setting system-specific values such as the locations of Allocation Vector buffers for RAM and Hard Drives; and executing the Device Initialization routine (see Function 21). The Cold Boot routine usually exits by chaining to the Warm Boot Function (Function 1) to set vectors on Page 0 of the TPA memory bank.

| Function 1 (xx03) | WBOOT Warm Boot |
|---:|:---|
| Enter: | None |
| Exit:  | None |
|        | Execution resumes at CPR |
| Uses:  | All Registers |

This function re-initializes the Operating System and returns to the Command Processor after reloading it from the default drive boot tracks, or banked memory if the Bios was assembled with the Fast Warm Boot option.

Unless altered by an ill-behaved Resident System Extension (RSX) or other operating transient program, the Warm Boot Vector at location 0 in memory points to this vector. Well-behaved programs will not alter this address but should, instead, alter the destination argument of the Jump vector in the Bios header. There is a singular exception to this in the case of NZCOM where the Warm Boot vector points to the NZBIOS, and Not the "Real" Bios. In such a case, the address of the "Real" Bios must be separately determined (See Function 30).

| Function 2 (xx06) | CONST Console Input Status |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0FFH if Char Ready, NZ |
|        | A = 0 if No Char Ready, Z |
| Uses:  | AF |

This function returns a flag indicating whether or not a character has been entered from the Console device selected by the IOBYTE on Page 0 of the TPA Bank. The return status is often used by Transient Programs to determine if the user has attempted to start or stop program execution.

| Function 3 (xx09) | CONIN Console Input |
|---:|:---|
| Enter: | None |
| Exit:  | A = Masked Input Character |
| Uses:  | AF |

This function waits for a character to be entered from the Console device selected by the IOBYTE on Page 0 of the TPA Bank, and returns it to the calling routine. According to strict CP/M 2.2 standards, the Most Significant bit of the input byte must be set to Zero, but this may be altered by the input mask for the Console Device.

| Function 4 (xx0C) | CONOUT Console Output |
|---:|:---|
| Enter: | C = Character to send to Console |
| Exit:  | None |
| Uses:  | AF |

This function sends a specified character to the Console Device defined by theIOBYTE on Page 0 of the TPA Bank. It will wait for the device to become ready, if necessary, before sending the character, and will mask bits as specified in the Character Device Configuration for the device as an Output.

| Function 5 (xx0F) | LIST List Output |
|---:|:---|
| Enter: | C = Character to send to List Device (Printer) |
| Exit:  | None |
| Uses:  | AF |

This function will send a specified character to the List Device (Printer) defined by the IOBYTE on Page 0 of the TPA Bank. It will wait for the device to become ready, if necessary, before sending the character, and will mask it as specified in the Character Device Configuration for the Output device.

| Function 6 (xx12) | AUXOUT Auxiliary Output |
|---:|:---|
| Enter: | C = Character to send to Auxiliary Device |
| Exit:  | None |
| Uses:  | AF |

This function will send a specified character to the Auxiliary Output Device defined by the IOBYTE on Page 0 of the TPA Bank. It will wait for the device to become ready, if necessary, before sending the character, and will mask it as specified in the Character Device Configuration for the Output device.

| Function 7 (xx15) | AUXIN Auxiliary Input |
|---:|:---|
| Enter: | None |
| Exit:  | A = Masked Input Character |
| Uses:  | AF |

This function will read a character from the Auxiliary Input Device defined by the IOBYTE on Page 0 of the TPA Bank. It will wait for a character to be received, and will mask it as specified in the Character Device Configuration for the Input device.

| Function 8 (xx18) | HOME Home Drive |
|---:|:---|
| Enter: | None |
| Exit:  | None |
|        | Heads on selected drive moved to Track 0 |
| Uses:  | All Primary Registers |

This function will position the head(s) on the selected drive to Track 0. In B/P Bios, This operation performs no useful action, and is simply a Return. Pending Write purges and head repositioning is handled by the individual device drivers (Specifically Select Drive functions).

| Function 9 (xx1B) | SELDSK Select Logical Drive |
|---:|:---|
| Enter: | C = Desired Drive (A=0..P=15) |
| Exit:  | (Success) A <> 0, NZ, HL = DPH Address |
|        | (No Drive) A = 0, Zero (Z), HL = 0 |
| Uses:  | All Primary Registers |

This function selects a specified logical drive as the current drive to which disk operations refer. If the operation is successful, the Disk Parameter Header (DPH) address is returned for later determination of the unit parameters If the operation fails for any reason (non-existant drive, unknown or bad media, etc), a Zero value pointer is returned to signify that the drive cannot be accessed through the Bios.

| Function 10 (xx1E) | SETTRK Select Track |
|---:|:---|
| Enter: | BC = Desired Track Number |
| Exit:  | None |
|        | Track Number saved |
| Uses:  | No Registers |

This function stores a specified Logical Track number for a future disk operation. The last value stored with this function will be the one used in Disk Reads and Writes.

**NOTE:** While a 16-bit value is specified for this function, only the lower byte (8-bits) is used in most drivers.

| Function 11 (xx21) | SETSEC Select Sector |
|---:|:---|
| Enter: | BC = Desired Sector Number |
| Exit:  | None |
|        | Sector Number saved |
| Uses:  | No Registers |

This function stores a specified Logical Sector Number for a future disk operation. The last value stored with this function will be the one used in Disk Reads and Writes.

**NOTE:** While a 16-bit value is specified for this function, only the lower byte (8-bits) is used in all Floppy Disk and most Hard and RAM Disk drivers.

| Function 12 (xx24) | SETDMA Set DMA Address for Transfer |
|---:|:---|
| Enter: | BC = Buffer Starting Addr |
| Exit:  | None |
|        | DMA Address saved |
| Uses:  | No Registers |

This Function stores a specified address to be used as the Source/Destination for a future disk operation. The last value stored with this function will be the one used in Disk Reads and Writes. In banked systems, the Bank selected for the transfer may be altered by Function 28.

| Function 13 (xx27) | READ Disk Read |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0, Z if No Errors |
|        | A = Non-Zero if Errors, NZ |
| Uses:  | All Primary Registers |

This function reads a Logical 128-byte sector from the Disk, Track and Sector set by Functions 9-11 to the address set with Function 12. On return, Register A=0 if the operation was successful, Non-Zero if Errors occurred.

| Function 14 (xx2A) | WRITE Disk Write |
|---:|:---|
| Enter: | C = 1 for immediate write |
|        | C = 0 for buffered write |
| Exit:  | A = 0, Z if No Errors |
|        | A = Non-Zero if Errors, NZ |
| Uses:  | All Primary Registers |

This function writes a logical 128-byte sector to the Disk, Track and Sector set by Functions 9-11 from the address set with Function 12. If Register C=1, an immediate write and flush of the Bios buffer is performed. If C=0, the write may be delayed due to the deblocking.

| Function 15 (xx2D) | LISTST List Output Status |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0FFH, NZ if ready for Output Character |
|        | A = 0, Z if Printer Busy |
| Uses:  | AF |

This function returns a flag indicating whether or not the printer is ready to accept a character.  It uses the IOBYTE on Page 0 of the TPA Bank to determine which physical device to access.

| Function 16 (xx30) | SECTRN Perform Sector Translation |
|---:|:---|
| Enter: | BC = Logical Sector Number |
|        | DE = Addr of Translation Table |
| Exit:  | HL = Physical Sector Number |
| Uses:  | All Primary Registers |

This function translates the Logical Sector Number in register BC (Only C used at present) to a Physical Sector number using the Translation Table obtained from the DPH and addressed by DE.

-----

This ends the strict CP/M 2.2-compliant portion of the Bios Jump Table. The next series of entry Jumps roughly follows those used in CP/M 3, but with corrections to what we perceived to be deficiencies and inconsistencies in the calling parameters and structures.

-----

| Function 17 (xx33) | CONOST Console Output Status |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0FFH, NZ if Console ready for output char |
|        | A = 0, Z if Console Busy |
| Uses:  | AF |

This function returns a flag indicating whether or not the Console Device selected by the IOBYTE on Page 0 of the TPA Bank is ready to accept another output character.

| Function 18 (xx36) | AUXIST Auxiliary Input Status |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0FFH, NZ if Aux Input has character waiting |
|        | A = 0, Z if No char ready |
| Uses:  | AF |

This function returns a flag indicating whether or not the Auxiliary Input selected by the IOBYTE on Page 0 of the TPA Bank has a character waiting.

| Function 19 (xx39) | AUXOST Auxiliary Output Status |
|---:|:---|
| Enter: | None |
| Exit:  | A = 0FFH, NZ if Aux Output ready for output char |
|        | A = 0, Z if Aux Out Busy |
| Uses:  | AF |

This function return a flag indicating whether or not the Auxiliary Output selected by the IOBYTE on Page 0 of the TPA Bank is ready to accept another character for output.

| Function 20 (xx3C) | DEVTBL Return Pointer to Device Table |
|---:|:---|
| Enter: | None |
| Exit:  | HL = Address of Device Table |
| Uses:  | HL |

This function roughly corresponds to an analogous CP/M Plus function although precise bit definitions vary somewhat. The Character IO table consists of four devices; COM1, COM2, PIO, and NUL. Each has an input and output mask, data rate settings and protocol flags. Not all defined settings (e.g. ACK/NAK and XON/XOFF handshaking, etc) may be fully implemented in each version, but are available for later expansion and use.

| Function 21 (xx3F) | DEVINI Initialize Devices |
|---:|:---|
| Enter: | None |
| Exit:  | None |
|        | Initialization done |
| Uses:  | All Primary Registers |

This function initializes Character IO settings and other functions which may be varied by a Configuration Utility. It is an extended version of the corresponding CP/M Plus function. Its primary use is to restore IO configurations, system parameters such as clock rate, wait states, etc, after alteration by programs which directly access hardware such as many modem programs and the configuration utility, BPCNFG (see 6.2).

| Function 22 (xx42) | DRVTBL Return DPH Pointer |
|---:|:---|
| Enter: | None |
| Exit:  | HL = Address of start of Table of DPH Pointers |
| Uses:  | HL |

This function returns a Pointer to a table of 16-bit pointers to Disk Parameter Headers for Drives A-P. A Null (0000H) entry means that no drive is defined at that logical position.

| Function 23 (xx45) | reserved <Reserved for Multiple Sector IO> |
|---:|:---|
| Enter: | None |
| Exit:  | None |
| Uses:  | No Registers |

This function is reserved in the initial B/P Bios release and simply returns.

| Function 24 (xx48) | FLUSH Flush Deblocker |
|---:|:---|
| Enter: | None |
| Exit:  | None |
|        | Pending Disk Writes executed |
| Uses:  | All Primary Registers |

This function writes any pending Data to disk from deblocking buffers as mentioned in Function 14 above. This function should be called in critical areas where tasks are being swapped, or media is being exchanged when it is possible that the Operating System will not detect the change.

| Function 25 (xx4B) | MOVE Perform Possible Inter-Bank Move |
|---:|:---|
| Enter: | HL = Start Source Address |
|        | DE = Start Dest Address |
|        | BC = Number Bytes to Move |
| Exit:  | None |
|        | Data is moved |
| Uses:  | All Primary Registers |

This function moves the specified number of bytes between specified locations. For banked moves, the Source and Destination banks must have been previously specified with an XMOVE call (function 29). Note that the B/P implementation of this function reverses the use of the DE and HL register pairs from the CP/M 3 equivalent function.

| Function 26 (xx4E) | TIME Get/Set Date and Time |
|---:|:---|
| Enter: | DE = Start of 6-byte Buffer |
|        | C = 0 (to Get Date/Time) |
|        | C = 1 (to Set Date/Time) |
| Exit:  | A = 1 of Successful |
|        | A = 0 if Error or No Clock |
| Uses:  | All Primary Registers |

This function provides an interface to programs for a Real-Time Clock driver in the Bios. The function uses a 6-byte Date/Time string in ZSDOS format as opposed to Digital Research's format used in CP/M Plus for this function. Also, This function must conform to additional requirements of DateStamper(tm) in that on exit, register E must contain the entry contents of (DE+5) and HL must point to the entry (DE)+5. If the actual hardware implementing the clock supports 1/10 second increments, the current 1/10 second count may be returned in register D.

| Function 27 (xx51) | SELMEM Select Memory Bank |
|---:|:---|
| Enter: | A = Desired Memory Bank |
| Exit:  | None |
|        | Bank is in Context in range 0..7FFFH |
| Uses:  | AF |

This function selects the Memory Bank specified in the A register and make it active in the address range 0-7FFFH. Since character IO may be used when a bank other than the TPA (which contains the IOBYTE) is activated with this function, the B/P Bios automatically obtains the IOBYTE from the TPA bank to insure that Character IO occurs with the desired devices.

| Function 28 (xx54) | SETBNK Select Memory Bank for DMA |
|---:|:---|
| Enter: | A = Memory Bank for Disk DMA Transfers |
| Exit:  | None |
|        | Bank Number saved for later Disk IO |
| Uses:  | No Registers |

This function selects a memory Bank with which to perform Disk IO. Function 12 (Set DMA Transfer Address) operates in conjunction with this selection for subsequent Disk IO.

| Function 29 (xx57) | XMOVE Set Source and Dest Banks for Move |
|---:|:---|
| Enter: | B = Destination Bank Num |
|        | C = Source Bank Number |
| Exit:  | None |
|        | Bank Nums saved for MOVE operation |
| Uses:  | No Registers |

This function sets the Source and Destination Bank numbers for the next Move (Function 25). After a Move is performed, the Source and Destination Banks are automatically reset to TPA Bank values.

-----

This  marks the end of the CP/M Plus "Type" jumps and begins the unique  additions to the B/P Bios table to support Banking, Direct IO and interfacing.

----- 

| Function 30 (xx5A) | RETBIO Return BIOS Addresses |
|---:|:---|
| Enter: | None |
| Exit:  | A = Bios Version (Hex) |
|        | BC = Addr of Bios Base |
|        | DE = Addr of Bios Config |
|        | HL = Addr of Device Table |
| Uses:  | All Primary Registers |


This function returns various pointers to internal BIOS data areas and the Bios Version Number as indicated above. The Bios Version may be used to determine currency of the system software, and will be used by various support utilities to minimize the possibility of data corruption and/or as an indicator of supported features.

The Base Address of the Bios Jump Table returned in register BC is often used to insure that the proper indexing is achieved into the B/P data structures in the event that a Bios "shell" has been added such as when running NZCOM. While the Warm Boot jump at memory location 0000H normally points to the Bios Base+3, it is not always reliable, whereas this function will always return a true value with B/P Bios.

Registers DE and HL return pointers which are of value to programs which alter or configure various Bios parameters. The pointer to the configuration area of the Bios should be used in utilities as opposed to indexing from the start of the Bios Jump Table since additions to the Jump Table or insertion of other data will affect the Configuration Area starting address. The pointer in HL is available for use in systems which may contain more than four character IO devices. This pointer enables exchanges of devices to place desired devices in the first four positions of the table making them available for selection via the IOBYTE. After any alterations are made to the devices, a call to the Device Configuration Bios Function 21 should be made to activate the features.

| Function 33 (xx5D) | Floppy Disk and Hard Disk Subfunctions |
|---:|:---|
| _see below_ | |


| Function 32 (xx60) | STFARC Set Bank for Far Jump/Call |
|---:|:---|
| Enter: | A = Desired Bank Number |
| Exit:  | None |
| Uses:  | No Registers |

This Function sets the bank number for a later Function 33 Jump to a routine in an alternate Memory Bank.

| Function  (xx63) | FRJP Jump to (HL) in Alternate Bank |
|---:|:---|
| Enter: | HL = Address to execute in Bank set w/Fn 32 |
| Exit:  | <Unknown> |
|        | Called routine sets return status |
| Uses:  | All Primary Regs (assumed) |

This Function switches to the bank number previously specified with Function 32, then calls the routine addressed by HL. Upon completion, operation returns to the bank from which called, and the address on the top of the stack.

| Function 34 (xx66) | FRCLR Clear Stack Switcher |
|---:|:---|
| Enter: | HL = Addr to resume exec in entry bank |
| Exit:  | None |
|        | Execution resumes at addr in HL in entry bank |
| Uses:  | No Registers |

This Function is used for error exits from banked routines to return to the entry bank.

| Function 35 (xx69) | FRGETB Load  A,(HL) from Alternate Bank |
|---:|:---|
| Enter: | HL = Addr of desired byte |
|        | C = Desired Bank Number |
| Exit:  | A = Byte from C:HL |
| Uses:  | AF |

This Function gets a byte (8-bits) from the specified Bank and Address. The bank is temporarily switched in context for the access (if required), then restored to entry conditions. Interrupts are temporarily disabled during the brief access time.

| Function 36 (xx6C) | FRGETW Load  DE,(HL) from Alternate Bank |
|---:|:---|
| Enter: | HL = Addr of desired word |
|        | C = Desired Bank Number |
| Exit:  | DE = Word from C:HL |
| Uses:  | AF, DE |

This Function gets a Word (16-bits) from the specified Bank and Address. The bank is temporarily switched in context for the access (if required), then restored to entry conditions. Interrupts are temporarily disabled during the brief access time.

| Function 37 (xx6F) | FRPUTB Load  (HL),A to Alternate Bank |
|---:|:---|
| Enter: | HL = Addr of Dest Byte |
|        | C = Desired Bank Number |
|        | A = Byte to save at C:HL |
| Exit:  | None |
|        | Byte stored at C:HL |
| Uses:  | AF |

This Function saves a Byte (8-bits) to the specified Address and Bank. The bank is temporarily switched in context for the access (if required), then restored to entry conditions. Interrupts are temporarily disabled during the brief access time.

| Function 38 (xx72) | FRPUTW Load (HL),DE to Alternate Bank |
|---:|:---|
| Enter: | DE = Word to store at C:HL |
|        | HL = Addr of Dest Byte |
|        | C = Desired Bank Number |
| Exit:  | None |
|        | Word stored at C:HL |
| Uses:  | AF |

This Function saves a Word (16-bits) to the specified Address and Bank. The bank is temporarily switched in context for the access (if required), then restored to entry conditions. Interrupts are temporarily disabled during the brief access time.

| Function 39 (xx75) | RETMEM Return Current Bank in Context |
|---:|:---|
| Enter: | None |
| Exit:  | A = Bank currently active in Addr 0..7FFFH |
| Uses:  | AF |

This Function returns the Memory Bank currently in Context in the address range of 0..7FFFH. It may be used in the "where am I" role in application programs to track memory accesses.


-----

### Function 31 - FLOPPY DISK SUBFUNCTIONS

Function 31 permits low-level access to Floppy and Hard Disks (via SCSI interface) by specifying a Driver Number and desired Function. While some hardware types do not support all of the parameters specified, particularly for Floppy Drives, this architecture supports all types, although specific systems may ignore certain functions. In this manner, for example, a single Format program supports NEC765, SMC9266, WD1770/1772/179x and other controller types with widely differing interfaces. Floppy Disk functions are accessed by entering a 1 value into Register B (Floppy Driver Number) and the desired function number in Register C, then jumping to or calling BIOS Entry jump number 31.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 0 |
|---:|:---|
|        | **Set Floppy Read/Write Mode** |
| Enter: | A = 0 for Double Density, |
|        | FF for Single Density |
|        | B = 1 (Floppy Driver) |
|        | C = 0 (Subfunction #) |
| Exit:  | None |
| Uses:  | AF |

This routine establishes the Density mode of operation of the Floppy Disk Controller for Read and Write accesses. It assumes that SubFunctions 1 (Set Size and Motor) and 3 (Set Sector) have been called first.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 1 |
|---:|:---|
|        | **Set Floppy Disk & Motor Parms** |
| Enter: | A = 0 for 300 rpm (normal), |
|        | FF for 360 rpm (8"/HD) |
|        | D = FF for Motor Control, |
|        | 0 if Motor always on |
|        | B = 1 (Floppy Driver) |
|        | C = 1 (Subfunction #) |
| Exit:  | None |
| Uses:  | AF |

This routine establishes some of the physical parameters for a Floppy Drive. The normal 5.25" and 3.5" disk drives holding 400 or 800 kb or less rotate at 300 rpm. Many of the newer drives can increase this speed to 360 rpm which is the rate used on older 8" floppy drives. This is the speed used on the "High Density" 1.2 MB (IBM formatted) 5.25" drives. The A register is used to indicate the fastest speed capable on the specified drive. Register D is used to indicate whether the Motor is always On, or will start and stop periodically. This is normally used by the Bios to delay for a period before writing if the motor is stopped to allow the diskette to come up to speed thereby minimizing chances of data corruption. Register E is used to indicate the physical media size as; 0=Hard Disk, 001B=8" Drive, 010B=5.25" Drive, and 011B=3.5". Nothing is returned from this command.

While all of these functions may not be supported on any specific computer type, the interface from using programs should always pass the necessary parameters for compatibility.

**NOTE:** This routine assumes that SubFunction 2 (Set Head and Drive) has been called first. Call this routine before calling Function 0 (Set Mode).


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 2 |
|---:|:---|
|        | **Set Head and Drive** |
| Enter: | A = Drive # (Bits 0,1), |
|        | Head # (Bit 2) |
|        | B = 1 (Floppy Driver) |
|        | C = 2 (Subfunction #) |
| Exit:  | None |
| Uses:  | AF |

This routine is entered with register A containing the Floppy unit number coded in bits 0 and 1 (Unit 0 = 00, 1 = 01 .. 3 = 11), and the Head in Bit 2 (0 = Head 0, 1 = Head 1). Nothing is returned from this function. Call this Subfunction before most of the others to minimize problems in Floppy accesses.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 3 |
|---:|:---|
|        | **Set Floppy Disk Mode** |
| Enter: | A = Physical Sector Number |
|        | D = Physical Sector Size |
|        | E = Last Sctr # on Side |
|        | B = 1 (Floppy Driver) |
|        | C = 3 (Subfunction #) |
| Exit:  | None |
| Uses:  | AF |

This routine establishes information needed to properly access a specified sector unambiguously with a number of different controller types. On entry, Register A contains the desired physical sector number desired, D contains the sector size where 0 = 128 byte sectors, 1 = 256 .. 3 = 1024 byte sectors, and E contains the last sector number on a side. Normally register E is unused in Western Digital controllers, but is needed with 765 and 9266 units. Nothing is returned from this subfunction.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 4 |
|---:|:---|
|        | **Specify Drive Times** |
| Enter: | A = Step Rate in milliSec |
|        | D = Head Unload Time in mS |
|        | E = Head Load Time in mS |
|        | B = 1 (Floppy Driver) |
|        | C = 4 (Subfunction #) |
| Exit:  | None |
| Uses:  | AF |

This subfunction set various timing values used for the physical drive selected. On entry, the A register contains the drive step rate in milliseconds. Within the Bios, this rate is rounded up to the nearest controller rate if the specified rate is not an even match. Register D should contain the desired Head Unload time in milliseconds, and E to the desired Head Load time in mS.

NOTE: With Western Digital type controllers, only the Step Rate is universally variable. In these systems, rates signaled by the Bios settings are rounded up to the closest fixed step rate such as the 2, 3, 5, or 6 milliSecond rates in the WD1772 or 6, 10, 20, or 30 milliSecond rates used in the older WD1770 and WD1795. Nothing is returned from this function.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 5 |
|---:|:---|
|        | **Home Disk Drive Heads** |
| Enter: | B = 1 (Floppy Driver) |
|        | C = 5 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | A <> 0, NZ if Errors |
| Uses:  | AF |
| **NOTE:** | Subfcns 1, 2, & 4 Needed |

This subfunction moves the head(s) on the selected drive to track 0 (home). Only success/failure is indicated by the value in the A register. No other registers may be altered by this function (especially BC).

**NOTE:** This function requires that Subfunctions 1 (Set Disk and Motor Parameters), 2 (Set Head and Drive) and 4 (Specify Drive Times) be called first in order to establish the physical characteristics of the Drive.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 6 |
|---:|:---|
|        | **Seek Track** |
| Enter: | A = Desired Track Number |
|        | D = 0FFH to Verify, |
|        | 0 for No Verification |
|        | E = 0 for No Double-Step |
|        | <>0 for Double-Step |
|        | B = 1 (Floppy Driver) |
|        | C = 6 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | <> 0, NZ if Error |
| Uses:  | AF |
| **NOTE:** | Subfcns 2, 3 & 4 Needed |

This subfunction moves the head(s) for the selected drive to a specified track on the media. If the Double-Step flag (Register E) is set to a Non-Zero value, then the controller will issue two step pulses for every track increment or decrement which is required. After the Seek, a Read ID function will be performed to verify that the desired track was found if the Verification Flag (Register D) is set to a Non-Zero Number, preferably 0FFH. Only the AF registers may be altered by this function.

**NOTE:** This function requires that Subfunctions 2 (Set Head and Drive), 3 (Set Floppy Disk Mode) and 4 (Specify Drive Times) be called first in order to establish the physical characteristics of the Drive.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 7 |
|---:|:---|
|        | **Read Floppy Disk Sector** |
| Enter: | HL = Dest Buffer Address |
|        | B = 1 (Floppy Driver) |
|        | C = 7 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | <> 0, NZ if Error |
| Uses:  | AF, HL |
| **NOTE:** | Subfcns 0, 1, 2, 4 & 6 Needed |

This subfunction Reads a physical sector of data from the selected drive and places it in the buffer at the specified address. It is important that an appropriately sized buffer is provided for this task. The Value in the A register will indicate the success or failure of the function as indicated in the above chart. Only the AF and HL registers may be altered by this function.

**NOTE:** This function requires that Subfunctions 0 (Set Read/Write Mode), 1 (Set Disk & Motor Parms), 2 (Set Head & Drive), 4 (Specify Drive Times) and 6 (Seek Track) be called first in order to establish the physical and logical characteristics of the data transfer.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 8 |
|---:|:---|
|        | **Write Floppy Disk Sector** |
| Enter: | HL = Source Buffer Address |
|        | B = 1 (Floppy Driver) |
|        | C = 8 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | A <> 0, NZ if Error |
| Uses:  | AF, HL |
| **NOTE:** | Subfcns 0, 1, 2, 4 & 6 Needed |

This subfunction writes data from the buffer beginning at the specified address to the track, sector and head selected by other subfunctions. The value in the A register along with the setting of the Zero Flag will indicate whether the operation succeeded or not. Only the AF and HL registers may be altered by this function.

**NOTE:** This function requires that Subfunctions 0 (Set Read/Write Mode), 1 (Set Disk & Motor Parms), 2 (Set Head & Drive), 4 (Specify Drive Times) and 6 (Seek Track) be called first in order to establish the physical and logical characteristics of the data transfer.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 9 |
|---:|:---|
|        | **Read Disk Sector ID** |
| Enter: | B = 1 (Floppy Driver) |
|        | C = 9 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | A <> 0, NZ if Error |
| Uses:  | AF |
| **NOTE:** | Subfcns 0 & 2 Needed |

This Subfunction reads the first correct ID information encountered on a track. There are no entry parameters for this function other than the Driver and Subfunction number. A flag is returned indicating whether or not errors occurred. An error indicates that no recognizable Sector ID could be read on the disk. In most cases, this is due to an incorrect Density setting in the Bios.

**NOTE:** This function requires that Subfunctions 2 (Set Head & Drive) and 3 (Set Floppy Disk Mode) are called first in order to establish the physical characteristics of the disk.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 10 |
|---:|:---|
|        | **Return Floppy Drive Status** |
| Enter: | B = 1 (Floppy Driver) |
|        | C = 10 (Subfunction #) |
| Exit:  | A = Status Byte of last Opn |
|        | BC = FDC Controller Type |
|        | HL = Address of Status Byte |
| Uses:  | AF, BC, HL |
| **NOTE:** | Subfcn 2 Needed |

This function returns the status of the currently-selected drive. There are no entry parameters for this function other than the Floppy Driver and Function number. On exit, the raw unmasked status byte of the drive, or the last operation depending on the controller type, is returned along with a binary number representing the FDC controller type (e.g. 765, 9266, 1772, etc).

**NOTE:** This routine assumes that Subfunction 2 (Set Head & Drive) has been called before this routine to select the Physical Parameters.


| Function 31 (xx5D) | DIRDIO Floppy SubFunction 11 |
|---:|:---|
|        | **Format Floppy Disk Track** |
| Enter: | HL = Pointer to Data Block |
|        | D = # of Sectors/Track |
|        | E = # of Bytes in Gap 3 |
|        | B = 1 (Floppy Driver) |
|        | C = 11 (Subfunction #) |
| Exit:  | A = 0, Zero Set (Z) if Ok |
|        | A <> 0, NZ if Error |
| Uses:  | AF, BC, DE, HL |
| **NOTE:** | Use Subfcn 10 for Cont Type |

This Sub function formats a complete track on one side of a Floppy Disk. It assumes that the Mode, Head/Drive, Track, and Sector have already been set. On entry, HL points to data required by the controller to format a track. This varies between controllers, so RETDST should be called to determine controller type before setting up data structures. On entry, D must also contain the number of Sectors per Track, and E must contain the number of bytes to use for Gap 3 in the floppy format. On exit, A=0 and the Zero flag is Set (Z) if the operation was satisfactorily completed, A <> 0 and the Zero flag cleared (NZ) if errors occurred. This routine may alter all primary registers (AF, BC, DE, HL).

**NOTE:** This routine assumes that Subfunction 10 (Return Floppy Drive Status) has been called first to determine the Controller type and insert the correct information in the Format Data Block.

-----

### Function 31 - HARD DISK SUBFUNCTIONS

These functions are available to directly access Hard Drives connected by a SCSI type interface. They are accessed by loading the desired function number in the C register, loading a 2 (SCSI driver) into the B register and calling or jumping to Jump number 31 in the Bios entry jump table. Since this interface is not as standardized as Floppy functions in order to handle SASI as well as SCSI devices, the interface has only basic functions with the precise operations specified by the User in the Command Descriptor Block passed with Function 2. While this places a greater burden on User programs, it allows more flexibility to take advantage of changing features in the newer SCSI drives.


| Function 31 (xx5D) | DIRDIO Hard Disk SubFunction 0 |
|---:|:---|
|        | **Set Hard Disk Addresses** |
| Enter: | DE = Address of Data Area |
|        | B = 2 (Hard Disk Driver) |
|        | C = 0 (Subfunction #) |
| Exit:  | A = # Bytes in Comnd Block |
| Uses:  | AF |

This Subfunction sets the User Data Area Address for Direct SCSI IO, and returns the number of bytes available in the SCSI Command Descriptor Block. The Data Area must be AT LEAST 512 bytes long and is used to store data to be written, and to receive data read from the selected drive. This Data Area size is mandatory since 512 bytes are always returned from a direct access in order to handle the wide variety of controller types recognized in the B/P Bios drivers. The number of bytes available in the Command Descriptor Block within the physical driver is usually 10 in order to handle the extended SCSI commands, but may be scaled back to 6 in limited applications.


| Function 31 (xx5D) | DIRDIO Hard Disk SubFunction 1 |
|---:|:---|
|        | **Set Physical & Logical Drive** |
| Enter: | A = Device Byte (5.2.1) |
|        | B = 2 (Hard Disk Driver) |
|        | C = 1 (Subfunction #) |
| Exit:  | A = Physical Device Bit |
| Uses:  | AF |

This Subfunction sets the Physical Device bit in the Bios for SCSI accesses and the Logical Unit Number in the SCSI Command Block (Byte 1, bits 7-5). The format of the Device Byte provided to this routine is defined in the Configuration Data, Section 5.2.1, CONFIG+61, and is available from the Extended Disk Parameter Header at DPH-1. On exiting this routine, a byte is returned with a "One" bit in the proper position (Bit 7 = Device 7...Bit 0 = Device 0) to select the desired unit via a SCSI command.


| Function 31 (xx5D) | DIRDIO Hard Disk SubFunction 2 |
|---:|:---|
|        | **Direct SCSI Driver** |
| Enter: | DE = Ptr to Comnd Desc Blk |
|        | A = 0 if No Write Data |
|        | A = FF if Data to Write |
|        | B = 2 (Hard Disk Driver) |
|        | C = 2 (Subfunction #) |
| Exit:  | A = Bit1 Status, Flags Set |
|        | H= Message Byte Value |
|        | L = Status Byte Value |
| Uses:  | AF, BC, DE, HL |
| **NOTE:** | Subfcns 0 & 1 Needed |

This Subfunction performs the actions required by the command in the specified Command Descriptor Block. The flag provided in Register A signifies whether or not user data is to be written by this command. If set to a Non-Zero value, Data from the area specified with Function 0 will be positioned for SCSI Write operations. At the end of the routine, 512 bytes are always transferred from the Bios IO Buffer to the Users Space set by Subfunction 0. This may be inefficient, but was the only way we could accommodate the wide variety of different SASI/SCSI controllers within reasonable code constraints. The status returned at completion of this function is the Status byte masked with the Check Bit, Bit 1. The full Status Byte and Message Byte from SCSI operations are also provided for more definition of any errors.

**NOTE:** This routine assumes that the Command Descriptor Block has been properly configured for the type of Hard Disk Controller set in B/P Bios, and that the selected disk is properly described (if necessary) in the Bios Unit definitions. Errors in phasing result in program exit and Warm Boot. It assumes the user has called Functions 0 (Set Hard Disk Addresses) and 1 (Set Physical & Logical Drives) before using this Subfunction.

----

## 5.2 Bios Data Structures

### 5.2.1  Configuration Area

Much of the ability to tailor B/P Bioses to your specific operating needs is due to the standardized location of many discrete elements of data, and a facility to easily locate and change them, regardless of the particular hardware platform in operation. Bios Function 30, Return Bios Addresses, reports the base address of the Configuration Area in the DE register pair. In this section, we will review each of the specified elements, their functions, and which parts of the data must be rigidly controlled to insure that the supplied utilities continue to function, as well as guarantee the portability of other programs.


| Offset (hex) | (dec) | Description | Data type |
| :---: |  :---: | :--- | :--- |
|  -0x06 / 0xFA | -6  | Bios ID | String, 6 bytes |
|  +0x00 | +0  | IOBYTE | Byte |
|  +0x02 | +2  | Bios Option Flags | Byte |
|  +0x03 | +3  | User Bank | Byte |
|  +0x04 | +4  | TPA Bank | Byte |
|  +0x05 | +5  | SYStem Bank | Byte |
|  +0x06 | +6  | RAM Drive Bank | Byte |
|  +0x07 | +7  | Maximum Bank Number | Byte |
|  +0x08 | +8  | Common Page Base | Byte |
|  +0x09 | +9  | DPB Size | Byte |
|  +0x0A | +10 | Number of DPBs in Common RAM | Byte |
|  +0x0B | +11 | Number of DPBs in System Bank | Byte |
|  +0x0C | +12 | Pointer to first Common DPB | Word |
|  +0x0E | +14 | Pointer to first Banked DPB | Word |
|  +0x10 | +16 | Initial Startup Command | String, 10 bytes |
|  +0x1A | +26 | Pointer to Environment Descriptor | Word |
|  +0x1C | +28 | Banked User Flag/Bank Number | Byte |
|  +0x1D | +29 | Pointer to Start of Banked User Area | Word |
|  +0x1F | +31 | CPU Clock Rate in Megahertz | Byte |
|  +0x20 | +32 | Additional Wait State Requirements | Byte |
|  +0x21 | +33 | Timer Reload Value | Word |
|  +0x23 | +35 | Floppy Disk Physical Parameters | Table |
|  +0x37 | +55 | Motor On Time in 1/10th Seconds | Byte |
|  +0x38 | +56 | Motor Spinup Time in 1/10th Seconds | Byte |
|  +0x39 | +57 | Maximum Number of Retries | Byte |
|  +0x3A | +58 | Pointer to Interrupt Vector Table | Word |
|  +0x3C | +60 | SCSI Controller Type | Byte |
|  +0x3D | +61 | Hard Drive Physical Parameters | Table |
|  +0x58 | +88 | (Reserved Bytes) | 5 Bytes |
|  +0x5D | +93 | Character Device Definitions | Table |


`CONFIG-6` Bios ID (Character String, 6 bytes)

This character string **MUST** begin with the three characters "B/P" in Uppercase Ascii, followed by three Version-specific identifying characters. As of March 1997, the following identifiers have been assigned to systems:

| ID    | Computer system |
| :---: | :--- |
| `"B/P-YS"` | YASBEC |
| `"B/P-AM"` | Ampro Little Board 100 |
| `"B/P-18"` | MicroMint SB-180 |
| `"B/P-CT"` | Compu/Time S100 Board Set |
| `"B/P-TT"` | Teletek |
| `"B/P-XL"` | Intelligent Computer Designs XL-M180 |
| `"B/P-DX"` | D-X Designs Pty Ltd P-112 |


`CONFIG+0` IOBYTE (Byte)

This byte contains the initial definition of the byte placed at offset 3 on the Base Page (0003H) during a Cold Boot and determines which of the four defined character IO devices will be used as the Console, Auxiliary and Printer devices. The default setting may be altered by BPCNFG to reflect changed device configurations, or by reassembly of the Bios. The bit definitions in this byte are:

```generic
Bit 7 6 5 4 3 2 1 0
    | | | | | | \------ Console Device
    | | | | \---------- Auxiliary Input Device
    | | \-------------- Auxiliary Output Device
    \------------------ Printer Device
```

`CONFIG+2` Bios Option Flags (Byte)

This byte consists of individually mapped bits which display which options are active in the assembled Bios. The bits listed as <reserved> should not be defined without prior coordination with the system developers to preclude conflicts with planned enhancements. The byte is currently defined as:

```generic
Bit 7 6 5 4 3 2 1 0
    | | | | | | | \---- 0 = Unbanked Bios    1 = Banked Bios
    | | | | | | \------ 0 = Bank in RAM      1 = Bank in ROM
    | | | | | \-------- 0 = DPBs Fixed       1 = DPBs Assignable
    | | | | \---------- 0 = ALV/CSV in TPA   1 = ALV/CSV in Bank (ZSDOS2)
    | \----------------  <reserved>
    \------------------ 0 = Not Locked       1 = Locked, Can't Reload
```

The next five bytes define the memory map of a banked system in 32k slices. For a complete description of Bank allocations, please refer to Section 4. In non-banked systems, all except the RAM Drive Bank should all be set to 0. If no memory is available for re-assignment as a RAM drive, this byte as well should be set to 0.

`CONFIG+3` User Bank (Byte)

This Byte reflects the Bank number reserved for User Applications.

`CONFIG+4` TPA Bank (Byte)

This Byte reflects the Bank number reserved for the Transient Program Area in the address range of 0..7FFFH. The next sequential bank number is normally the Common Bank which always remains in Context in the addressing range of 8000..FFFFH and contains the Operating System, Bios and Z-System tables.

`CONFIG+5` SYStem Bank (Byte)

This byte reflects the Bank number containing any executable code and data specified for the System Bank.

`CONFIG+6` RAM Drive Bank (Byte)

This byte reflects the starting Bank number available for use as a RAM Drive. It is assumed that all RAM from this Bank through the Maximum Bank Number is contiguous and available as a RAM Drive.

`CONFIG+7` Maximum Bank Number (Byte)

This byte reflects the number of the last available bank of RAM in the system. In many systems, it may be set to different numbers depending on the number of RAM chips installed in the system.

`CONFIG+8` Common Page Base (Byte)

This byte reflects the Base Page of the Common area in systems which do not fully comply with the 32k Memory Banking architecture of B/P Bios, but can be made somewhat compliant. This Byte must be AT LEAST 80H, but may be higher if needed.

`CONFIG+9` DPB Size (Byte)

This byte contains the length of Disk Parameter Block allocations within the Bios. Since more information is needed than the 15 bytes defined by Digital Research in CP/M 2.2, an extended format is used. All re-assignments of Disk Parameter data should use this byte to determine the size of records.

`CONFIG+10` Number of DPBs in Common RAM (Byte)
`CONFIG+11` Number of DPBs in System Bank (Byte)

These two bytes indicate the complete complement of Floppy Disk formats available within the Bios. In most cases, one of these two bytes will reflect a zero value with all Disk Parameter Blocks resident either in the Common area or in the System Bank. The provisions are available, however with these two bytes to split the definitions for custom versions without voiding the support tools provided.

`CONFIG+12` Pointer to first Common DPB (Word)
`CONFIG+14` Pointer to first Banked DPB (Word)

These two words point to the first DPB in a sequential list within the respective memory banks for Disk Parameter Blocks defined in the preceding bytes. In most cases one of these two words will be a Null pointer (0000H) corresponding to no data as described in the count bytes above.

`CONFIG+16` Initial Startup Command (String, 10 Bytes)

This string contains the first command which will be initiated on a Cold Boot. It is loaded into the Multiple Command Buffer defined in the Environment Descriptor (See 5.2.4) and calls a file of the specified name with a type of "COM". The string may have up to eight characters and must be Null-terminated (end with a Binary 0). The string is defined as:

|  | Initial Startup Command String |
| :---: | :--- |
| Byte | Number of Characters (0..8) |
| String | 8 bytes for Ascii characters (usually Uppercase) |
| Byte | Terminating Null (binary 0) |

`CONFIG+26` Pointer to Environment Descriptor (Word)

This Word points to the first byte of an extended Z34 Environment which **MUST** begin on a Page boundary (xx00H). See Section 5.3.1 for a complete description of the Environment Descriptor and B/P Bios unique features.

`CONFIG+28` Banked User Flag/Bank Number (Byte)

This Byte may be used as a flag to indicate whether or not a User Bank is defined. Bank 0 cannot be used as a User bank by decree of the system authors. Therefore, if this byte contains a binary 0, no User Bank is available.

`CONFIG+29` Pointer to Start of Banked User Area (Word)

This word contains the address of the first available byte in the Banked User Area, if one exists. Routines loaded into the User Bank should contain a standard RSX header structure to link sequential programs and provide a primitive memory management function.

`CONFIG+31` CPU Clock Rate in Megahertz (Byte)

This byte must contain the processor speed rounded to the nearest Megahertz. It may be used by software timing loops in application and utility programs to adapt to the clock speed of the host computer and provide an approximate time. This byte is reflected in the Environment Descriptor (see 5.2.4) as well for programs which are Z-System "aware".

`CONFIG+32` Additional Wait State Requirements (Byte, nybble-mapped)

This byte is "nybble-mapped" to reflect the number of wait states needed for memory and IO accesses when these functions can be set via software. In the Z80/Z180, IO port accesses have one wait state inserted within the processor. This byte does not account for this fact, and reflects wait states **IN ADDITION TO** any which are built into the hardware. For older processors such as the Z80, these bytes normally have no effect since additional wait states must be added with hardware.

`CONFIG+33` Timer Reload Value (Word)

In many systems, Interrupts or Timer values are set by software-configurable countdown timers. the 16-bit value at this location is reserved for setting the timer value and may be "fine tuned" to allow the system to maintain correct time in the presence of clock frequencies which may deviate from precise frequencies needed for accurate clocks.

`CONFIG+35` Floppy Disk Physical Parameters (Table)

This table consists of four 5-byte entries which contain information on up to four physical drives. Each entry is defined as:

| Byte | Description |
| :---: | :--- |
| 0 | Provides base for XDPH byte, _see bit mapping below_ |
| 1 | Step Rate in milliseconds |
| 2 | Head Load Time in milliseconds |
| 3 | Head Unload Time in milliseconds |
| 4 | Number of Tracks (Cylinders) on drive |

```generic
XDPH Base
Bit 7 6 5 4 3 2 1 0
    | | | | | \-------- Disk Size 000=Fixed Disk, 001=8", 010=5.25", 011=3.5"
    | | | | \---------- 0 = Single-Sided,      1 = Double-Sided
    | | | \------------  <reserved>
    | | \-------------- 0 = Motor Always On    1 = Motor Control Needed
    | \---------------- 0 = 300 RPM Max Speed  1 = 360 RPM (8" & HD)
    \------------------  <reserved>
```
Those bits in Byte 0 which are listed as unused must be set to 0 since this byte provides the initial value stored in the XDPH when assignable drives are used. For controllers which do not need the available information (e.g. Western Digital controllers do not need Byte 3), these values may be set to any arbitrary value, but **MUST** remain present in the structure to prevent changing subsequent addresses.

`CONFIG+55` Motor On Time in 1/10th Seconds (Byte)

This time may be used in some types of Floppy Disk controllers to keep the drive motors spinning for a specified time after the last access to avoid delays in bringing the spindle up to speed. Some controllers, notably the Western Digital 17xx and 19xx series to not support this feature. In this case, the byte may be set to any arbitrary value, but **MUST** remain present.

`CONFIG+56` Motor Spinup Time in 1/10th Seconds (Byte)

This time is the delay which will be imposed by the Bios before attempting to access a Floppy Disk drive when it senses that the motor is in a stopped condition. Providing such a delay will minimize the probability of data corruption by writing to disk which is rotating at the incorrect speed.

`CONFIG+57` Maximum Number of Retries (Byte)

This byte specifies the number of attempts which will be made on a Floppy Disk access before returning an error code. In some cases, such as diagnostic programs, it may be desirable to set this value to 1 to identify soft errors, or ones which fail on the first attempt, but succeed on a subsequent try. We recommend a value of 3 or 4 based on our experience. Larger values may result in inordinately long delays when errors are detected.

`CONFIG+58` Pointer to Interrupt Vector Table (Word)

This Word contains the address of the base of an Interrupt Vector Table which, when used, contains pointers to service routines. The precise definition of the table is not standardized and may vary considerably between systems. This pointer serves only to provide an easy and standardized method of locating the table for re-definition of services or system features.

`CONFIG+60` SCSI Controller Type (Byte)

To accommodate the widest variety of different controllers including the older SASI models, this byte is defined as containing a byte code to the specific model being used. In most cases, this byte has little if any effect within the Bios, but may have significant effects on Hard Disk Diagnostic programs, or User-developed utilities. Any additions to this table should be coordinated with the authors to insure that the standard support utilities continue to function. Current definitions are:

| ID | Controller type |
| :---: | :--- |
| 0 | Owl |
| 1 | Adaptec ACB-4000A |
| 2 | Xebec 1410A/Shugart 1610-3 (SASI) |
| 3 | Seagate SCSI |
| 4 | Shugart 1610-4 (Minimal SCSI subset) |
| 5 | Conner SCSI |
| 6 | Quantum SCSI |
| 7 | Maxtor SCSI |
| 8 | Syquest SCSI |
| 9 | GIDE (IDE/ATA) |

`CONFIG+61` Hard Drive Physical Parameters (Table)

This table consists of three 9-byte entries defining up to three physical Hard Drives. While the SCSI definition allows for more units, three was considered adequate for most systems. If additional drives are needed, please contact the authors for methods of including them without invalidating any of the standard utilities or interfaces. Each of the three entries is defined as:

| Entry | Description |
| :--- | :--- |
| Byte | Physical and Logical Address, _see bit mapping below_ |
| Word | Number of Physical Cylinders on Drive |
| Byte | Number of Usable Physical Heads on Drive |
| Word | Cylinder Number to begin Reduced Write Current |
| Word | Cylinder Number to begin Write Precompensation |
| Byte | Step Rate. This byte may either be an absolute rate in mS or a code based on controller-specific definitions |

```generic
Physical and Logical Address
 Bit 7 6 5 4 3 2 1 0
     | | | | | \-------- Physical Device (000-110B, 111B reserved for Host)
     | | | | \----------  <reserved>
     | | | \------------ 0 = Drive NOT Present, 1 = Drive Present
     \------------------  Logical Unit Number (000-111B) for controllers
```

For many of the newer controllers, the last three items may not have any meaning in which case they can be set to any arbitrary value. Also in newer drives, the physical characteristics such as the number of cylinders and heads may be hidden within the drive electronics with re-mapped values provided to the controller via various SCSI commands. As with the last three entries, in this case, they may be set to any arbitrary value.

`CONFIG+88` Reserved (5 Bytes)

Five Bytes are reserved for future expansion.

`CONFIG+93` Character Device Definitions (Table)

This table consists of four or more 16-byte (8-byte in B/P versions prior to 1.1) entries and must be terminated by a Null (binary Zero) byte. Each entry defines the name and characteristics of a character device in the system. The first four of these are directly available for selection by the IOBYTE as the Console, Auxiliary IO and Printer. Other entries may be defined and exchanged with the first four to make them accessible to the system. The entries are defined as:

| Entry | Description |
| :---: | :--- |
| String | Four Ascii character Name as: COM1, PIO1, NULL, etc. |
| Byte | Data Rate capabilities, _see bit mapping below_ |
| Byte | Configuration Byte, _see bit mapping below_ |
| Byte | Input Data Mask |
|  | Bit-mapped byte used to logically AND with bytes read from Device Input |
| Byte | Output Data Mask |
|  | Bit-mapped byte used to logically AND with bytes before being output to device |
| Word | Pointer to Character Output routine |
| Word | Pointer to Output Status routine |
| Word | Pointer to Character Input routine |
| Word | Pointer to Input Status routine |

**NOTE:** The last four pointers are not at these locations in B/P Bios versions prior to 1.1, but were accessed by a pointer returned by Bios Function 30.

```generic
Data Rate capabilities
Bit 7 6 5 4 3 2 1 0
    | | | | \---------- Current Data Rate Setting
    \------------------ Maximum Rate Available (Bits-per-Second) as:
      0000 = None    0001 = 134.5   0010 = 50       0011 = 75
      0100 = 150     0101 = 300     0110 = 600      0111 = 1200
      1000 = 2400    1001 = 4800    1010 = 9600     1011 = 19200
      1100 = 38400   1101 = 76800   1110 = 115200   1111 = Fixed
```

```generic
Configuration Byte
Bit 7 6 5 4 3 2 1 0
    | | | | | | | \---- 0 = 2 Stop Bits,       1 = 1 Stop Bit
    | | | | | | \------ 0 = No Parity,         1 = Parity Enabled
    | | | | | \-------- 0 = Odd Parity,        1 = Even Parity
    | | | | \---------- 0 = 8-bit Data,        1 = 7-bit Data
    | | | \------------ 0 = No XON/XOFF,       1 = XON/XOFF Control Enabled
    | | \-------------- 0 = No CTS/RTS,        1 = CTS/RTS Control Enabled
    | \---------------- 0 = Device NOT Input,  1 = Device can be read
    \------------------ 0 = Device NOT Output, 1 = Can Write Device
```


### 5.2.2  Disk Parameter Header

The Disk Parameter Header (DPH) is a logical data structure required for each disk drive in a CP/M compatible Disk Operating System. It consists of a series of eight pointers which contain addresses of other items needed by the DOS as well as some scratchpad space. The Address of the DPH associated with a given drive is returned by the Bios after a successful selection with Bios Function 9. If Errors occur during selection, or the drive does not exist, a Null Pointer (0000H) is returned.

For B/P Bios, it was necessary to add an additional four bytes to each DPH which contain additional information on physical and logical parameters as well as flag information. These additional bytes are referred to as the Extended DPH, or XDPH. While similar in concept to the extension added to CP/M 3, the implementation is different. The XDPH prepends the DPH and may be accessed by decrementing the returned address. As a convention, DPHs in B/P Bios source code have reserved certain label sequences for specific types of units with DPH00-DPH49 used for Floppy Drives, DPH50-DPH89 for Hard Drive Partitions and DPH90-DPH99 for RAM Drives.

An entire DPH/XDPH block is required for each logical drive in a B/P Bios system. While some pointers, such as the pointer to the Directory Buffer, may be common across a number of drives, for most systems, the other items will point to unique areas.


| Offset (hex) | (dec) | Description | Data type |
| :---: | :---: | :--- | :--- |
|  -0x04 / 0xFC| -4  | Format Lock Flag | Byte |
|  -0x03 / 0xFD | -3  | Disk Drive Type | Byte |
|  -0x02 / 0xFE | -2  | Driver ID Number | Byte |
|  -0x01 / 0xFF | -1  | Physical Drive/Unit Number | Byte |
|  +0x00 | +0  | Skew Table Pointer | Word |
|  +0x02 | +2  | Dos Scratch Area | 3 Words |
|  +0x08 | +8  | Directory Buffer Pointer | Word |
|  +0x0A | +10 | DPB Pointer | Word |
|  +0x0C | +12 | Disk Checksum Buffer | Word |
|  +0x0E | +14 | Allocation Vector (ALV) Buffer | Word |


The DPH/XDPH elements as indexed from the DPH addresses accessible to application programs are:

`DPH-4` Format Lock Flag (Byte)

A Zero value indicates that the format of the disk is not fixed, but may be changed. If the Bios was assembled with the Auto-select option, the Bios will scan a number of different formats in order to identify the disk. If a 0FFH value is placed in this byte, it indicates that the format is fixed and cannot be changed. This is normally the case for RAM and Hard disk drives, as well as for alien floppy formats which have been selected in the emulation mode. If the Auto-select option was not chosen during assembly of the Bios, all Floppy Disk drives will also have a 0FFH byte in this position showing that the formats cannot be changed.


`DPH-3` Disk Drive Type (Byte)

This byte is bit mapped and contains flags indicating many parameters of the drive. For Floppy Drives, this byte contains a copy of the first byte in the Physical Drive Table (See 5.2.1, CONFIG+35) with the two reserved bytes set during the drive selection process. The byte is then defined as:

```generic
Bit 7 6 5 4 3 2 1 0
    | | | | | \-------- Disk Size  000=Fixed Disk, 001=8", 010=5.25", 011=3.5"
    | | | | \---------- 0 = Single Sided               1 = Double Sided
    | | | \------------ 0 = Single Step Drive          1 = Double Step Drive
    | | \-------------- 0 = Motor Always On            1 = Drive Motor Control Needed
    | \---------------- 0 = Max Speed 5.25" (300 rpm)  1 = 8" & HD Max Speed (360 rpm)
    \------------------ 0 = Double Density             1 = Single Density
```

For Hard Disk Partitions and the RAM Drive, this byte is not used and is set to all Zeros indicating a Fixed Drive type.

`DPH-2` Driver ID Number (Byte)

Three Driver Types are used in the basic B/P Bios configuration. A Zero value indicates a Non-existent driver, with other values used to direct disk accesses to the respective code appropriate to the device. Basic defined driver types exist for Floppy Disk (1), Hard Disk via the SCSI interface (2), and RAM Disk (3). If you wish to extend this table to include tailored drivers, please consult with the authors to preclude possible conflicts with planned extensions.

`DPH-1` Physical Drive/Unit Number (Byte)

This byte contains the Physical Drive or Unit Number hosting the logical drive. For Floppy Drives, this will usually be in the range of 0 to 3 for four drives. Hard drives may have several DPHs sharing the same physical drive number, while this field is ignored in the single RAM drive supported in the distribution B/P Bios version.

**NOTE:** The Physical Drive Number byte for Hard Drives is comprised of two fields to ease handling of SCSI devices. Up to seven devices (device 111B is reserved for the Host Computer) each having up to 8 Logical Units may be defined. The Byte is configured as:

```generic
Bit 7 6 5 4 3 2 1 0
    | | | | | \-------- Physical Device (000-110B, 111B reserved for Host)
    | | | | \----------  <reserved>
    | | | \------------ 0 = Unit Not Available, 1 = Unit Active
    \------------------ Logical Unit Number (000-111B)
```

`DPH+0` Skew Table Pointer (Word)

This word contains a pointer to the Skew table indicator. It rarely is used for Hard and RAM drives, but is required in Floppy Disk drives. If the Bios was assembled using the Calculated Skew option, the address is of a Byte whose absolute value indicates the numerical value of skew (normally in the range of 1 to 6) used for disk accesses. This term is often replaced with Interleave, and is synonymous for this purpose. If the value of the byte is negative, it means that the sectors are recorded in a skewed form on the disk and that Reads and Writes should be sequential. If the value is positive, then an algorithm is called to compute a physical sector number based on the desired logical sector and the skew factor. For systems assembled without Calculated skew, this word points to a table of up to 26 bytes which must be indexed with the desired Physical Sector number (0..Maximum Sector Number) to obtain the corresponding Disk Sector number.

`DPH+2` Dos Scratch Area (3 Words)

These three words are available for the Dos to use as it requires. No fixed values are assigned, nor are meanings for the data stored there of any value.

`DPH+8` Directory Buffer Pointer (Word)

This word points to a 128-byte Data area that is used for Directory searches. It is usually a common area to all DPH's in a system and is frequently updated by the Dos in normal use.

`DPH+10` DPB Pointer (Word)

This word points to another data structure which details many of the logical parameters of the selected drive or partition. Its structure is detailed in Section 5.2.3 below. Drives of the same type and logical configuration may share DPB definitions, so it is not uncommon to find the DPB pointers in different DPH structures pointing to the same area.

`DPH+12` Disk Checksum Buffer (Word)

This word points to a scratch RAM buffer area for removable-media drives used to detect disk changes. Normally this feature is used only for Floppy Disk Drives, and is disabled by containing a Zero word (0000H) for Hard and RAM drives. For Floppy Drives, a RAM area with one byte for every four directory entries (128-byte sector) is needed (See 5.2.3, DPH+11/12). This scratch area cannot be shared among drives.

It should be noted that in a fully Banked B/P Bios system with ZSDOS2, the Checksum Buffer is placed in the System Bank and not directly accessible by applications programs.

`DPH+14` Allocation Vector (ALV) Buffer (Word)

This word points to a bit-mapped buffer containing one bit for each allocation block on the subject drive (See 5.2.3, DPB+5/6). A "1" bit in this buffer means that the corresponding block of data on the device is already allocated to a file, while a "0" means that the block is free. This buffer is unique to each logical drive and cannot be shared among drives.

It should be noted that in a fully Banked B/P Bios system with ZSDOS2, the ALV Buffer is placed in the System Bank and not directly accessible by applications programs. Since access to the ALV buffer is frequently needed to compute free space on drives, ZSDOS2 contains an added function to return disk free space. Using this call allows applications access to the information without directly accessing the data structure.


### 5.2.3 Disk Parameter Block

The Disk Parameter Block (DPB) is a data structure defined by Digital Research for CP/M which defines the logical configuration of storage on mass storage. It has been expanded in B/P Bios to include additional information to provide enhanced flexibility and capability. The expansion is referred to as the Extended DPB or XDPB, and prepends the actual DPB structure. The address of the DPB may be obtained from the DPH pointer returned by the Bios or Dos after a disk selection (See 5.2.2 above). All DPBs reside in the Common Memory area and are available to applications programs whether in a Banked or Unbanked system. For the sake of a convention, the DPBs are labeled in the same manner as DPHs with DPB00-DPB49 used for Floppy Drives, DPB50-DPB89 for Hard Drive Partitions, and DPB90-99 for RAM Drives.


| Offset (hex) | (dec) | Description | Data type |
| :---: | :---: | :--- | :--- |
|  -0x10 / 0xEA | -16 | Ascii ID String | 10 Bytes |
|  -0x06 / 0xFA | -6  | Format Type Byte 0 | Byte |
|  -0x05 / 0xFB | -5  | Format Type Byte 1 | Byte |
|  -0x04 / 0xFC | -4  | Skew Factor | Byte |
|  -0x03 / 0xFD | -3  | Starting Sector Number | Byte |
|  -0x02 / 0xFE | -2  | Physical Sectors per Track | Byte |
|  -0x01 / 0xFF | -1  | Physical Tracks per Side | Byte |
|  +0x00 | +0  | Sectors per Track | Word |
|  +0x02 | +2  | Block Shift Factor | Byte |
|  +0x03 | +3  | Block Mask | Byte |
|  +0x04 | +4  | Extent Mask | Byte |
|  +0x05 | +5  | Disk Size (Capacity) | Word |
|  +0x07 | +7  | Maximum Directory Entry | Word |
|  +0x09 | +9  | Allocations 0 and 1 | Word |
|  +0x0B | +11 | Check Size | Word |
|  +0x0D | +13 | Track Offset | Word |


The layout of the Disk Parameter Block as indexed from the available DPB pointer is:

`DPB-16` Ascii ID String (10 Bytes)

This string serves as an identification which may be printed by applications programs such as our BPFORMAT. This string may be a mixed alphanumeric Ascii set of up to ten characters, but the last valid character must have the Most Significant Bit (Bit 7) Set to a "1".

`DPB-6` Format Type Byte 0 (Byte)

This byte contains some of the information about the format of the drive, and the logical sequencing of information on the physical medium. The bits in the byte have the following significance:

```generic
Bit  7 6 5 4 3 2 1 0
     | | | | | \-------- Disk Size:  000 = Fixed Disk, 001 = 8", 010 = 5.25", 011 = 3.5"
     | | \-------------- Track Type
     | |                    000 = Single Side       001 = Reserved
     | |                    010 = Sel by Sec, Cont  011 = Sel by Sec, Sec # Same
     | |                    100 = S0 All, S1 All    101 = S0 All,S1 All Reverse
     | |                    110 = Sel by Trk LSB    111 = Reserved
     | \---------------- 0 = Track 0 Side 0 is Double Density, 1 = Single Density
     \------------------ 0 = Data Tracks are Double Density, 1 = Single Density
```

For Hard Drives and RAM Drives, this byte contains all Zero bits to signify Fixed Media and format.

`DPB-5` Format Type Byte 1 (Byte)

This byte contains additional information about the format of information. The bits have the following meanings:

```generic
Bit  7 6 5 4 3 2 1 0
     | | | | | \--------- Sector Size:  000 = 128, 001 = 256, 010 = 512, 011 = 1024
     | | \--------------- Allocation Size:  000=1K, 001=2K, 010=4K, 011=8K, 100=16K
     | |                     (NOTE: This should match the definition in DPH)
     | \----------------- <Reserved>
     \------------------- 0 = Normal Speed (300 rpm)
                          1 = 8" & HD Floppy (360 rpm) or Hard Drive
```

For Hard Drives, The distribution version of B/P Bios and the support utilities assume that the Sector size is always 512 bytes. The remaining bits should be set as indicated.

`DPB-4` Skew Factor (Byte)

This byte is a signed binary value indicating the skew factor to be used during Format, Read and Write. It is normally used only with Floppy Drives and usually set to -1 (0FFH) for Hard and RAM drives to indicate that Reads and Writes should be done with No skew. If the option to calculate skew is in effect during Bios assembly, the Skew pointer in the DPH (BPH+0/1) points to this byte. If a skew table is used, this byte has no effect and should be set to 80H.

`DPB-3` Starting Sector Number (Byte)

This byte contains the number of the first Physical Sector on each track. Since most Disk Operating Systems use a Zero-based sequential scheme to reference sectors, this value provides the initial offset to correct logical to physical sector numbers.

`DPB-2` Physical Sectors per Track (Byte)

This byte contains the number of Physical (as opposed to logical) Sectors on each track. For example, CP/M computes sectors based on 128-byte allocations which are used on single-density 8" Floppy Disks. One of the popular five- inch formats uses five 1k physical sectors which equates to 40 logical CP/M sectors. This byte contains 5 in this instance for the number of 1k Physical Sectors.

`DPB-1` Physical Tracks per Side (Byte)

This byte contains the number of Physical Tracks per Side, also called the Number of Cylinders. It reflects the Disk, as opposed to the Drive capabilities and is used to establish the requirements for double-stepping of Floppy Drives. In the case of a 40-track disk placed in an 80-track drive, this byte would contain 40, while the Drive parameter in the Configuration Section contains 80 as the number of tracks on the drive. This byte has no meaning for Hard Drive partitions or RAM drives and should be set to Zero, although any arbitrary value is acceptable.

`DPB+0` Physical Tracks per Side (Word)

This value is the number of Logical 128-byte sectors on each data track of the disk. It is equivalent to the number of Physical Sectors times the Physical Sector Size MOD 128.

`DPB+2` Block Shift Factor (Byte)
`DPB+3` Block Mask (Byte)
`DPB+4` Extent Mask (Byte)

These three bytes contain values used by the Operating System to compute Tracks and Sectors for accessing logical drives. Their values are detailed in various references on CP/M and ZSDOS programming and should not be varied without knowledge of their effects.

`DPB+5` Disk Size / Capacity (Word)

This Word contains the number of the last allocation block on the drive. It is the same as the capacity in allocation blocks - 1. For example, if 4k allocation blocks are being used and a 10 Megabyte drive is being defined, this word would contain 10,000,000/4000 - 1 or 2499.

`DPB+7` Maximum Directory Entry (Word)

This Word contains the number of the last Directory Entry and is the same as the Number of Entries - 1. For example, if 1024 directories are desired, this word would be set to 1024 - 1 = 1023.

`DPB+9` Allocations 0 and 1 (2 Bytes)

These two Bytes hold the initial allocations stored in the first two bytes of the ALV Buffer (See 5.2.2, DPH+14/15) during initial drive selection. Their primary use is to indicate that the Directory Sectors are already allocated and unavailable for data storage. They are bit-mapped values and are used in Hi-byte, Lo-byte form as opposed to the normally used Lo-byte, Hi-byte storage used in Z80 type CPUs for Word storage. The bits are allocated from the MSB of the first byte thru the LSB, then MSB thru LSB of the second byte based on one bit per allocation block or fraction thereof used by the Directory. The bits may be calculated by first computing the number of entries per allocation block, then dividing the desired number of entries by this number. Any remainder requires an additional allocation bit.

For example, if 4k allocation blocks are used, each block is capable of 4096/32 bytes per entry = 128 Directory Entries. If 512 entries are desired, then 512/128 = 4 allocation blocks are needed which dictates that Allocation byte 0 would be 11110000B (0F0H) and Allocation Byte 1 would be 00000000B.

`DPB+11` Check Size (Word)

This Word is only used in removable media (normally only Floppy Drives) and indicates the number of sectors on which to compute checksums to detect changed disks. It should be set to 0000H for Fixed and RAM Disks to avoid the time penalty of relogging after each warm boot.

`DPB+13` Track Offset (Word)

This Word indicates the number of Logical Tracks to skip before the present DPB is effective. It is normally used to reserve boot tracks (usually 1 to 3), or to partition larger drives into smaller logical units by skipping tracks used for other drive definitions.


### 5.3.1 Environment Descriptor

The Environment Descriptor, referred to as simply the ENV, is the heart of what is now known as The Z-System. The most recent additions to the system by Joe Wright and Jay Sage replaced some relatively meaningless elements in the ENV with system dependent information such as the location of the Operating System components. Consequently, the ENV is not just a feature of the ZCPR 3.4 Command Processor Replacement, but is an Operating System Resource which allows other programs such as ZCPR 3.4 to access its information.

The B/P Bios requires an ENV to be present, and uses several items of information contained in it. The banked ZSDOS2 and Z40 Command Processor Replacement use even more ENV features. A few remaining bytes have been re-defined for support to B/P Bios-based systems. To denote the definition of B/P Bios data elements, a new Type, 90H, has been reserved. Using this "Type" byte, user programs can access and take advantage of the new definitions and features.

A template for the Environment Descriptor used in B/P Bios which takes its values from the Z3BASE.LIB file included in the distribution disk is:


### 5.3.2 Terminal Capabilities

In addition to the Basic Environment Descriptor described above, a dummy Terminal Capability record structure (TCAP, also known as TERMCAP) is attached to reserve space for, and define default capabilities of the computer terminal. The default TERMCAP is fully compliant with the VLIB routines used in the Z-System Community after VLIB4D. The skeleton record structure is:


## 5.4 ZSDOS2 Function Reference

| Number | Fcn Name | Input Parameters     | Returned Values         |
|:------:|:---------|:---------------------|:------------------------|
| 0 | Boot                 | None        | None |
| 1 | Console Input        | None        | A=Character |
| 2 | Console Output       | E=Character | A=00H |
| 3 | Reader Input         | None        | A=Character |
| 4 | Punch Output         | E=Character | A=00H |
| 5 | List Output          | E=Character | A=00H |
| 6 | Direct Console I/O   | E=0FFH (In) | A=Input Character |
|   |  | E=0FEH (In)       | A=Console Status |
|   |  | E=0FDH (In)       | A=Input Character |
|   |  | E=00H..0FCH (Out) | A=00H |
|  7 | Get I/O Byte        | None              | A=I/O Byte (0003H) |
|  8 | Set I/O Byte        | E=I/O Byte        | A=00H |
|  9 | Print String        | DE=Address String | A=00H |
| 10 | Read Console Buffer | DE=Address Buffer | A=00H |
| 11 | Get Console Status  | None              | A=00H = No character |
|    |                     |  | A=01H = Char. present |
| 12 | Get Version Number  | None | A=Version Number (22H) |
| 13 | Reset Disk System   | None | A=00H No $*.* on A |
|    |                     |  | A=FFH $*.* on A |
| 14 | Select Disk         | E=Disk Number | A=00H No $*.* File |
|    |                     |   | A=FFH $*.* File |
| 15 | Open File           | DE=Address of FCB | A=Directory Code |
| 16 | Close File          | DE=Address of FCB | A=Directory Code |
| 17 | Search for First    | DE=Address of FCB | A=Directory Code |
| 18 | Search for Next     | DE=Address of FCB | A=Directory Code |
| 19 | Delete File         | DE=Address of FCB | A=Error Code |
| 20 | Read Sequential     | DE=Address of FCB | A=Read/Write Code |
| 21 | Write Sequential    | DE=Address of FCB | A=Read/Write Code |
| 22 | Make File           | DE=Address of FCB | A=Directory Code |
| 23 | Rename File         | DE=Address of FCB | A=Error Code |
| 24 | Get Login Vector    | None           | HL=Login Vector |
| 25 | Get Current Disk    | None           | A=Current Disk |
| 26 | Set DMA Address     | DE=DMA Address | A=00H |
| 27 | Get Alloc. Address  | None           | HL=Addr Alloc Vector |
| 28 | Write Protect Disk  | None           | A=00H |
| 29 | Get R/O Vector      | None           | HL=R/O Vector |
| 30 | Set File Attributes | DE=Address FCB | A=Error Code |
| 31 | Get DPB Address     | None           | HL=Address of DPB |
| 32 | Set/Get User Code   | E=FFH (Get)    | A=User Number |
|    |                     | E=User Number (Set) | A=00H |<
| 33 | Read Random       | DE=Address of FCB | A=Read/Write Code |
| 34 | Write Random      | DE=Address of FCB | A=Read/Write Code |
| 35 | Compute File Size | DE=Address of FCB | A=Error Code |
| 36 | Set Random Record | DE=Address of FCB | A=00H |
| 37 | Reset Mult Drive  | DE=Mask  | A=00H |
| 38 | Not Implemented |  |  |
| 39 | Get fixed disk vector | None | HL=Fixed Disk Vector |
| 40 | Write random, 00 fill | DE=Addr of FCB | A=Read/Write Code |
| 41-44 | Not Implemented | | |
| 45 | Set error mode | E=FFH (Get)          | A=00H |
|    |                | E=FEH (Get Err/Disp) | A=00H |
|    |                | E=01H (Set ZSDOS)    | A=00H |
|    |                | E=00H (Set CP/M)     | A=00H |
| 46 | Return Free Space | E=Disk Number | A=Error Code |
|    |                |  | Space in DMA+0..DMA+3 |
| 47 | Get DMA address   | None | HL=Current DMA Address |
| 48 | Get DOS & version | None | H=DOS type: "S"=ZSDOS, "D"=ZDDOS |
|    |                   |      | L=BCD Version Number |
| 49 | Return ENV Address | None | HL=Env. Descriptor Addr |
| 50-97 | Not Implemented | | |
| 98 | Get time | DE=Address to Put Time | A=Time/Date Code |
| 99 | Set time | DE=Address of Time     | A=Time/Date Code |
| 100 | Get flags      | None           | HL=Flags |
| 101 | Set flags      | DE=Flags       | None |
| 102 | Get file stamp | DE=Addr of FCB | A=Time/Date Code, |
|     |                |                | Stamp in DMA Buffer |
| 103 | Set file stamp | DE=FCB Address, | A=Time/Date Code |
|     |                | Stamp in DMA Buffer |  |
| 104-151 | Not Implemented | | |
| 152 | Parse FileSpec | DE=FCB Address, | A=No. of "?"s in Fn.Ft |
|     |                | String in DMA Buffer | DE=Addr of delimit chr |
|     |                |  | FCB+15=0 if Parse Ok, 0FFH if Error(s) |
| 153-255 | Not Implemented | | |


| BDOS Codes |  |
| :--- | :--- |
| Directory Codes: | A=00H, 01H, 02H, 03H if No Error |
|  | A=FFH if Error |
| Error Codes: | A=00H if No Error |
|  | A=0FFH if error |
| Time/Date Codes: | A=01H if No error |
|  | A=0FFH if error |
| Read/Write Codes: | A=00H if No error |
|  | A=01H Read - End of File / Write - Directory Full |
|  | A=02H Disk Full |
|  | A=03H Close Error in Random Record Read/Write |
|  | A=04H Read Empty Record during Random Record Read |
|  | A=05H Directory Full during Random Record Write |
|  | A=06H Record too big during Random Record Read/Write |
| Extended Error codes | A=0FFH Extended Error Flag |
| in Return Error Mode: | H=01H Disk I/O Error (Bad Sector) |
|  | H=02H Read Only Disk |
|  | H=03H Write Protected File |
|  | H=04H Invalid Drive (Select) |


## 5.5 Datespec and File Stamp Formats

The universal stamp and time formats used by ZSDOS are based on packed BCD  digits. It was decided that these were the easiest format for Z80 applications programs to work with, and were compatible with most real time clocks. The format for the stamps and for the clock functions are identical to the Plu*Perfect DateStamper's formats for these functions.

Some file stamping formats (for example CP/M Plus type) do not store all the information present in the universal format to disk. In the case of CP/M Plus type stamps, there is no provision for stamping the Last Access time. The ZSDOS interface routines fill unimplemented fields in the stamp with 0 when the Get Stamp function is used, and ignore the contents of the unused fields when the Put Stamp function is used.

Depending on the stamping method selected, the format of the stamps on the disk may differ from the universal format. These differences are effectively hidden from users by ZSDOS and the Stamp routines so long as ZSDOS's functions are used to get or manipulate the stamps.

Time format (6 bytes packed BCD):

| Byte  | Description |
| :---: | :--- |
| `TIME+0` | last 2 digits of year |
|          | (prefix 19 assumed for 78 to 99, else 20 assumed) |
| `TIME+1` | month  [1..12] |
| `TIME+2` | day    [1..31] |
| `TIME+3` | hour   [0..23] |
| `TIME+4` | minute [0..59] |
| `TIME+5` | second [0..59] |

File Stamp format (15 bytes packed BCD):

| Location | Description |
| :---: | :--- |
| `DMA+0 ` | Create field (first 5 bytes of time format) |
| `DMA+5 ` | Access field (first 5 bytes of time format) |
| `DMA+10` | Modify field (first 5 bytes of time format) |
