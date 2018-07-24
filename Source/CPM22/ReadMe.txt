OS2CCP & OS3BDOS
----------------

Sourced from DRIPAK archive.

It appears to have come from DRI and seems to be the closest
version of pure original source.  The source is commented, but
utilizes multiple statements per line.

OS2CCP.BAK - Original file from DRIPAK
OS2CCP.ASM - Modified ORG

OS3BDOS.BAK - Original file from DRIPAK
OS3BDOS.ASM - Modified ORG & DRI CPM22PAT01 applied

CCP & BDOS
----------

Sourced from DRIPAK archive.

It is a nicer formatted version of above.  Lines
expanded to one statement per line.  The case of message string
literals has been modified, but
otherwise byte identical to OS2CCP & OS3BDOS.

CCP.BAK - Original file from DRIPAK
CCP.ASM - Modified ORG

BDOS.BAK - Original file from DRIPAK
BDOS.ASM - Modified ORG & DRI CPM22PAT01 applied

CCP22 & BDOS22
--------------

Sourced from DRIPAK archive.

It is an independent disassembly and reconstruction of CCP/BDOS.
DRI CPM22PAT01 was already applied.  Unclear why, but the BDOS
source was checking for a blank instead of a ctrl-s in the
KBSTAT routine.  Ctrl-s seems to be correct based on all other
BDOS images I have encountered.  Also, these files imbed the
CP/M version number into the serial number fields.  Other than
this, they are byte identical to the OS2CCP/OS3BDOS images above.

CCP22.BAK - Original file from DRIPAK
CCP22.ASM - Modified ORG

BDOS22.BAK - Original file from DRIPAK
BDOS22.ASM - Modified ORG & fix for ctrl-S

CCPB03 & BDOSB01
----------------

Sourced from N8VEM effort to create an enhanced
variant of CP/M 2.2.

It appears to be a disassembly and reconstruction of CCP/BDOS,
but there are no comments attributing the work.  DRI CPM22PAT01
was already applied.  The message string literals are all
in CAPS in BDOS.  Additionally, there is explicit filler of 0x55
value bytes at the end of the CCP/BDOS files padding their
length out to full page.  Other than this, the BDOS
is byte identical to the others above.  CCP contains multiple
enhancements and is, therefore, not identical to others.

CCPB03.ASM - Enhanced reassembly of CCP

BDOSB01.ASM - Reassembly of BDOS w/ DRI Patch 01

---

The first 6 bytes of BDOS are the serial number.  In general,
the BDOS sources just leave all six bytes as 0x00.  The
one exception is BDOS22 which defines the 6 bytes to be a
hybrid of CP/M version information and serial number.  This is
basically irrelevant unless MOVCPM is used, in which case
the 6 byte serial number field must match with MOVCPM.

---

The DRI CP/M Patch #01 (DRI CPM22PAT01) is defined to be
nop; nop; lxi h,0 and that is how I have patched OS3BDOS & BDOS.
However, BDOS22 uses nop; nop; lxi h,fbase for the patch.
In practice, this difference does not matter because the value
placed in HL at this point is unused (immediately overwritten).

---