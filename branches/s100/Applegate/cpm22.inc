;********************************************************
; This file contains bits of information that are common
; between the CCP, BDOS and BIOS.  Since the CCP and
; BDOS are built as one unit and the BIOS as another, it
; is handy to have common things in a common file rather
; that constantly needing to keep things in sync between
; two different files.
;
; 02/16/2013 - Bob Applegate


;
; This is the TOTAL RAM in the system.  Ie, starts at 64
; but then gets decreased due to ROM monitors at top of
; memory.  This can be set artificially low to allow
; more room for BIOS debugging code.
;
; This is the amount of contiguous RAM from 0000.
;
RAMSIZE		EQU	48	;expressed in K

;
; Low memory locations
;
IOBYTE		EQU	3	;i/o definition byte.
TDRIVE		EQU	4	;current drive name and user number.
ENTRY		EQU	5	;entry point for the cp/m bdos.



CCPSIZE		EQU	0800H	;I hate hard-coding things!
BDOSSIZE	EQU	0E00H

;
; Where CP/M things are located
;
CCPBASE		equ	(RAMSIZE-7)*1024
BDOSBASE	equ	(CCPBASE+CCPSIZE)
BIOSBASE	equ	(BDOSBASE+BDOSSIZE)
