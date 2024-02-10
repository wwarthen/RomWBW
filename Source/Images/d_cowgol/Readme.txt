===== Cowgol 2.0 for CP/M =====

This disk contains the Cowgol 2.0 compiler and related tools.
These files were provided by Ladislau Szilagyi and were sourced
from his GitHub repository at https://github.com/Laci1953/Cowgol_on_CP_M.

The COWFE program included here is the RomWBW-specific version that
is tailored to RomWBW memory management.

The primary distribution site for Cowgol 2.0 is at
https://github.com/davidgiven/cowgol.

The Hi-Tech C compiler components were sourced from the updated
version by Tony Nicholson at https://github.com/agn453/HI-TECH-Z80-C.
However, the CPP.COM component was sourced from Ladislau Szilagyi's
enhanced Hi-Tech C at https://github.com/Laci1953/HiTech-C-compiler-enhanced.

Note that only the minimum required Hi-Tech C compiler components
are provided.  Additional components from Hi-Tech C may be required
depending on your needs.

There are two example Cowgol applications included:

- HEXDUMP is a simple hex dump utility and is purely a Cowgol
  application (no assembler or C components).  The command
  line to build the application is:

    COWGOL HEXDUMP.COW

- DYNMSORT demonstrates a sort algorithm and is composed of
  Cowgol, C, and assembler components.  The command line to
  build the application is:

    COWGOL -LC DYNMSORT.COW MERGES.C RAND.AS

There are also SUBMIT files provided to build the example
applications which can be used as follows:

    SUBMIT HEXDUMP
    SUBMIT DYNMSORT

-- WBW 12:38 PM 2/10/2024    

    

