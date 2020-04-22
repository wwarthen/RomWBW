;======================================================================
;	SN76489 sound driver
;
;	WRITTEN BY: DEAN NETHERTON
;======================================================================
;
; TODO:
;
;======================================================================
; CONSTANTS
;======================================================================
;

SN76489_PORT_LEFT 	.EQU	$FC	; PORTS FOR ACCESSING THE SN76489 CHIP (LEFT)
SN76489_PORT_RIGHT 	.EQU	$F8	; PORTS FOR ACCESSING THE SN76489 CHIP (LEFT)
SN7_IDAT                .EQU    0
SN7_TONECNT		.EQU	3	; COUNT NUMBER OF TONE CHANNELS
SN7_NOISECNT		.EQU	1	; COUNT NUMBER OF NOISE CHANNELS
SN7_CHCNT		.EQU	SN7_TONECNT + SN7_NOISECNT
CHANNEL_0_SILENT	.EQU	$9F
CHANNEL_1_SILENT	.EQU	$BF
CHANNEL_2_SILENT	.EQU	$DF
CHANNEL_3_SILENT	.EQU	$FF

SN7CLKDIVIDER	.EQU	4
SN7CLK		.EQU    CPUOSC / SN7CLKDIVIDER
SN7RATIO	.EQU	SN7CLK * 100 / 32


SN7_FIRST_NOTE	.EQU	5827		; A1#
SN7_LAST_NODE	.EQU	209300		; C7

A1S		.equ	SN7RATIO / SN7_FIRST_NOTE
C7		.EQU	SN7RATIO / SN7_LAST_NODE

       .echo "SN76489: range of A1# (pitch: "
       .echo A1S
       .echo ") to C7 (pitch: "
       .echo C7
       .echo ")\n"

#include "audio.inc"

SN76489_INIT:
	LD	IY, SN7_IDAT		; POINTER TO INSTANCE DATA

        LD	DE,STR_MESSAGELT
	CALL	WRITESTR
	LD	A, SN76489_PORT_LEFT
	CALL	PRTHEXBYTE

        LD	DE,STR_MESSAGERT
	CALL	WRITESTR
	LD	A, SN76489_PORT_RIGHT
	CALL	PRTHEXBYTE
;
SN7_INIT1:
	LD	BC, SN7_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE, SN7_IDAT		; DE := SN7 INSTANCE DATA PTR
	CALL	SND_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED

	CALL	SN7_VOLUME_OFF
	XOR	A			; SIGNAL SUCCESS
	RET

;======================================================================
; SN76489 DRIVER - SOUND ADAPTER (SND) FUNCTIONS
;======================================================================
;

SN7_RESET:
	AUDTRACE(TRACE_INIT)
	CALL	SN7_VOLUME_OFF
	XOR	A			; SIGNAL SUCCESS
	RET

SN7_VOLUME_OFF:
	AUDTRACE(TRACE_VOLUME_OFF)

	LD	A, CHANNEL_0_SILENT
	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	LD	A, CHANNEL_1_SILENT
	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	LD	A, CHANNEL_2_SILENT
	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	LD	A, CHANNEL_3_SILENT
	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	RET

; BITS MAPING
; SET TONE:
; 1 CC 0 PPPP (LOW)
; 0 0 PPPPPP (HIGH)

; 1 CC 1 VVVV

SN7_VOLUME:
	AUDDEBUG("SN7VOL ")
	AUDTRACE_L
	AUDDEBUG("\r\n")
	LD	A, L
	LD	(PENDING_VOLUME), A

	XOR	A			; SIGNAL SUCCESS
	RET



SN7_NOTE:
	AUDDEBUG("SN7NOT ")
	AUDTRACE_L
	AUDDEBUG("\r\n")

	ADD	HL, HL			; SHIFT RIGHT (MULT 2) -INDEX INTO SN7NOTETBL TABLE OF WORDS
					; TEST IF HL IS LARGER THAN SN7NOTETBL SIZE
 	OR	A      			; CLEAR CARRY FLAG
	LD	DE, SIZ_SN7NOTETBL
  	SBC	HL, DE
  	JR	NC, SN7_NOTE1   	; INCOMING HL DOES NOT MAP INTO SN7NOTETBL

	ADD	HL, DE			; RESTORE HL
	LD	E, L			; HL = SN7NOTETBL + HL
	LD	D, H
	LD	HL, SN7NOTETBL
	ADD	HL, DE

	LD	A, (HL)			; RETRIEVE PITCH COUNT FROM SN7NOTETBL
	INC	HL
	LD	H, (HL)
	LD	L, A

	JR	SN7_PITCH		; APPLY PITCH

