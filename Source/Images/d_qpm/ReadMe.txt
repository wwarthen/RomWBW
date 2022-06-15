===== QP/M Disk for RomWBW =====

This disk contains the distribution files for the QP/M Operating
System.  The disk is initially set up to boot CP/M 2.2.  You
must use the QINSTALL program to install QP/M on the boot
tracks and subsequently boot QP/M.

== Notes ==

By default, QP/M saves the current drive/user (2 byte value) at address 0x0008.
This is also the address of the Z80 RST 08 restart vector and conflicts with
RomWBW.  When running QINSTALL, you must change the QP/M address for this value
to something else.  I have been using 0x000E without issue.

RomWBW CBIOS has been modified to put the QP/M TIMDAT vector at 0x0010.  The
vector points into CBIOS where the actual TIMDAT routine is located.  The
TIMDAT routine reads the current date/time from HBIOS, changes the values from
BCD to binary, and rearranges some bytes for QP/M compatibilty.

--WBW 5:29 PM 6/4/2022
