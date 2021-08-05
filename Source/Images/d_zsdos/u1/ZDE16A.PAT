; This patch file modifies the officially-distributed .COM file
; for ZDE Ver 1.6 (copyright by Carson Wilson) to:
;   - Correct a bug which did not preserve create times when
;	editing files > 1 extent.
;   - Use an apparently 'dead' byte in the configuration area as
;	a configuration flag to allow disabling the 'Auto-Indent'
;	feature which was always 'on' in ZDE1.6.
;
; With the second change, you may configure the 'Auto-Indent'
; feature to be active (as distributed) or disabled (as this patch
; is configured) by altering the DB at label 'AIDflt' in the
; second part of this patch file below.
;
; Assemble this file to a .HEX file (example uses ZMAC) as:
;
;	ZMAC ZDE16A.PAT /H
;	
; then overlay the resulting ZDE16.HEX onto ZDE16.COM with MYLOAD
; (or equivalent) as:
;
;	MYLOAD ZDE.COM=ZDE.COM,ZDE16.HEX
;
; The resulting ZDE.COM will be identified as 'ZDE 1.6a' in the
; text identification string near the beginning of the .COM file.
;
; Harold F. Bower, 18 July 2001.
;
; CP/M Standard Equates
;
BDOS	EQU	0005H
FCB	EQU	005CH
DMA	EQU	0080H
TPA	EQU	0100H
;
SDMA	EQU	26		; CP/M Function to set DMA Address
;
; Needed locations within ZDE 1.6
;
Fill	EQU	TPA+0F8BH	; For Date Patch
TimBuf	EQU	TPA+3B3FH	;  "    "    "
;
VTFlg	EQU	TPA+3ADAH	; For Auto-Ins Patch
HCRFlg	EQU	TPA+3AE3H	;  "   "    "    "
LfMarg	EQU	TPA+3AFDH	;  "   "    "    "
;
; ----------- Begin Patch File -----------
;
; --- Fix Create Time Stamp Preservation Error ---

	  ORG  TPA+0029H
				; was:
	DB	'a,  (C)'	;  DB    ', Copr.'
	  ORG  TPA+2461H
				; was:
	LD	(FCB+13),A	;  CALL  ClUsrF
;
	  ORG  TPA+2F10H
				; was:
	LD	B,4		;  CALL  ClUsrF
	CALL	ClUsrF		;  LD    DE,TimBuf
	LD	DE,TimBuf	;  LD    C,SDMA
	CALL	SetDMA		;  CALL  BDOS
;
	  ORG  TPA+30AAH
				; was:
	LD	DE,DMA		;  LD    C,SDMA
SetDMA:	LD	C,SDMA		;  LD    DE,DMA
;
	  ORG  TPA+30B4H
				; was:
ClUsrF:	XOR	A		;  XOR   A
	EX	DE,HL		;  LD    (FCB+13),A
	JP	Fill		;  RET
;
; --- Usurp Config Flag for Auto-Insert use, sense on startup ---
;
	  ORG  TPA+0057H
				; was: 0FFH
AIDflt:	DB	00H		; Set Desired default (0=Off, FF=On)
;
	  ORG  TPA+262AH
				; was:
	LD	(LfMarg),HL	;  LD    HL,0101H
	XOR	A		;  LD    (LfMarg),HL
	LD	(VTFlg),A	;  XOR   A
	LD	(HCRFlg),A	;  LD    (VTFlg),A
	NOP			;  LD    (HCRFlg),A
	LD	A,(AIDflt)	;  DEC   A
;
	  ORG  TPA+2711H
				; was:
	NOP			;  LD    A,(0157H) {Unknown Use}
	NOP			;  OR    A
	NOP			;  JP    Z,Error2
	NOP
	NOP
	NOP
	NOP
;
;------------ End of Patch File ------------
	END
