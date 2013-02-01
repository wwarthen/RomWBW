;--------------------------------------------------------
; File Created by SDCC : free open source ANSI-C Compiler
; Version 3.0.2 #6489 (May 10 2011) (Mac OS X x86_64)
; This file was generated Sat May 21 07:40:18 2011
;--------------------------------------------------------
	.module loaderhc
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _loaderhc
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; overlayable items in  ram 
;--------------------------------------------------------
	.area _OVERLAY
;--------------------------------------------------------
; external initialized ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;loaderhc.c:1: void loaderhc(void)
;	---------------------------------
; Function loaderhc
; ---------------------------------
_loaderhc_start::
_loaderhc:


;***********************************
;*	Z180 Home Computer Prototype
;*	LOAD MONITOR FROM ROM INTO RAM AND EXECUTE Program
;*	Andrew Lynch
;*	lynchaj@yahoo.com
;*	15 Feb 2007
;* 	Updated by Max Scane 26 May 2010 for increase in BIOS size
;*	Updated by Max Scane April 2011 for the home computer
;***********************************

	.area	_HEADER (ABS)

;********************* CONSTANTS ****************************************

RAMTOP 		= 	0xffff		; highest addressable memory location
MONSTART	= 	0xf800		; start of 2k for rom monitor f800-ffff
RAMBOTTOM	=	0x8000		; beginning of upper 32k of ram
END		=	0xff		; mark ed of text
CR		=	0x0d
LF		=	0x0a
ESC		=	0x1b


ROMSTART_MON	=	0x0100	; Where the Monitor is stored in ROM
RAMTARG_MON	=	0xF800	; Where the Monitor starts in RAM (entry point)
MOVSIZ_MON	=	0x0800	; Monitor is 2KB in length

ROMSTART_CPM	=	0x0900	; Where the CCP+BDOS+BIOS is stored in ROM
RAMTARG_CPM	=	0xD400	; Where the CCP+BDOS+BIOS starts in RAM 
MOVSIZ_CPM	=	0x1F00	; CCP, BDOS, + BIOS is 7-8KB in length

Monitor_Entry	=	0xF860	; Monitor Entry Point (May change)


HC_REG_BASE     =	0x80             ; HOME COMPUTER I/O REGS $80-$9F
PPI1		=	HC_REG_BASE+0x00
ACR		=	HC_REG_BASE+0x14
RMAP            =	ACR+2

IO_REG_BASE	=	0x40		; IO register base offset for Z1x80
CNTLA0		=	IO_REG_BASE+0x00
CNTLB0		= 	IO_REG_BASE+0x02
STAT0		=	IO_REG_BASE+0x04
TDR0		=	IO_REG_BASE+0x6
RDR0		=	IO_REG_BASE+0x08
CBR		=	IO_REG_BASE+0x38
BBR		=	IO_REG_BASE+0x39
CBAR		=	IO_REG_BASE+0x3a
ICR             =       0x3f             ; not relocated!!!


;*******************************************************************
;*	START AFTER RESET
;*	Function	: ready system, load monitor into RAM and start
;*******************************************************************

	.ORG	0x0000
	jp		ENTRY

	; place here data for the loader to use for booting (later)
	;
	; Note before you move the monitor into top of RAM you need to setup
	; the MMU.  Currently it is setup compatible with the N8VEM V1 as
	; 32KB common and 32KB banked
	; This may change in the future
	;
ENTRY:
	DI							; Disable interrupts
        ld      a,#IO_REG_BASE                   ; get the Relocation value

;	out0	(ICR),a
	.db	0x0ed,0x39,ICR

	ld	a,#0x80				; setup for a 33/32 KB memory plan
;	out0	(CBAR),a
	.db	0x0ed,0x39,CBAR

	ld	a,#0x00

;	out0	(BBR),a				; banked area starts at 0
	.db	0x0ed,0x39,BBR

	ld	a,#0x00
;	out0	(CBR),a				; so does common area
	.db	0x0ed,0x39,CBR
	
	LD	SP,#RAMTOP			; Set stack pointer to top of ram
	IM	1					; Set interrupt mode 1

	LD	HL,#ROMSTART_MON		; where in rom Monitor is stored 
	LD	DE,#RAMTARG_MON		; where in ram to move Monitor to 
	LD	BC,#MOVSIZ_MON		; number of bytes to move from ROM to RAM
	LDIR				; Block Copy Monitor to Upper RAM page

	LD	HL,#ROMSTART_CPM		; where in rom CP/M is stored (first byte)
	LD	DE,#RAMTARG_CPM		; where in ram to move CP/M to (first byte)
	LD	BC,#MOVSIZ_CPM		; number of bytes to move from ROM to RAM
	LDIR				; Block Copy of CP/M to Upper RAM page

;	EI		; enable interrupts (access to Monitor while CP/M running)

	JP	MONSTART			; jump to Start of Monitor


;************************************************************************
;*	MASKABLE INTERRUPT-PROGRAM
;*	Function	:
;*	Input		:
;*	Output		: 
;*	uses		: 
;*	calls		: none
;*	info		:
;*	tested		: 2 Feb 2007
;************************************************************************

	.ORG	0x0038				; Int mode 1
	RETI						; return from interrupt


;************************************************************************
;*	NONMASKABLE INTERRUPT-PROGRAM
;*	Function	:
;*	Input		:
;*	Output		: none
;*	uses		: 
;*	calls		: none
;*	info		:
;*	tested		: 2 Feb 2007
;************************************************************************

	.ORG	0x0066		; HERE IS THE NMI ROUTINE
;;;	RETI
	RETN                    ; return from NMI

	.ORG	0x00FF
FLAG:	.db	0x0FF


_loaderhc_end::
	.area _CODE
	.area _CABS