SN7_NOTE1:
	OR	$FF			; not implemented yet
	RET

SN7_PITCH:
	AUDDEBUG("SN7PIT ")
	AUDTRACE_HL
	AUDDEBUG("\r\n")
	LD	(PENDING_PITCH), HL

	XOR	A			; SIGNAL SUCCESS
	RET

SN7_PLAY:
	AUDDEBUG("SN7PLY ")
	AUDTRACE_D
	AUDDEBUG("\r\n")

	CALL	SN7_APPLY_VOL
	CALL	SN7_APPLY_PIT

	XOR	A			; SIGNAL SUCCESS
	RET

SN7_QUERY:
	LD	A, E
	CP	SND_CHCNT
	JR	Z, SN7_QUERY_CHCNT

	CP	SND_SPITCH
	JR	Z, SN7_QUERY_PITCH

	CP	SND_SVOLUME
	JR	Z, SN7_QUERY_VOLUME

	OR	$FF			; SIGNAL FAILURE
	RET

SN7_QUERY_CHCNT:
	LD	B, SN7_TONECNT
	LD	C, SN7_NOISECNT
	XOR	A
	RET

SN7_QUERY_PITCH:
	LD	HL, (PENDING_PITCH)

	XOR	A
	RET

SN7_QUERY_VOLUME:
	LD	A, (PENDING_VOLUME)
	LD	L, A
	LD	H, 0

	XOR	A
	RET

;
;	UTIL FUNCTIONS
;

SN7_APPLY_VOL:				; APPLY VOLUME TO BOTH LEFT AND RIGHT CHANNELS
	PUSH	BC			; D CONTAINS THE CHANNEL NUMBER
	PUSH	AF
	LD	A, D
	AND	$3
	RLCA
	RLCA
	RLCA
	RLCA
	RLCA
	OR	$90
	LD	B, A

	LD	A, (PENDING_VOLUME)
	RRCA
	RRCA
	RRCA
	RRCA

	AND	$0F
	LD	C, A
	LD	A, $0F
	SUB	C
	AND	$0F
	OR	B			; A CONTAINS COMMAND TO SET VOLUME FOR CHANNEL

	AUDTRACE(TRACE_PORT_WR)
	AUDTRACE_A
	AUDTRACE(TRACE_NEWLINE)

	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	POP	AF
	POP	BC
	RET

SN7_APPLY_PIT:
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	HL, (PENDING_PITCH)

	LD	A, D
	AND	$3
	RLCA
	RLCA
	RLCA
	RLCA
	RLCA
	OR	$80
	LD	B, A			; PITCH COMMAND 1 - CONTAINS CHANNEL ONLY

	LD	A, L			; GET LOWER 4 BITS FOR COMMAND 1
	AND	$F
	OR	B			; A NOW CONATINS FIRST PITCH COMMAND

	AUDTRACE(TRACE_PORT_WR)
	AUDTRACE_A
	AUDTRACE(TRACE_NEWLINE)

	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	LD	A, L			; RIGHT SHIFT OUT THE LOWER 4 BITS
	RRCA
	RRCA
	RRCA
	RRCA
	AND	$F
	LD	B, A

	LD	A, H
	AND	$3
	RLCA
	RLCA
	RLCA
	RLCA				; AND PLACE IN BITS 5 AND 6
	OR	B			; OR THE TWO SETS OF BITS TO MAKE 2ND PITCH COMMAND

	AUDTRACE(TRACE_PORT_WR)
	AUDTRACE_A
	AUDTRACE(TRACE_NEWLINE)

	OUT	(SN76489_PORT_LEFT), A
	OUT	(SN76489_PORT_RIGHT), A

	POP	AF
	POP	BC
	POP	DE
	RET


