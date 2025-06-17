# 7 ZSDOS Version 2

Version 2 of ZSDOS is currently in a developmental phase. The version provided with this package is preliminary and should not be considered a final work. Be sure you back up any files which you don't mind sacrificing, and please let us know in as much detail as possible any problems you experience.

In addition to the ZSDOS Version call (Function 48) returning 20H signifying ZSDOS2, three new Operating System functions have been added. They are:

| Function 46 | Return Disk Free Space |
| ---: | :--- |
| Enter: | C = 46 (function #) |
|        | E = Drive # (A=0..P=15) |
| Exit:  | A = 0 if Ok, <>0 if Error |
|        | Disk Free Space in kilobytes is placed in DMA+0 (LSB) thru DMA+3 (MSB) |

This function returns Disk Free Space from fully-banked systems where the ALV buffers are not directly accessible by applications programs. It **MUST** be used to reliably determine free space since there is no way for programs to ascertain which System Bank (if more than one) contains the Allocation Bit Map. For most reasonably-sized systems, only the lower two or three bytes will be used, but four bytes are allocated to accommodate a maximally-sized system.

| Function  | Return Environment Descriptor Address |
| ---: | :--- |
| Enter: | C = 49 (function #) |
| Exit:  | HL = Address of Env Desc. |

This function returns the address of a ZCPR 3.4 "type" Environment Descriptor needed in B/P Bios systems. Rather than rely on the Command Processor inserting the ENV address into application programs upon execution, this function may be used to reliably acquire the ENV address at any time.

| Function 152 | Parse File Name |
| ---: | :--- |
| Enter: | C = 152 (function #) |
|        | DE = Pointer to dest FCB |
|        | DMA --> start of parse string |
| Exit:  | A = Number of "?" in fn.ft |
|        | DE = points to delimiter |
|        | FCB+15 will be 0 if parse Ok, 0FFH if errors occurred |

This function may be used to replace Z3LIB library routines in a more robust manner and produce consequently smaller applications programs. It is fully compliant with ZCPR 3.4 parse specifications.


## 7.1 NOTES Spring 2001

The versions of ZSDOS2 (the Banked Z-System DOS) and Z4x Banked Command Processor Replacement have been modified over the years. The manual may refer to specific versions, or by generic names. As of the Spring 2001 release under the GNU General Public License, Two versions of ZSDOS2 are provided; `ZS203.ZRL` which contains code for hashed directories, and `ZS227G,ZRL` which does not.
