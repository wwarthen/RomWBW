# 8 ZCPR Version 4

`Z40.ZRL` is a consolidation of ZCPR34 and many of the RCP features commonly in use, modified by the need to bank as much of the Command Processor as possible. When Z40 is used in a Fully-Banked system, you may not need much of, or any Resident Command Processor with your system. Z40 relys on ZSDOS2 and will **NOT** work without it since the Command Line Parser and disk free space calculations have been removed in favor of ZSDOS2 services. Additionally, the prompt line displays the time and will only function correctly if he ZSDOS2 clock is enabled. Comments on how these new System components work would be appreciated.

More complete documentation is provided in the `Z40.HLP` files included with the distribution diskettes, and a list of active functions is available with the H command at the prompt. To read the On-line help files, use `HELP.COM` available for downloading from any Z-Node.


## 8.1 NOTES Spring 2001

The versions of ZSDOS2 (the Banked Z-System DOS) and Z4x Banked Command Processor Replacement have been modified over the years. The manual may refer to specific versions, or by generic names. As of the Spring 2001 release under the GNU General Public License, the latest version of the Z4x Processor Replacement is `Z41.ZRL` which features a small amount of tailoring. A new utility; **`CONFZ4.COM`** is available for this purpose.