SN7_FNTBL:
	.DW	SN7_RESET
	.DW	SN7_VOLUME
	.DW	SN7_PITCH
	.DW	SN7_NOTE
	.DW	SN7_PLAY
	.DW	SN7_QUERY

#IF (($ - SN7_FNTBL) != (SND_FNCNT * 2))
	.ECHO	"*** INVALID SND FUNCTION TABLE ***\n"
	FAIL
#ENDIF

PENDING_PITCH
	.DW	0		; PENDING PITCH (10 BITS)
PENDING_VOLUME
	.DB	0		; PENDING VOL (8 BITS -> downoverted to 4 BITS and inverted)

STR_MESSAGELT	.DB	"\r\nSN76489: LEFT IO=0x$"
STR_MESSAGERT	.DB	", RIGHT IO=0x$"

#IF AUDIOTRACE
TRACE_INIT		.DB	"\r\nSN7_INIT CALLED\r\n$"
TRACE_VOLUME_OFF	.DB	"\r\nSN7_VOLUME_OFF\r\n$"
TRACE_VOLUME_SET	.DB	"\r\nSN7_VOLUME_SET CH: $"
TRACE_PLAY		.DB	"\r\nPLAY\r\n$"
TRACE_VOLUME		.DB	", VOL: $"
TRACE_PORT_WR		.DB	"\r\nOUT SN76489, $"
TRACE_PITCH_SET		.DB	"\r\nSN7_PITCH_SET CH: $"
TRACE_PITCH		.DB	", PITCH: $"
TRACE_NEWLINE		.DB 	"\r\n$"
#ENDIF

