# GLOSSARY

**Application Programs**
In contrast to utility programs (see), application programs or applications are larger programs such as word processors which function interactively with the user.

**BDOS**
Basic Disk Operating System. The machine-independent, but usually processor-dependent, program which controls the interface between application programs and the machine-dependent hardware devices such as printers, disk drives, clocks, etc. It also establishes the concept of files on media and controls the opening, reading, writing, and closing of such constructs.

**BGii**
BackGrounder ii from Plu*Perfect Systems, a windowing task-switching system for CP/M users with hard or RAM disks.

**BIOS**
Basic Input/Output System. Machine-dependent routines which perform actual peripheral device control such as sending and receiving characters to the console, reading and writing to disk drives, etc.

**Bit**
BInary digiT. An element which can have only a single on or off state.

**Bit Map**
An array of bits used to represent or map large arrays of binary information in a compact form.

**Boot**
The term used for the starting sequence of a computer. Generally applies to starting from a "Cold," or power-off state, and includes the loading of Operating System, and configuration steps.

**Byte**
A grouping of eight bits.

**CPR**
Command Processor Replacement. Replaces CCP (see below). Example: ZCPR

**CCP**
Console Command Processor. The portion of the operating system that interprets user's commands and either executes them directly or loads application programs from disk for execution. The CCP may be overwritten by applications, and is reloaded by the "Warm Boot" function of the BIOS.

**Checksum**
An value which arithmetically summarizes the contents of a series of memory locations, and used to check the current contents for errors.

**Clock Driver**
A software link between a Non-banked ZSDOS and the clock on your system. The clock driver allows ZSDOS and its utilities to read the clock which is normally inherent in the B/P Bios.

**Command Script**
Sometimes called simply scripts, command scripts allow you to create a single command which issues other commands to perform a unique set of actions. CP/M submit files are one kind of command script familiar to all CP/M users. ZCPR also offers more sophisticated types of scripts such as aliases and command files (e.g., ALIAS.CMD).

**DateStamper**
A software package developed by Plu*Perfect Systems to allow time and date stamping of files. The Boot System uses an external module in the file LDDS.COM to implement DateStamper, while ZSDOS2 automatically supports this stamping method. DateStamper is unique among file stampers for microcomputers for two reasons: first, it maintains all file stamps within a file; second, it maintains stamps for create, access, and modify time/date for each file.

**DDT**
Dynamic Debugging Tool. A utility distributed with CP/M 2.2 which can display, disassemble, or alter disk files or areas of memory using opcodes or hexadecimal values.

**DOS**
Disk Operating System. Often used term for the BDOS, but generally refers to the aggregate of CCP, BDOS and BIOS.

**DosDisk**
A software package from Plu*Perfect Systems which allows users of CP/M and compatible computers to write and read files directly to and from standard 5-1/4" 40-track Double-Sided, Double-Density MS-DOS format diskettes. This is the standard "360k" disk format used in IBM-PC compatible computers.

**FCB**
File Control Block. A standard memory structure used by CP/M and compatible operating systems to regulate disk file operations.

**File Attributes**
Also known as file attributes, reserved bits stored along with file names in disk directories which control how the files are accessed.

**Hexadecimal**
A base-16 numbering system consisting of the numbers 0-9 and letters A-F. Often used to represent bytes as two digits (00 to FF). Use of Hexadecimal numbers is usually represented by suffixing the number with an "H" as in "01H".

**IOBYTE**
Input/Output Byte. A reserved byte at location 3 which is used by some CP/M BIOS's to redirect input and output between devices such as terminals and printers.

**K**
Usually refers to Kilobyte or 1024 (2^10th power) bytes.

**P2D**
P2Dos Datestamps. An alternative form of file stamping used in HAJ Ten Brugge's P2DOS. P2D stamps are compatible with CP/M Plus time and date stamps. This format is supported in a B/P Boot system with the LDP2D.COM Stamp module, and automatically in ZSDOS2.

**RAM**
Random Access Memory. As opposed to Read Only Memory (ROM) the area of a computer's memory which may be both read from and written to.

**RSX**
Resident System Extension. A program module complying with a standard developed by Plu*Perfect Systems for extending the functionality of a CP/M 2.2 compatible Operating System. The module must be loaded at the top of the Transient Program Area, and below the Console Command Processor.

**System Prompt**
The familiar A> prompt which appears soon after CP/M computersare started up.

**TPA**
Transient Program Area. That addressable memory space from the lowest available address to the highest available address. Usually this extends from 100H to the base of the BDOS (assuming that the Command Processor is overwritten), or the base of the lowest RSX.

**Utility Programs**
In contrast to application programs (see), utility programs or utilities are shorter programs, such as directory programs, which accept a single command from the user.

**Wheel Byte**
Taking its name from the colloquial "Big Wheel," the Wheel byte controls security under ZCPR and ZSDOS. When the byte is set to a non-zero value, the user has "Wheel status" and may execute commands unavailable to other users.

**Word**
In the computer context, a fixed number of bytes. For 8- bit microcomputers, a word is usually two bytes, or 16 bits.

**Z-System**
An operating system which completely replaces CP/M by substituting ZCPR for Digital Research's command processor and ZSDOS for Digital Research's disk operating system. ZCPR and ZSDOS complement one another in several ways to enhance performance.

**ZCPR**
Z80 Command Processor Replacement. Originally developed as a group effort of the Special Interest Group for Microcomputers (SIG/M), but refined by Richard Conn to ZCPR version 3.0 and Jay Sage to versions 3.3 and 3.4.

**ZRL**
A form of Relocatable file image using specified "Named Common" bases. For ZSDOS, files of this type are MicroSoft-compatible REL files using only the Common Relative segment "_BIOS_".
