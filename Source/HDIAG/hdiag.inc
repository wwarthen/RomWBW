;
;=======================================================================
; HDIAG Diagnostic ROM Global Definitions
;=======================================================================
;
; Include this file in modules written to run under HDIAG to
; have access to the HDIAG global variables and jump table
; definitions.
;
; It is important to use the definitions in this file because
; the internal structure of HDIAG is very likely to change
; over time.
;
; Global Variable Addresses
;
hd_cpu		.equ	$FF80	
hd_mmgr		.equ	$FF81
;
; HDIAG Function Jump Table Vectors
;
hd_jptbl	.equ	$FF00
hd_cinit	.equ	hd_jptbl + 0	; init console
hd_cin		.equ	hd_jptbl + 3	; read console byte
hd_cout		.equ	hd_jptbl + 6	; write console byte
hd_cist		.equ	hd_jptbl + 9	; console input status
hd_cost		.equ	hd_jptbl + 12	; console output status
;
; CPU Identified Constants (value of hd_cpu)
;
hd_cpu_none	.equ	0		; unknown cpu
hd_cpu_z80	.equ	1		; plain Z80
hd_cpu_z180	.equ	2		; original Z180 (HD64180)
hd_cpu_z180k	.equ	3		; Zilog Z180 Rev. K
hd_cpu_z180n	.equ	4		; Zilog Z180 Rev. N
hd_cpu_z280	.equ	5		; Zilog Z280
;
; Memory Manager Identified Constants (value of hd_mmgr)
;
hd_mm_none	.equ	0		; unknown memory manager
hd_mm_sbc	.equ	1		; SBC/MBC/Zeta 1
hd_mm_z2        .equ	2		; Zeta 2/RC2014
hd_mm_z180      .equ	3		; Z180 native
hd_mm_n8        .equ	4		; Z180 on N8
hd_mm_z280      .equ	5		; Z280 native