; THE FREQUENCY BY QUATER TONE STARTING AT A1#
SN7NOTETBL:
       .dw     A1S
       .dw     SN7RATIO / 5912
       .dw     SN7RATIO / 5998
       .dw     SN7RATIO / 6085
       .dw     SN7RATIO / 6174
       .dw     SN7RATIO / 6264
       .dw     SN7RATIO / 6355
       .dw     SN7RATIO / 6447
       .dw     SN7RATIO / 6541
       .dw     SN7RATIO / 6636
       .dw     SN7RATIO / 6733
       .dw     SN7RATIO / 6831
       .dw     SN7RATIO / 6930
       .dw     SN7RATIO / 7031
       .dw     SN7RATIO / 7133
       .dw     SN7RATIO / 7237
       .dw     SN7RATIO / 7342
       .dw     SN7RATIO / 7449
       .dw     SN7RATIO / 7557
       .dw     SN7RATIO / 7667
       .dw     SN7RATIO / 7778
       .dw     SN7RATIO / 7891
       .dw     SN7RATIO / 8006
       .dw     SN7RATIO / 8122
       .dw     SN7RATIO / 8241
       .dw     SN7RATIO / 8361
       .dw     SN7RATIO / 8482
       .dw     SN7RATIO / 8606
       .dw     SN7RATIO / 8731
       .dw     SN7RATIO / 8858
       .dw     SN7RATIO / 8987
       .dw     SN7RATIO / 9118
       .dw     SN7RATIO / 9250
       .dw     SN7RATIO / 9385
       .dw     SN7RATIO / 9521
       .dw     SN7RATIO / 9660
       .dw     SN7RATIO / 9800
       .dw     SN7RATIO / 9943
       .dw     SN7RATIO / 10087
       .dw     SN7RATIO / 10234
       .dw     SN7RATIO / 10383
       .dw     SN7RATIO / 10534
       .dw     SN7RATIO / 10687
       .dw     SN7RATIO / 10843
       .dw     SN7RATIO / 11000
       .dw     SN7RATIO / 11160
       .dw     SN7RATIO / 11322
       .dw     SN7RATIO / 11487
       .dw     SN7RATIO / 11654
       .dw     SN7RATIO / 11824
       .dw     SN7RATIO / 11995
       .dw     SN7RATIO / 12170
       .dw     SN7RATIO / 12347
       .dw     SN7RATIO / 12527
       .dw     SN7RATIO / 12709
       .dw     SN7RATIO / 12894
       .dw     SN7RATIO / 13081
       .dw     SN7RATIO / 13271
       .dw     SN7RATIO / 13464
       .dw     SN7RATIO / 13660
       .dw     SN7RATIO / 13859
       .dw     SN7RATIO / 14061
       .dw     SN7RATIO / 14265
       .dw     SN7RATIO / 14473
       .dw     SN7RATIO / 14683
       .dw     SN7RATIO / 14897
       .dw     SN7RATIO / 15113
       .dw     SN7RATIO / 15333
       .dw     SN7RATIO / 15556
       .dw     SN7RATIO / 15782
       .dw     SN7RATIO / 16012
       .dw     SN7RATIO / 16245
       .dw     SN7RATIO / 16481
       .dw     SN7RATIO / 16721
       .dw     SN7RATIO / 16964
       .dw     SN7RATIO / 17211
       .dw     SN7RATIO / 17461
       .dw     SN7RATIO / 17715
       .dw     SN7RATIO / 17973
       .dw     SN7RATIO / 18234
       .dw     SN7RATIO / 18500
       .dw     SN7RATIO / 18769
       .dw     SN7RATIO / 19042
       .dw     SN7RATIO / 19319
       .dw     SN7RATIO / 19600
       .dw     SN7RATIO / 19885
       .dw     SN7RATIO / 20174
       .dw     SN7RATIO / 20468
       .dw     SN7RATIO / 20765
       .dw     SN7RATIO / 21067
       .dw     SN7RATIO / 21373
       .dw     SN7RATIO / 21684
       .dw     SN7RATIO / 22000
       .dw     SN7RATIO / 22320
       .dw     SN7RATIO / 22645
       .dw     SN7RATIO / 22974
       .dw     SN7RATIO / 23308
       .dw     SN7RATIO / 23647
       .dw     SN7RATIO / 23991
       .dw     SN7RATIO / 24340
       .dw     SN7RATIO / 24694
       .dw     SN7RATIO / 25053
       .dw     SN7RATIO / 25418
       .dw     SN7RATIO / 25787
       .dw     SN7RATIO / 26163
       .dw     SN7RATIO / 26544
       .dw     SN7RATIO / 26930
       .dw     SN7RATIO / 27321
       .dw     SN7RATIO / 27718
       .dw     SN7RATIO / 28121
       .dw     SN7RATIO / 28530
       .dw     SN7RATIO / 28945
       .dw     SN7RATIO / 29366
       .dw     SN7RATIO / 29793
       .dw     SN7RATIO / 30226
       .dw     SN7RATIO / 30666
       .dw     SN7RATIO / 31113
       .dw     SN7RATIO / 31566
       .dw     SN7RATIO / 32025
       .dw     SN7RATIO / 32490
       .dw     SN7RATIO / 32963
       .dw     SN7RATIO / 33442
       .dw     SN7RATIO / 33929
       .dw     SN7RATIO / 34422
       .dw     SN7RATIO / 34923
       .dw     SN7RATIO / 35431
       .dw     SN7RATIO / 35946
       .dw     SN7RATIO / 36469
       .dw     SN7RATIO / 36999
       .dw     SN7RATIO / 37537
       .dw     SN7RATIO / 38083
       .dw     SN7RATIO / 38637
       .dw     SN7RATIO / 39200
       .dw     SN7RATIO / 39770
       .dw     SN7RATIO / 40349
       .dw     SN7RATIO / 40936
       .dw     SN7RATIO / 41530
       .dw     SN7RATIO / 42134
       .dw     SN7RATIO / 42747
       .dw     SN7RATIO / 43369
       .dw     SN7RATIO / 44000
       .dw     SN7RATIO / 44640
       .dw     SN7RATIO / 45289
       .dw     SN7RATIO / 45948
       .dw     SN7RATIO / 46616
       .dw     SN7RATIO / 47294
       .dw     SN7RATIO / 47982
       .dw     SN7RATIO / 48680
       .dw     SN7RATIO / 49388
       .dw     SN7RATIO / 50106
       .dw     SN7RATIO / 50835
       .dw     SN7RATIO / 51575
       .dw     SN7RATIO / 52325
       .dw     SN7RATIO / 53086
       .dw     SN7RATIO / 53858
       .dw     SN7RATIO / 54642
       .dw     SN7RATIO / 55437
       .dw     SN7RATIO / 56243
       .dw     SN7RATIO / 57061
       .dw     SN7RATIO / 57891
       .dw     SN7RATIO / 58733
       .dw     SN7RATIO / 59587
       .dw     SN7RATIO / 60454
       .dw     SN7RATIO / 61333
       .dw     SN7RATIO / 62225
       .dw     SN7RATIO / 63130
       .dw     SN7RATIO / 64048
       .dw     SN7RATIO / 64980
       .dw     SN7RATIO / 65925
       .dw     SN7RATIO / 66884
       .dw     SN7RATIO / 67857
       .dw     SN7RATIO / 68844
       .dw     SN7RATIO / 69846
       .dw     SN7RATIO / 70862
       .dw     SN7RATIO / 71893
       .dw     SN7RATIO / 72938
       .dw     SN7RATIO / 73999
       .dw     SN7RATIO / 75075
       .dw     SN7RATIO / 76167
       .dw     SN7RATIO / 77275
       .dw     SN7RATIO / 78399
       .dw     SN7RATIO / 79539
       .dw     SN7RATIO / 80696
       .dw     SN7RATIO / 81870
       .dw     SN7RATIO / 83061
       .dw     SN7RATIO / 84269
       .dw     SN7RATIO / 85495
       .dw     SN7RATIO / 86738
       .dw     SN7RATIO / 88000
       .dw     SN7RATIO / 89280
       .dw     SN7RATIO / 90579
       .dw     SN7RATIO / 91896
       .dw     SN7RATIO / 93233
       .dw     SN7RATIO / 94589
       .dw     SN7RATIO / 95965
       .dw     SN7RATIO / 97361
       .dw     SN7RATIO / 98777
       .dw     SN7RATIO / 100214
       .dw     SN7RATIO / 101671
       .dw     SN7RATIO / 103150
       .dw     SN7RATIO / 104650
       .dw     SN7RATIO / 106172
       .dw     SN7RATIO / 107716
       .dw     SN7RATIO / 109283
       .dw     SN7RATIO / 110873
       .dw     SN7RATIO / 112486
       .dw     SN7RATIO / 114122
       .dw     SN7RATIO / 115782
       .dw     SN7RATIO / 117466
       .dw     SN7RATIO / 119175
       .dw     SN7RATIO / 120908
       .dw     SN7RATIO / 122667
       .dw     SN7RATIO / 124451
       .dw     SN7RATIO / 126261
       .dw     SN7RATIO / 128098
       .dw     SN7RATIO / 129961
       .dw     SN7RATIO / 131851
       .dw     SN7RATIO / 133769
       .dw     SN7RATIO / 135715
       .dw     SN7RATIO / 137689
       .dw     SN7RATIO / 139691
       .dw     SN7RATIO / 141723
       .dw     SN7RATIO / 143784
       .dw     SN7RATIO / 145876
       .dw     SN7RATIO / 147998
       .dw     SN7RATIO / 150151
       .dw     SN7RATIO / 152335
       .dw     SN7RATIO / 154550
       .dw     SN7RATIO / 156798
       .dw     SN7RATIO / 159079
       .dw     SN7RATIO / 161393
       .dw     SN7RATIO / 163740
       .dw     SN7RATIO / 166122
       .dw     SN7RATIO / 168538
       .dw     SN7RATIO / 170990
       .dw     SN7RATIO / 173477
       .dw     SN7RATIO / 176000
       .dw     SN7RATIO / 178560
       .dw     SN7RATIO / 181157
       .dw     SN7RATIO / 183792
       .dw     SN7RATIO / 186466
       .dw     SN7RATIO / 189178
       .dw     SN7RATIO / 191930
       .dw     SN7RATIO / 194722
       .dw     SN7RATIO / 197553
       .dw     SN7RATIO / 200426
       .dw     SN7RATIO / 203342
       .dw     SN7RATIO / 206299
       .dw     C7

SIZ_SN7NOTETBL	.EQU	$ - SN7NOTETBL
		.ECHO	"SN76489 approx "
		.ECHO	SIZ_SN7NOTETBL / 2 / 4 /12
		.ECHO	" Octaves.  Last note index supported: "

		.echo SIZ_SN7NOTETBL / 2
		.echo "\n"
