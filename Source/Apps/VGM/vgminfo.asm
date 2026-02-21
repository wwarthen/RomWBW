;------------------------------------------------------------------------------
; VGM File Info Display for CP/M
;------------------------------------------------------------------------------
;
; Scans all .VGM files in current directory and displays chip information
; in a formatted table
;
; (c)2026 Joao Miguel Duraes
; Licensed under the MIT License
;
; Version: 1.2 - 20-Feb-2026
;
; Assemble with:
;   TASM -80 -b vgminfo.asm vgminfo.com
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; CP/M definitions
;------------------------------------------------------------------------------

BOOT            .equ    0000H               ; boot location
BDOS            .equ    0005H               ; bdos entry point
FCB             .equ    005CH               ; file control block
FCBCR           .equ    FCB + 20H           ; fcb current record
BUFF            .equ    0080H               ; DMA buffer

PRINTF          .equ    9                   ; BDOS print string function
OPENF           .equ    15                  ; BDOS open file function
CLOSEF          .equ    16                  ; BDOS close file function
READF           .equ    20                  ; BDOS sequential read function
RREAD           .equ    33                  ; BDOS random read function
SETDMA          .equ    26                  ; BDOS set DMA address
SFIRST          .equ    17                  ; BDOS search first
SNEXT           .equ    18                  ; BDOS search next

CR              .equ    0DH                 ; carriage return
LF              .equ    0AH                 ; line feed

;------------------------------------------------------------------------------
; VGM Header offsets
;------------------------------------------------------------------------------

DEBUG_SUM       .equ    1                   ; 1 = build with checksum support

; Increment BUILD_NUM on every source change so we can confirm which binary is running.
BUILD_NUM       .equ    0022H               ; debug build number (hex)

; Run modes
MODE_SIMPLE     .equ    0                   ; v1.1-style table output
MODE_VERBOSE    .equ    1                   ; long output
MODE_DEBUG      .equ    2                   ; long output + debug instrumentation

; Number of spaces to indent detail lines (used for technical and GD3 lines)
DETAIL_INDENT    .equ    1

VGM_IDENT        .equ    00H                 ; "Vgm " identifier
VGM_EOFREL       .equ    04H                 ; EOF offset (relative to 0x04)
VGM_VERSION      .equ    08H                 ; Version
VGM_SN76489_CLK  .equ    0CH                 ; SN76489 clock (4 bytes, little-endian)
VGM_GD3REL       .equ    14H                 ; GD3 offset (relative to 0x14)
VGM_TOTALSMP     .equ    18H                 ; Total samples
VGM_LOOPREL      .equ    1CH                 ; Loop offset (relative to 0x1C)
VGM_LOOPSMP      .equ    20H                 ; Loop samples
VGM_RATE         .equ    24H                 ; Rate
VGM_YM2612_CLK  .equ    2CH                 ; YM2612 clock (4 bytes, little-endian)
VGM_YM2151_CLK  .equ    30H                 ; YM2151 clock (4 bytes, little-endian)
VGM_DATAOFF     .equ    34H                 ; VGM data offset (relative to 0x34)
VGM_YM3812_CLK  .equ    50H                 ; YM3812 clock (OPL2)
VGM_YMF262_CLK  .equ    5CH                 ; YMF262 clock (OPL3)
VGM_AY8910_CLK  .equ    74H                 ; AY-3-8910 clock (4 bytes, little-endian)

;------------------------------------------------------------------------------
; VGM Command codes (subset)
;------------------------------------------------------------------------------

VGM_PSG1_W      .equ    050H                ; PSG (SN76489) write
VGM_PSG2_W      .equ    030H                ; PSG #2 write
VGM_YM26121_W   .equ    052H                ; YM2612 port 0 write
VGM_YM26122_W   .equ    053H                ; YM2612 port 1 write
VGM_YM26123_W   .equ    0A2H                ; YM2612 #2 port 0 write
VGM_YM26124_W   .equ    0A3H                ; YM2612 #2 port 1 write
VGM_YM21511_W   .equ    054H                ; YM2151 write
VGM_YM21512_W   .equ    0A4H                ; YM2151 #2 write
VGM_OPL2_W      .equ    05AH                ; YM3812 (OPL2) write
VGM_OPL31_W     .equ    05EH                ; YMF262 (OPL3) port 0 write
VGM_OPL32_W     .equ    05FH                ; YMF262 (OPL3) port 1 write
VGM_AY_W        .equ    0A0H                ; AY-3-8910 write
VGM_ESD         .equ    066H                ; End of sound data
VGM_WNS         .equ    061H                ; Wait n samples
VGM_W735        .equ    062H                ; Wait 735 samples
VGM_W882        .equ    063H                ; Wait 882 samples

;------------------------------------------------------------------------------
; Program Start
;------------------------------------------------------------------------------

                .ORG    100H

START:          LD      SP, STACK           ; Setup stack
                
                ; Parse command tail for -v (verbose), -d (debug), -h (help), and optional filename
                CALL    PARSE_ARGS

                ; Help mode: print usage and exit
                LD      A, (HELP_FLAG)
                OR      A
                JR      Z, NOT_HELP
                LD      DE, MSG_HELP
                CALL    PRTSTR
                JP      BOOT
NOT_HELP:

                ; Display header (simple vs verbose)
                LD      A, (RUN_MODE)
                CP      MODE_SIMPLE
                JR      NZ, HDR_VERBOSE

                LD      DE, MSG_S_HEADER1
                CALL    PRTSTR
                CALL    PRINT_BUILD
                LD      DE, MSG_S_HEADER2
                CALL    PRTSTR
                LD      DE, MSG_S_DIVIDER
                CALL    PRTSTR
                JR      HDR_DONE

HDR_VERBOSE:
                LD      DE, MSG_HEADER1
                CALL    PRTSTR
                CALL    PRINT_BUILD
                LD      DE, MSG_HEADER2
                CALL    PRTSTR

HDR_DONE:
                ; Ensure DMA points to BUFF for directory searches
                LD      DE, BUFF
                LD      C, SETDMA
                CALL    BDOS

                ; Init runtime debug counters
                XOR     A
                LD      (DBG_PROC), A
                LD      (DBG_OPENFAIL), A
                LD      (DBG_BADSIG), A
                LD      (DBG_DUP), A
                LD      (DBG_HAVE_PREV), A
                LD      (DBG_COLLECT_EARLY), A

                ; Single-file mode?
                LD      A, (HAS_TARGET)
                OR      A
                JR      Z, DO_DIRECTORY

                ; Build FILE_FCB name from TARGETNAME and assume .VGM
                LD      HL, TARGETNAME
                LD      DE, FILE_FCB+1
                LD      BC, 8
                LDIR
                LD      HL, TARGETEXT
                LD      DE, FILE_FCB+9
                LD      BC, 3
                LDIR

                ; Debug: show which file we're about to process
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JR      NZ, SF_NODEBUG
                LD      DE, MSG_DBG_PROC
                CALL    PRTSTR
                CALL    PRINT_FNAME_BASE
                CALL    CRLF
SF_NODEBUG:

                CALL    PROCESS_FILE

                ; Simple mode footer divider
                LD      A, (RUN_MODE)
                CP      MODE_SIMPLE
                JR      NZ, SF_DONE
                LD      DE, MSG_S_DIVIDER
                CALL    PRTSTR
SF_DONE:        JP      BOOT

DO_DIRECTORY:
                ; Debug: count how many .VGM files BDOS reports
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JR      NZ, SKIP_DBG_COUNT

                CALL    COUNT_VGMS
                LD      A, (DBG_TOTAL)
                LD      (DBG_EXPECT), A
                LD      DE, MSG_DBG_COUNT
                CALL    PRTSTR
                LD      A, (DBG_EXPECT)
                CALL    PRTDEC8
                CALL    CRLF

SKIP_DBG_COUNT:
                ; Collect a stable list of file names (no file I/O during search)
                CALL    COLLECT_VGMS

                ; Process collected files
                LD      A, (FILECOUNT)
                OR      A
                JP      Z, NO_FILES

                LD      B, A
                LD      HL, FILELIST

PROC_LOOP:
                ; copy 11 bytes into FILE_FCB+1
                PUSH    BC
                LD      DE, FILE_FCB+1
                LD      BC, 11
                LDIR
                POP     BC

                ; Preserve loop counter (B) and HL (FILELIST pointer) across PROCESS_FILE
                PUSH    BC
                PUSH    HL

                ; Debug: show which file we're about to process
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JR      NZ, PROC_NODEBUG
                LD      DE, MSG_DBG_PROC
                CALL    PRTSTR
                CALL    PRINT_FNAME_BASE
                CALL    CRLF
PROC_NODEBUG:

                CALL    PROCESS_FILE

                POP     HL
                POP     BC

                OR      A
                JR      Z, PROC_NEXT
                LD      A, (DBG_PROC)
                INC     A
                LD      (DBG_PROC), A
PROC_NEXT:
                DJNZ    PROC_LOOP

                ; Simple mode footer divider
                LD      A, (RUN_MODE)
                CP      MODE_SIMPLE
                JR      NZ, MAYBE_DBG_REPORT
                LD      DE, MSG_S_DIVIDER
                CALL    PRTSTR
                JP      BOOT

MAYBE_DBG_REPORT:
                ; Debug mismatch report
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JR      NZ, DBG_DONE

                LD      A, (DBG_PROC)
                LD      B, A
                LD      A, (DBG_EXPECT)
                CP      B
                JR      Z, DBG_DONE

                LD      DE, MSG_DBG_MISMATCH
                CALL    PRTSTR

                LD      DE, MSG_DBG_EXP
                CALL    PRTSTR
                LD      A, (DBG_EXPECT)
                CALL    PRTDEC8

                LD      DE, MSG_DBG_GOT
                CALL    PRTSTR
                LD      A, (DBG_PROC)
                CALL    PRTDEC8
                CALL    CRLF

                LD      DE, MSG_DBG_OPENF
                CALL    PRTSTR
                LD      A, (DBG_OPENFAIL)
                CALL    PRTDEC8

                LD      DE, MSG_DBG_BAD
                CALL    PRTSTR
                LD      A, (DBG_BADSIG)
                CALL    PRTDEC8

                LD      DE, MSG_DBG_DUP
                CALL    PRTSTR
                LD      A, (DBG_DUP)
                CALL    PRTDEC8

                LD      DE, MSG_DBG_COL
                CALL    PRTSTR
                LD      A, (DBG_COLLECT_EARLY)
                CALL    PRTDEC8

                CALL    CRLF

DBG_DONE:
                JP      BOOT                ; Exit to CP/M

NO_FILES:       LD      DE, MSG_NOFILES
                CALL    PRTSTR
                JP      BOOT

;------------------------------------------------------------------------------
; Process a VGM file - read header and display info
;------------------------------------------------------------------------------

PROCESS_FILE:   
                ; Reset per-file printed flag
                XOR     A
                LD      (PROC_PRINTED), A

                ; Reset FCB
                XOR     A
                LD      (FILE_FCB), A       ; Default drive
                LD      (FILE_FCB+12), A    ; Clear extent
                LD      (FILE_FCB+32), A    ; Clear current record
                
                ; Open file
                LD      DE, FILE_FCB
                LD      C, OPENF
                CALL    BDOS
                CP      0FFH
                JR      NZ, PF_OPENOK
                LD      A, (DBG_OPENFAIL)
                INC     A
                LD      (DBG_OPENFAIL), A
                XOR     A
                RET                         ; Can't open, skip
PF_OPENOK:
                
                ; Set DMA to our buffer for first block
                LD      DE, VGMBUF
                LD      C, SETDMA
                CALL    BDOS
                
                ; Read first 128 bytes (header)
                LD      DE, FILE_FCB
                LD      C, READF
                CALL    BDOS
                OR      A
                JR      NZ, READ_DONE       ; EOF or error
                
                ; Read second 128 bytes (to allow scanning right after header)
                LD      DE, VGMBUF+128
                LD      C, SETDMA
                CALL    BDOS
                LD      DE, FILE_FCB
                LD      C, READF
                CALL    BDOS
                
                ; Read third 128 bytes
                LD      DE, VGMBUF+256
                LD      C, SETDMA
                CALL    BDOS
                LD      DE, FILE_FCB
                LD      C, READF
                CALL    BDOS
                
                ; Read fourth 128 bytes
                LD      DE, VGMBUF+384
                LD      C, SETDMA
                CALL    BDOS
                LD      DE, FILE_FCB
                LD      C, READF
                CALL    BDOS
                
READ_DONE:
                
                ; Restore DMA
                LD      DE, BUFF
                LD      C, SETDMA
                CALL    BDOS
                
                ; Check if valid VGM
                LD      HL, VGMBUF
                LD      A, (HL)
                CP      'V'
                JR      NZ, PF_BADSIG
                INC     HL
                LD      A, (HL)
                CP      'g'
                JR      NZ, PF_BADSIG
                INC     HL
                LD      A, (HL)
                CP      'm'
                JR      NZ, PF_BADSIG
                INC     HL
                LD      A, (HL)
                CP      ' '
                JR      NZ, PF_BADSIG
                JR      PF_SIGOK
PF_BADSIG:
                LD      A, (DBG_BADSIG)
                INC     A
                LD      (DBG_BADSIG), A
                JR      PROC_CLOSE
PF_SIGOK:
                
                ; Mark as printed
                LD      A, 1
                LD      (PROC_PRINTED), A

                ; Output depends on run mode
                LD      A, (RUN_MODE)
                CP      MODE_SIMPLE
                JR      Z, PF_SIMPLE

                ; Verbose/debug: Display per-file summary line + details
                CALL    PRINT_FILE_LINE

                ; Print extended technical + GD3 details
                CALL    PRINT_DETAILS

                ; Blank line between files
                CALL    CRLF
                JR      PF_OUTDONE

PF_SIMPLE:
                CALL    PRINT_SIMPLE_LINE

PF_OUTDONE:
                
                ; Close file
PROC_CLOSE:     LD      DE, FILE_FCB
                LD      C, CLOSEF
                CALL    BDOS
                ; Return A=1 if we printed this file, else A=0
                LD      A, (PROC_PRINTED)
                RET

;------------------------------------------------------------------------------
; Check which chips are used: hybrid approach
; 1. Check header clocks to see which chip types are present
; 2. Scan commands to detect multiple instances of same chip type
;------------------------------------------------------------------------------

CHECK_CHIPS:
                ; Detect chips actually used by scanning the VGM command stream.
                ; (We do not pre-mark chips based on header clocks, since clocks may be 0
                ;  even when commands exist, and vice-versa.)
                XOR     A
                LD      (CHIP_FLAGS), A
                LD      (CHIP_TYPES), A          ; used for OPL2/OPL3 display bits

COMPUTE_DATA_START:
                LD      HL, (VGMBUF+VGM_DATAOFF)
                LD      A, H
                OR      L
                JR      NZ, GOT_OFFSET
                LD      HL, 000CH                ; Default for VGM < 1.50 (0x40-0x34)
GOT_OFFSET:     LD      DE, VGMBUF+VGM_DATAOFF    ; VGMBUF + 0x34
                ADD     HL, DE                   ; HL = VGMBUF + 0x34 + offset

                ; Scan up to 255 commands or until EOD
                LD      C, 255
SCAN_LOOP:
                ; Stop if we run past our 512-byte local buffer to avoid false positives
                LD      DE, VGMBUF+512
                OR      A
                SBC     HL, DE
                JR      C, SCAN_INRANGE
                JP      SCAN_DONE
SCAN_INRANGE:   ADD     HL, DE

                LD      A, (HL)
                INC     HL
                
                CP      VGM_ESD
                JP      Z, SCAN_DONE
                
                CP      VGM_PSG1_W
                JP      NZ, CHK_PSG2
                LD      A, (CHIP_FLAGS)
                OR      01H                 ; bit 0 = SN #1
                LD      (CHIP_FLAGS), A
                INC     HL                  ; Skip data byte
                JP      SCAN_NEXT
                
CHK_PSG2:       CP      VGM_PSG2_W
                JP      NZ, CHK_YM2612
                LD      A, (CHIP_FLAGS)
                OR      02H                 ; bit 1 = SN #2
                LD      (CHIP_FLAGS), A
                INC     HL
                JP      SCAN_NEXT
                
CHK_YM2612:     CP      VGM_YM26121_W
                JR      Z, GOT_YM2612_1
                CP      VGM_YM26122_W
                JR      Z, GOT_YM2612_1
                CP      VGM_YM26123_W
                JR      Z, GOT_YM2612_2
                CP      VGM_YM26124_W
                JP      NZ, CHK_YM2151
GOT_YM2612_2:   LD      A, (CHIP_FLAGS)
                OR      08H                 ; bit 3 = YM2612 #2
                LD      (CHIP_FLAGS), A
                INC     HL
                INC     HL                  ; Skip 2 data bytes
                JP      SCAN_NEXT
GOT_YM2612_1:   LD      A, (CHIP_FLAGS)
                OR      04H                 ; bit 2 = YM2612 #1
                LD      (CHIP_FLAGS), A
                INC     HL
                INC     HL
                JP      SCAN_NEXT
                
CHK_YM2151:     CP      VGM_YM21511_W
                JR      Z, GOT_YM2151_1
                CP      VGM_YM21512_W
                JP      NZ, CHK_AY
                LD      A, (CHIP_FLAGS)
                OR      20H                 ; bit 5 = YM2151 #2
                LD      (CHIP_FLAGS), A
                INC     HL
                INC     HL
                JP      SCAN_NEXT
GOT_YM2151_1:   LD      A, (CHIP_FLAGS)
                OR      10H                 ; bit 4 = YM2151 #1
                LD      (CHIP_FLAGS), A
                INC     HL
                INC     HL
                JP      SCAN_NEXT
                
CHK_AY:         CP      VGM_AY_W
                JP      NZ, CHK_OPL2
                LD      A, (HL)             ; register/chip byte
                BIT     7, A                ; Bit 7 = chip 2?
                JR      Z, GOT_AY1
                LD      A, (CHIP_FLAGS)
                OR      80H                 ; bit 7 = AY #2
                LD      (CHIP_FLAGS), A
                JR      SCAN_SKIP_AY
GOT_AY1:        LD      A, (CHIP_FLAGS)
                OR      40H                 ; bit 6 = AY #1
                LD      (CHIP_FLAGS), A
SCAN_SKIP_AY:   INC     HL
                INC     HL                  ; Skip 2 data bytes
                JP      SCAN_NEXT
                
CHK_OPL2:       CP      VGM_OPL2_W
                JP      NZ, CHK_OPL3
                ; Mark OPL2 present
                LD      A, (CHIP_TYPES)
                OR      010H                 ; bit 4 = OPL2
                LD      (CHIP_TYPES), A
                INC     HL                   ; skip register
                INC     HL                   ; skip data
                JP      SCAN_NEXT
                
CHK_OPL3:       CP      VGM_OPL31_W
                JR      Z, GOT_OPL3
                CP      VGM_OPL32_W
                JP      NZ, CHK_WAIT
GOT_OPL3:       ; Mark OPL3 present
                LD      A, (CHIP_TYPES)
                OR      020H                 ; bit 5 = OPL3
                LD      (CHIP_TYPES), A
                INC     HL                   ; skip register
                INC     HL                   ; skip data
                JP      SCAN_NEXT
                
CHK_WAIT:       CP      VGM_WNS
                JR      NZ, CHK_W735
                INC     HL
                INC     HL                  ; Skip 2-byte wait value
                JP      SCAN_NEXT
                
CHK_W735:       CP      VGM_W735
                JR      Z, SCAN_NEXT
                CP      VGM_W882
                JR      Z, SCAN_NEXT
                
                ; Unknown command or short wait 0x70-0x7F -> just continue
                CP      70H
                JR      C, SCAN_NEXT
                CP      80H
                JR      NC, SCAN_NEXT
                
SCAN_NEXT:      DEC     C
                JP      NZ, SCAN_LOOP
                
SCAN_DONE:      ; Display chips found
                LD      B, 0                ; Chip counter
                LD      A, (CHIP_FLAGS)
                LD      C, A                ; Save flags
                
                ; SN76489
                AND     03H                 ; bits 0-1
                JP      Z, NO_SN
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      A, C
                AND     03H
                CP      03H                 ; Both chips?
                JR      Z, SN_DUAL
                LD      DE, MSG_SN76489
                CALL    PRTSTR
                JR      SN_DONE
SN_DUAL:        LD      DE, MSG_SN76489X2
                CALL    PRTSTR
SN_DONE:        INC     B
NO_SN:
                ; YM2612
                LD      A, C
                AND     0CH                 ; bits 2-3
                JR      Z, NO_YM2612
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      A, C
                AND     0CH
                CP      0CH                 ; Both chips?
                JR      Z, YM2612_DUAL
                LD      DE, MSG_YM2612
                CALL    PRTSTR
                JR      YM2612_DONE
YM2612_DUAL:    LD      DE, MSG_YM2612X2
                CALL    PRTSTR
YM2612_DONE:    INC     B
NO_YM2612:
                ; YM2151
                LD      A, C
                AND     30H                 ; bits 4-5
                JR      Z, NO_YM2151
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      A, C
                AND     30H
                CP      30H                 ; Both chips?
                JR      Z, YM2151_DUAL
                LD      DE, MSG_YM2151
                CALL    PRTSTR
                JR      YM2151_DONE
YM2151_DUAL:    LD      DE, MSG_YM2151X2
                CALL    PRTSTR
YM2151_DONE:    INC     B
NO_YM2151:
                ; OPL2 (YM3812)
                LD      A, (CHIP_TYPES)
                BIT     4, A
                JR      Z, NO_OPL2
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      DE, MSG_OPL2
                CALL    PRTSTR
                INC     B
NO_OPL2:
                ; OPL3 (YMF262)
                LD      A, (CHIP_TYPES)
                BIT     5, A
                JR      Z, NO_OPL3
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      DE, MSG_OPL3
                CALL    PRTSTR
                INC     B
NO_OPL3:
                ; AY-3-8910
                LD      A, C
                AND     0C0H                ; bits 6-7
                JR      Z, NO_AY
                LD      A, B
                OR      A
                CALL    NZ, PRINT_COMMA
                LD      A, C
                AND     0C0H
                CP      0C0H                ; Both chips?
                JR      Z, AY_DUAL
                LD      DE, MSG_AY8910
                CALL    PRTSTR
                JR      AY_DONE
AY_DUAL:        LD      DE, MSG_AY8910X2
                CALL    PRTSTR
AY_DONE:        INC     B
NO_AY:
                ; None
                LD      A, B
                OR      A
                RET     NZ
                LD      DE, MSG_UNKNOWN
                CALL    PRTSTR
                RET

PRINT_COMMA:    LD      A, ','
                CALL    PRTCHR
                LD      A, ' '
                CALL    PRTCHR
                RET

;------------------------------------------------------------------------------
; Print per-file summary + verbose fields header lines
; Filename(.VGM): NAME
;  Version: 1.xx
;  Chips Used: <list>
;------------------------------------------------------------------------------

PRINT_FILE_LINE:
                ; Summary line
                LD      DE, MSG_FILE_PREFIX
                CALL    PRTSTR
                CALL    PRINT_FNAME_BASE

#if DEBUG_SUM
                ; Debug: append 512-byte checksum to summary line
                CALL    CALC_SUM512
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JR      NZ, PFL_NOCHK

                ; Print space + [HHLL]
                LD      A, ' '
                CALL    PRTCHR
                LD      A, '['
                CALL    PRTCHR
                LD      A, (SUM_HI)
                CALL    PRTHEX8
                LD      A, (SUM_LO)
                CALL    PRTHEX8
                LD      A, ']'
                CALL    PRTCHR
PFL_NOCHK:
#endif

                CALL    CRLF

                ; Version line
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                LD      DE, MSG_VER_PREFIX
                CALL    PRTSTR
                CALL    PRINT_VERSION
                CALL    CRLF

                ; Chips line
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                LD      DE, MSG_CHIPS_PREFIX
                CALL    PRTSTR
                CALL    CHECK_CHIPS
                CALL    CRLF

                RET

;------------------------------------------------------------------------------
; v1.1-style simple line: NAME(8) + two spaces + chips
;------------------------------------------------------------------------------
PRINT_SIMPLE_LINE:
                CALL    PRINT_FNAME_PAD8
                CALL    CHECK_CHIPS
                CALL    CRLF
                RET

PRINT_FNAME_PAD8:
                LD      HL, FILE_FCB+1
                LD      B, 8
                LD      D, 0                 ; printed length
PSN_LOOP:       LD      A, (HL)
                CP      ' '
                JR      Z, PSN_PAD
                CALL    PRTCHR
                INC     D
                INC     HL
                DJNZ    PSN_LOOP
                JR      PSN_GAP
PSN_PAD:
                ; pad to 8
                LD      A, 8
                SUB     D
                JR      Z, PSN_GAP
                LD      B, A
PSN_PADLOOP:    LD      A, ' '
                CALL    PRTCHR
                DJNZ    PSN_PADLOOP
PSN_GAP:
                LD      A, ' '
                CALL    PRTCHR
                LD      A, ' '
                CALL    PRTCHR
                RET

;------------------------------------------------------------------------------
; Print filename base (trim trailing spaces from 8-char name in FILE_FCB)
;------------------------------------------------------------------------------

PRINT_FNAME_BASE:
                LD      HL, FILE_FCB+1
                LD      B, 8
                LD      C, 0                ; length (0..8)
                LD      D, 0                ; index
PFNB_SCAN:
                LD      A, (HL)
                CP      ' '
                JR      Z, PFNB_NEXT
                LD      C, D
                INC     C
PFNB_NEXT:
                INC     HL
                INC     D
                DJNZ    PFNB_SCAN

                LD      HL, FILE_FCB+1
                LD      B, C
                LD      A, B
                OR      A
                JR      NZ, PFNB_PRINT
                LD      B, 8
PFNB_PRINT:
                LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DJNZ    PFNB_PRINT
                RET

;------------------------------------------------------------------------------
; Print filename from FCB as fixed-width 8.3 (8 + '.' + 3)
;------------------------------------------------------------------------------

PRINT_FNAME83:  ; name (8)
                LD      HL, FILE_FCB+1
                LD      B, 8
PFN_LOOP:       LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DJNZ    PFN_LOOP
                LD      A, '.'
                CALL    PRTCHR
                ; ext (3)
                LD      HL, FILE_FCB+9
                LD      B, 3
PFE_LOOP:       LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DJNZ    PFE_LOOP
                RET

;------------------------------------------------------------------------------
; Print VGM version as M.mm (mm printed as hex to match common VGM notation)
;------------------------------------------------------------------------------

PRINT_VERSION:  LD      HL, VGMBUF+VGM_VERSION
                LD      A, (HL)             ; minor (e.g. 70h)
                LD      (VER_MINOR), A
                INC     HL
                LD      A, (HL)             ; major (e.g. 01h)
                CP      0AH
                JR      C, PV_DIGIT
                LD      A, '?'              ; unexpected major
                JR      PV_OUT
PV_DIGIT:       ADD     A, '0'
PV_OUT:         CALL    PRTCHR
                LD      A, '.'
                CALL    PRTCHR
                LD      A, (VER_MINOR)
                CALL    PRTHEX8
                RET

;------------------------------------------------------------------------------
; Print HL as 4 hex digits
;------------------------------------------------------------------------------

PRTHEX16:       PUSH    AF
                PUSH    HL
                LD      A, H
                CALL    PRTHEX8
                LD      A, L
                CALL    PRTHEX8
                POP     HL
                POP     AF
                RET

;------------------------------------------------------------------------------
; Print a 32-bit little-endian value at HL as 8 hex digits
;------------------------------------------------------------------------------

PRTHEX32_LE:    PUSH    HL
                LD      E, (HL)
                INC     HL
                LD      D, (HL)
                INC     HL
                LD      C, (HL)
                INC     HL
                LD      B, (HL)
                LD      A, B
                CALL    PRTHEX8
                LD      A, C
                CALL    PRTHEX8
                LD      A, D
                CALL    PRTHEX8
                LD      A, E
                CALL    PRTHEX8
                POP     HL
                RET

;------------------------------------------------------------------------------
; Print build number
;------------------------------------------------------------------------------

PRINT_BUILD:    LD      HL, BUILD_NUM
                CALL    PRTHEX16
                RET

;------------------------------------------------------------------------------
; Print B spaces
;------------------------------------------------------------------------------

PRTSPACES:      LD      A, ' '
PS_LOOP:        CALL    PRTCHR
                DJNZ    PS_LOOP
                RET

;------------------------------------------------------------------------------
; Print the extended details block (size, offsets, clocks, GD3 fields)
;------------------------------------------------------------------------------

PRINT_DETAILS:  
                ; Determine header size (stored as 16-bit) in HDR_SIZE
                ; header_size = 0x40 if dataoff==0 else (0x34 + dataoff)
                LD      HL, VGMBUF+VGM_DATAOFF
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      NZ, PD_HSZ_FROM_OFF
                LD      HL, 0040H
                JR      PD_HSZ_SET
PD_HSZ_FROM_OFF:
                LD      HL, (VGMBUF+VGM_DATAOFF)  ; low 16-bits are enough here
                LD      DE, 0034H
                ADD     HL, DE
PD_HSZ_SET:     LD      (HDR_SIZE), HL

                ; Line 1: Size/Data/GD3
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                LD      DE, MSG_L_SIZE
                CALL    PRTSTR
                CALL    GET_FILE_SIZE
                LD      HL, TMP32
                CALL    PRTHEX32_LE

                ; Also print decimal size in bytes
                LD      DE, MSG_SIZE_DEC_OPEN
                CALL    PRTSTR
                LD      HL, TMP32
                CALL    PRTDEC32_COMMA
                LD      DE, MSG_SIZE_DEC_CLOSE
                CALL    PRTSTR

                LD      DE, MSG_L_DATA
                CALL    PRTSTR
                CALL    GET_DATA_ABS
                LD      HL, DATA_ABS
                CALL    PRTHEX32_LE

                LD      DE, MSG_L_GD3
                CALL    PRTSTR
                CALL    GET_GD3_ABS
                LD      HL, GD3_ABS
                CALL    PRTHEX32_LE

                CALL    CRLF

                ; Clock lines are printed only in debug mode (-d)
                LD      A, (RUN_MODE)
                CP      MODE_DEBUG
                JP      NZ, PD_SKIP_CLOCKS

                ; Line 2: clocks (SN/YM2612/YM2151)
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                LD      DE, MSG_L_CLK1
                CALL    PRTSTR
                LD      HL, VGMBUF+VGM_SN76489_CLK
                CALL    PRTHEX32_LE
                LD      DE, MSG_L_CLK_YM2612
                CALL    PRTSTR
                LD      HL, VGMBUF+VGM_YM2612_CLK
                CALL    PRTHEX32_LE
                LD      DE, MSG_L_CLK_YM2151
                CALL    PRTSTR
                LD      HL, VGMBUF+VGM_YM2151_CLK
                CALL    PRTHEX32_LE
                CALL    CRLF

                ; Line 3: clocks (OPL2/OPL3/AY) - only if header supports it
                CALL    EXT_CLOCKS_OK
                OR      A
                JR      Z, PD_CLK_EXT_ZERO

                ; OPL2
                LD      HL, (HDR_SIZE)
                LD      DE, 0054H           ; need header_size > 0x53
                OR      A
                SBC     HL, DE
                JR      C, PD_CLK_EXT_ZERO
                LD      HL, VGMBUF+VGM_YM3812_CLK
                CALL    COPY32
                JR      PD_CLK_EXT_PRINT

PD_CLK_EXT_ZERO:
                XOR     A
                LD      (TMP32), A
                LD      (TMP32+1), A
                LD      (TMP32+2), A
                LD      (TMP32+3), A

PD_CLK_EXT_PRINT:
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                LD      DE, MSG_L_CLK2
                CALL    PRTSTR

                ; OPL2 clock in TMP32 (either real or 0)
                LD      HL, TMP32
                CALL    PRTHEX32_LE

                ; OPL3
                LD      DE, MSG_L_CLK_OPL3
                CALL    PRTSTR
                CALL    GET_OPL3_CLK
                LD      HL, TMP32
                CALL    PRTHEX32_LE

                ; AY
                LD      DE, MSG_L_CLK_AY
                CALL    PRTSTR
                CALL    GET_AY_CLK
                LD      HL, TMP32
                CALL    PRTHEX32_LE

                CALL    CRLF

PD_SKIP_CLOCKS:
                ; GD3 fields (if present)
                CALL    PRINT_GD3
                RET

;------------------------------------------------------------------------------
; Helpers for 32-bit offset computation
;------------------------------------------------------------------------------

; Copy 4 bytes from HL to TMP32
COPY32:         PUSH    DE
                LD      DE, TMP32
                LD      BC, 4
                LDIR
                POP     DE
                RET

; TMP32 = EOFREL + 4  (file size)
GET_FILE_SIZE:  LD      HL, VGMBUF+VGM_EOFREL
                CALL    COPY32
                LD      A, (TMP32)
                ADD     A, 04H
                LD      (TMP32), A
                LD      A, (TMP32+1)
                ADC     A, 00H
                LD      (TMP32+1), A
                LD      A, (TMP32+2)
                ADC     A, 00H
                LD      (TMP32+2), A
                LD      A, (TMP32+3)
                ADC     A, 00H
                LD      (TMP32+3), A
                RET

; DATA_ABS = (dataoff==0 ? 0x40 : 0x34 + dataoff)
GET_DATA_ABS:   LD      HL, VGMBUF+VGM_DATAOFF
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      NZ, GDA_NONZERO
                ; 0x00000040
                XOR     A
                LD      (DATA_ABS+1), A
                LD      (DATA_ABS+2), A
                LD      (DATA_ABS+3), A
                LD      A, 040H
                LD      (DATA_ABS), A
                RET
GDA_NONZERO:    LD      HL, VGMBUF+VGM_DATAOFF
                LD      DE, DATA_ABS
                LD      BC, 4
                LDIR
                LD      A, (DATA_ABS)
                ADD     A, 034H
                LD      (DATA_ABS), A
                LD      A, (DATA_ABS+1)
                ADC     A, 00H
                LD      (DATA_ABS+1), A
                LD      A, (DATA_ABS+2)
                ADC     A, 00H
                LD      (DATA_ABS+2), A
                LD      A, (DATA_ABS+3)
                ADC     A, 00H
                LD      (DATA_ABS+3), A
                RET

; GD3_ABS = (gd3rel==0 ? 0 : 0x14 + gd3rel)
GET_GD3_ABS:    LD      HL, VGMBUF+VGM_GD3REL
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      NZ, GGA_NONZERO
                XOR     A
                LD      (GD3_ABS), A
                LD      (GD3_ABS+1), A
                LD      (GD3_ABS+2), A
                LD      (GD3_ABS+3), A
                RET
GGA_NONZERO:    LD      HL, VGMBUF+VGM_GD3REL
                LD      DE, GD3_ABS
                LD      BC, 4
                LDIR
                LD      A, (GD3_ABS)
                ADD     A, 014H
                LD      (GD3_ABS), A
                LD      A, (GD3_ABS+1)
                ADC     A, 00H
                LD      (GD3_ABS+1), A
                LD      A, (GD3_ABS+2)
                ADC     A, 00H
                LD      (GD3_ABS+2), A
                LD      A, (GD3_ABS+3)
                ADC     A, 00H
                LD      (GD3_ABS+3), A
                RET

; Return A=1 if version >= 1.51, else A=0
EXT_CLOCKS_OK:  LD      HL, VGMBUF+VGM_VERSION
                LD      A, (HL)             ; minor
                LD      B, A
                INC     HL
                LD      A, (HL)             ; major
                CP      01H
                JR      C, ECO_NO
                JR      NZ, ECO_YES         ; major > 1
                LD      A, B
                CP      051H
                JR      C, ECO_NO
ECO_YES:        LD      A, 1
                RET
ECO_NO:         XOR     A
                RET

; Read OPL3 clock into TMP32 if available, else 0
GET_OPL3_CLK:   CALL    EXT_CLOCKS_OK
                OR      A
                JR      Z, GOC_ZERO
                LD      HL, (HDR_SIZE)
                LD      DE, 0060H           ; need header_size > 0x5F
                OR      A
                SBC     HL, DE
                JR      C, GOC_ZERO
                LD      HL, VGMBUF+VGM_YMF262_CLK
                CALL    COPY32
                RET
GOC_ZERO:       XOR     A
                LD      (TMP32), A
                LD      (TMP32+1), A
                LD      (TMP32+2), A
                LD      (TMP32+3), A
                RET

; Read AY clock into TMP32 if available, else 0
GET_AY_CLK:     CALL    EXT_CLOCKS_OK
                OR      A
                JR      Z, GAC_ZERO
                LD      HL, (HDR_SIZE)
                LD      DE, 0078H           ; need header_size > 0x77
                OR      A
                SBC     HL, DE
                JR      C, GAC_ZERO
                LD      HL, VGMBUF+VGM_AY8910_CLK
                CALL    COPY32
                RET
GAC_ZERO:       XOR     A
                LD      (TMP32), A
                LD      (TMP32+1), A
                LD      (TMP32+2), A
                LD      (TMP32+3), A
                RET

;------------------------------------------------------------------------------
; GD3 tag reading + printing
;------------------------------------------------------------------------------

; Increment RANDREC (24-bit)
INC_RANDREC:    LD      HL, RANDREC
                INC     (HL)
                RET     NZ
                INC     HL
                INC     (HL)
                RET     NZ
                INC     HL
                INC     (HL)
                RET

; Read up to 16 records (2048 bytes) starting at GD3_ABS into GD3BUF
READ_GD3_BUF:
                ; intra = GD3_ABS & 0x7F
                LD      A, (GD3_ABS)
                AND     07FH
                LD      (GD3_INTRA), A

                ; compute record = GD3_ABS >> 7 (use B:C:D:E as 32-bit)
                LD      A, (GD3_ABS)
                LD      E, A
                LD      A, (GD3_ABS+1)
                LD      D, A
                LD      A, (GD3_ABS+2)
                LD      C, A
                LD      A, (GD3_ABS+3)
                LD      B, A

                LD      A, 7
RG_SHIFT:       SRL     B
                RR      C
                RR      D
                RR      E
                DEC     A
                JR      NZ, RG_SHIFT

                ; RANDREC = start record
                LD      HL, RANDREC
                LD      (HL), E
                INC     HL
                LD      (HL), D
                INC     HL
                LD      (HL), C

                ; read 16 records
                LD      HL, GD3BUF
                LD      B, 16
RG_LOOP:        PUSH    BC

                ; set FCB randrec bytes
                CALL    SET_FCB_RANDREC

                ; set DMA = HL
                PUSH    HL
                PUSH    HL
                POP     DE
                LD      C, SETDMA
                CALL    BDOS
                POP     HL

                ; random read
                LD      DE, FILE_FCB
                LD      C, RREAD
                CALL    BDOS

                POP     BC
                OR      A
                JR      NZ, RG_DONE

                CALL    INC_RANDREC

                LD      DE, 0080H
                ADD     HL, DE
                DJNZ    RG_LOOP

RG_DONE:
                ; Restore DMA for directory scanning
                LD      DE, BUFF
                LD      C, SETDMA
                CALL    BDOS
                RET

; Set FCB random record bytes from RANDREC
SET_FCB_RANDREC:
                LD      A, (RANDREC)
                LD      (FILE_FCB+33), A
                LD      A, (RANDREC+1)
                LD      (FILE_FCB+34), A
                LD      A, (RANDREC+2)
                LD      (FILE_FCB+35), A
                RET

; Skip UTF-16LE string at HL, returns HL at next string
GD3_SKIP_STR:
GSS_LOOP:
                ; Bounds check: stop if HL is past end of GD3BUF
                LD      DE, GD3BUF+2048
                OR      A
                SBC     HL, DE
                JR      C, GSS_INRANGE
                ; out of range -> stop skipping
                RET
GSS_INRANGE:    ADD     HL, DE

                LD      A, (HL)
                INC     HL
                LD      B, (HL)
                INC     HL
                OR      B
                JR      NZ, GSS_LOOP
                RET

; Read UTF-16LE string at HL into TMPSTR (best-effort ASCII), returns HL at next string
; - Stops at UTF-16LE NUL (0x0000)
; - Replaces non-ASCII or nonzero high byte with '?'
GD3_READ_STR:   LD      DE, TMPSTR
                LD      C, 63
GRS_LOOP:
                ; Bounds check: need two bytes available (HL <= GD3BUF+2046)
                PUSH    DE
                LD      DE, GD3BUF+2047
                OR      A
                SBC     HL, DE
                JR      C, GRS_OKPTR
                ; out of range -> terminate
                ADD     HL, DE
                POP     DE
                XOR     A
                LD      (DE), A
                RET
GRS_OKPTR:      ADD     HL, DE
                POP     DE

                LD      A, (HL)             ; low byte
                INC     HL
                LD      (GD3_CHRLO), A
                LD      A, (HL)             ; high byte
                INC     HL
                LD      B, A                ; B = high byte
                LD      (GD3_CHRHI), A

                ; end of string if low==0 and high==0
                LD      A, (GD3_CHRLO)
                OR      B
                JR      Z, GRS_END

                ; map to printable ASCII if high==0 and low in [0x20..0x7E]
                LD      A, B
                OR      A
                JR      NZ, GRS_MAKEQ
                LD      A, (GD3_CHRLO)
                CP      020H
                JR      C, GRS_MAKEQ
                CP      07FH
                JR      NC, GRS_MAKEQ
                LD      B, A                ; B = character
                JR      GRS_HAVE
GRS_MAKEQ:      LD      B, '?'
GRS_HAVE:
                ; store if space remains
                LD      A, C
                OR      A
                JR      Z, GRS_LOOP
                LD      A, B
                LD      (DE), A
                INC     DE
                DEC     C
                JR      GRS_LOOP
GRS_END:        XOR     A
                LD      (DE), A
                RET

; Print one GD3 line: indent + label (DE) + TMPSTR (if non-empty)
GD3_PRINT_LINE: LD      A, (TMPSTR)
                OR      A
                RET     Z
                LD      B, DETAIL_INDENT
                CALL    PRTSPACES
                CALL    PRTSTR             ; DE = label
                LD      DE, TMPSTR
                CALL    PRTSTR
                CALL    CRLF
                RET

PRINT_GD3:      ; only if GD3_REL != 0
                LD      HL, VGMBUF+VGM_GD3REL
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                RET     Z

                CALL    GET_GD3_ABS
                CALL    READ_GD3_BUF

                ; HL = GD3BUF + intra
                LD      HL, GD3BUF
                LD      A, (GD3_INTRA)
                LD      E, A
                LD      D, 0
                ADD     HL, DE

                ; Verify GD3 signature
                LD      A, (HL)
                CP      'G'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      'd'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      '3'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      ' '
                RET     NZ
                INC     HL                  ; advance past signature

                ; skip version + size (8 bytes)
                LD      DE, 8
                ADD     HL, DE

                ; HL now points to start of UTF-16LE strings
                ; Title (EN), Title (JP)
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_TITLE
                CALL    GD3_PRINT_LINE
                CALL    GD3_SKIP_STR

                ; Game (EN), Game (JP)
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_GAME
                CALL    GD3_PRINT_LINE
                CALL    GD3_SKIP_STR

                ; System (EN), System (JP)
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_SYS
                CALL    GD3_PRINT_LINE
                CALL    GD3_SKIP_STR

                ; Author (EN), Author (JP)
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_AUTH
                CALL    GD3_PRINT_LINE
                CALL    GD3_SKIP_STR

                ; Release date
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_DATE
                CALL    GD3_PRINT_LINE

                ; Creator
                CALL    GD3_READ_STR
                LD      DE, MSG_GD3_BY
                CALL    GD3_PRINT_LINE

                RET


;------------------------------------------------------------------------------
; Parse CP/M command tail for -v (verbose) and -d (debug)
; Default is MODE_SIMPLE.
;------------------------------------------------------------------------------

PARSE_ARGS:     XOR     A
                LD      (RUN_MODE), A       ; MODE_SIMPLE
                LD      (DBG_SUM), A
                LD      (HELP_FLAG), A
                LD      (HAS_TARGET), A

                LD      HL, BUFF            ; CP/M command tail buffer
                LD      A, (HL)             ; length byte
                OR      A
                RET     Z

                LD      B, A                ; B = remaining chars
                INC     HL

PA_MAIN:
                ; Skip spaces
PA_SKIPSP:      LD      A, B
                OR      A
                RET     Z
                LD      A, (HL)
                CP      ' '
                JR      NZ, PA_TOKEN
                INC     HL
                DEC     B
                JR      PA_SKIPSP

PA_TOKEN:       ; Option token?
                CP      '-'
                JR      Z, PA_DASH
                CP      '/'
                JR      Z, PA_DASH

                ; Bare option tokens (v/d/h) only if single-character token
                CP      'v'
                JR      Z, PA_BARE_V
                CP      'V'
                JR      Z, PA_BARE_V
                CP      'd'
                JR      Z, PA_BARE_D
                CP      'D'
                JR      Z, PA_BARE_D
                CP      'h'
                JR      Z, PA_BARE_H
                CP      'H'
                JR      Z, PA_BARE_H

                ; Otherwise treat as filename token
                JR      PA_FILENAME

PA_DASH:        ; Consume '-' or '/'
                INC     HL
                DEC     B
                RET     Z
                LD      A, (HL)
                CP      'v'
                JR      Z, PA_SET_V
                CP      'V'
                JR      Z, PA_SET_V
                CP      'd'
                JR      Z, PA_SET_D
                CP      'D'
                JR      Z, PA_SET_D
                CP      'h'
                JR      Z, PA_SET_H
                CP      'H'
                JR      Z, PA_SET_H
                JR      PA_CONS_OPT

PA_BARE_V:      CALL    PA_BARE_IS_SINGLE
                JR      NZ, PA_FILENAME
PA_SET_V:       LD      A, MODE_VERBOSE
                LD      (RUN_MODE), A
                JR      PA_CONS_OPT

PA_BARE_D:      CALL    PA_BARE_IS_SINGLE
                JR      NZ, PA_FILENAME
PA_SET_D:       LD      A, MODE_DEBUG
                LD      (RUN_MODE), A
                LD      A, 1
                LD      (DBG_SUM), A
                JR      PA_CONS_OPT

PA_BARE_H:      CALL    PA_BARE_IS_SINGLE
                JR      NZ, PA_FILENAME
PA_SET_H:       LD      A, 1
                LD      (HELP_FLAG), A
                JR      PA_CONS_OPT

PA_CONS_OPT:    ; Consume one option character
                INC     HL
                DEC     B
                JR      PA_MAIN

; Returns Z if current token is single-character (end or next char is space)
PA_BARE_IS_SINGLE:
                LD      A, B
                CP      1
                RET     Z
                PUSH    HL
                INC     HL
                LD      A, (HL)
                POP     HL
                CP      ' '
                RET

; Parse filename token at HL into TARGETNAME (8 chars padded), sets HAS_TARGET.
PA_FILENAME:
                ; Pre-fill target name with spaces
                LD      DE, TARGETNAME
                LD      C, 8
                LD      A, ' '
PA_FN_FILL:     LD      (DE), A
                INC     DE
                DEC     C
                JR      NZ, PA_FN_FILL

                LD      DE, TARGETNAME
                LD      C, 8

PA_FN_LOOP:     LD      A, B
                OR      A
                JR      Z, PA_FN_DONE
                LD      A, (HL)
                CP      ' '
                JR      Z, PA_FN_DONE
                CP      '.'
                JR      Z, PA_FN_EATEXT

                ; uppercase a-z
                CP      'a'
                JR      C, PA_FN_CHKSTORE
                CP      'z'+1
                JR      NC, PA_FN_CHKSTORE
                SUB     20H

PA_FN_CHKSTORE: PUSH    AF
                LD      A, C
                OR      A
                JR      Z, PA_FN_NOSTORE
                POP     AF
                LD      (DE), A
                INC     DE
                DEC     C
                JR      PA_FN_EATCH
PA_FN_NOSTORE:  POP     AF

PA_FN_EATCH:    INC     HL
                DEC     B
                JR      PA_FN_LOOP

PA_FN_EATEXT:   ; eat '.' and the extension, stop at space
PA_FN_EATX1:    LD      A, B
                OR      A
                JR      Z, PA_FN_DONE
                LD      A, (HL)
                CP      ' '
                JR      Z, PA_FN_DONE
                INC     HL
                DEC     B
                JR      PA_FN_EATX1

PA_FN_DONE:     LD      A, 1
                LD      (HAS_TARGET), A
                JP      PA_MAIN


;------------------------------------------------------------------------------
; 512-byte checksum over VGMBUF (simple 16-bit sum)
;------------------------------------------------------------------------------

CALC_SUM512:    PUSH    AF
                PUSH    BC
                PUSH    DE
                PUSH    HL

                LD      HL, VGMBUF
                LD      DE, 0200H           ; 512 bytes
                XOR     A
                LD      (SUM_LO), A
                LD      (SUM_HI), A

SUM_LOOP:       LD      A, (HL)
                INC     HL
                LD      B, A
                LD      A, (SUM_LO)
                ADD     A, B
                LD      (SUM_LO), A
                LD      A, (SUM_HI)
                ADC     A, 0
                LD      (SUM_HI), A
                DEC     DE
                LD      A, D
                OR      E
                JR      NZ, SUM_LOOP

                POP     HL
                POP     DE
                POP     BC
                POP     AF
                RET

;------------------------------------------------------------------------------
; Debug: count number of .VGM files in current directory via SFIRST/SNEXT
; Sets DBG_TOTAL.
;------------------------------------------------------------------------------
COUNT_VGMS:
                XOR     A
                LD      (DBG_TOTAL), A

                ; Ensure DMA is BUFF
                LD      DE, BUFF
                LD      C, SETDMA
                CALL    BDOS

                ; SFIRST
                LD      DE, SEARCH_FCB
                LD      C, SFIRST
                CALL    BDOS
                CP      0FFH
                RET     Z

                ; count first match
                LD      A, 1
                LD      (DBG_TOTAL), A

CV_LOOP:
                LD      DE, SEARCH_FCB
                LD      C, SNEXT
                CALL    BDOS
                CP      0FFH
                RET     Z

                LD      A, (DBG_TOTAL)
                INC     A
                LD      (DBG_TOTAL), A
                JR      CV_LOOP

;------------------------------------------------------------------------------
; Collect all .VGM file names into FILELIST using SFIRST/SNEXT only.
; Also updates DBG_DUP using DBG_CHECK_DUP.
; Sets FILECOUNT.
; Sets DBG_COLLECT_EARLY=1 if FILECOUNT != DBG_EXPECT (or list fills).
;------------------------------------------------------------------------------
COLLECT_VGMS:
                XOR     A
                LD      (FILECOUNT), A
                LD      HL, FILELIST
                LD      (LISTPTR), HL

                ; Ensure DMA is BUFF
                LD      DE, BUFF
                LD      C, SETDMA
                CALL    BDOS

                ; SFIRST
                LD      DE, SEARCH_FCB
                LD      C, SFIRST
                CALL    BDOS
                CP      0FFH
                JR      Z, CVG_DONE

CVG_LOOP:
                ; A contains directory entry index (0-3)
                AND     03H
                RLCA
                RLCA
                RLCA
                RLCA
                RLCA                        ; * 32
                LD      L, A
                LD      H, 0
                LD      DE, BUFF
                ADD     HL, DE              ; HL -> directory entry
                INC     HL                  ; skip user

                ; Copy name to FILE_FCB+1 for duplicate checking
                LD      DE, FILE_FCB+1
                LD      BC, 11
                LDIR

                CALL    DBG_CHECK_DUP

                ; Copy name into FILELIST
                LD      HL, FILE_FCB+1
                LD      DE, (LISTPTR)
                LD      BC, 11
                LDIR
                LD      (LISTPTR), DE

                ; increment count (cap at 255)
                LD      A, (FILECOUNT)
                INC     A
                LD      (FILECOUNT), A
                CP      0FFH
                JR      C, CVG_NEXT
                LD      A, 1
                LD      (DBG_COLLECT_EARLY), A
                JR      CVG_DONE

CVG_NEXT:
                ; next match
                LD      DE, SEARCH_FCB
                LD      C, SNEXT
                CALL    BDOS
                CP      0FFH
                JR      NZ, CVG_LOOP

CVG_DONE:
                ; If DBG_EXPECT is 0 (non-debug), skip collectEarly check
                LD      A, (DBG_EXPECT)
                OR      A
                RET     Z

                ; If FILECOUNT != DBG_EXPECT, flag collectEarly
                LD      A, (FILECOUNT)
                LD      B, A
                LD      A, (DBG_EXPECT)
                CP      B
                RET     Z
                LD      A, 1
                LD      (DBG_COLLECT_EARLY), A
                RET

;------------------------------------------------------------------------------
; Debug: detect consecutive duplicate 8.3 names (from directory enumeration)
; Increments DBG_DUP if FILE_FCB+1..11 matches PREVNAME.
;------------------------------------------------------------------------------
DBG_CHECK_DUP:
                LD      A, (DBG_HAVE_PREV)
                OR      A
                JR      NZ, DCD_HAVE

                ; first entry: just store
                LD      A, 1
                LD      (DBG_HAVE_PREV), A
                LD      HL, FILE_FCB+1
                LD      DE, PREVNAME
                LD      BC, 11
                LDIR
                RET

DCD_HAVE:
                ; compare current name to previous
                LD      HL, FILE_FCB+1
                LD      DE, PREVNAME
                LD      B, 11
DCD_CMP:
                LD      A, (HL)
                LD      C, A
                LD      A, (DE)
                CP      C
                JR      NZ, DCD_STORE
                INC     HL
                INC     DE
                DJNZ    DCD_CMP

                ; match -> duplicate
                LD      A, (DBG_DUP)
                INC     A
                LD      (DBG_DUP), A

DCD_STORE:
                LD      HL, FILE_FCB+1
                LD      DE, PREVNAME
                LD      BC, 11
                LDIR
                RET

;------------------------------------------------------------------------------
; Print A as two hex digits
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Print A as unsigned decimal (0-255)
;------------------------------------------------------------------------------
PRTDEC8:        PUSH    AF
                PUSH    BC
                PUSH    DE

                LD      E, A                ; working value
                LD      B, 0                ; hundreds
PD8_HUND:       LD      A, E
                CP      100
                JR      C, PD8_TENS
                LD      A, E
                SUB     100
                LD      E, A
                INC     B
                JR      PD8_HUND

PD8_TENS:       LD      D, 0                ; tens
PD8_TENL:       LD      A, E
                CP      10
                JR      C, PD8_ONES
                LD      A, E
                SUB     10
                LD      E, A
                INC     D
                JR      PD8_TENL

PD8_ONES:       ; print hundreds if any
                LD      A, B
                OR      A
                JR      Z, PD8_PRT_T
                ADD     A, '0'
                CALL    PRTCHR

PD8_PRT_T:      ; print tens if any (or if hundreds printed)
                LD      A, B
                OR      A
                JR      NZ, PD8_T_ALWAYS
                LD      A, D
                OR      A
                JR      Z, PD8_PRT_O
PD8_T_ALWAYS:   LD      A, D
                ADD     A, '0'
                CALL    PRTCHR

PD8_PRT_O:      LD      A, E
                ADD     A, '0'
                CALL    PRTCHR

                POP     DE
                POP     BC
                POP     AF
                RET

;------------------------------------------------------------------------------
; Print 32-bit little-endian value at HL as decimal with commas
;------------------------------------------------------------------------------
PRTDEC32_COMMA:
                PUSH    AF
                PUSH    BC
                PUSH    DE
                PUSH    HL

                ; Copy input to DECVAL
                LD      DE, DECVAL
                LD      BC, 4
                LDIR

                ; Check zero
                LD      HL, DECVAL
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      NZ, P32_NZ
                LD      A, '0'
                CALL    PRTCHR
                JR      P32_DONE

P32_NZ:
                ; Build digits in reverse in DECBUF
                LD      HL, DECBUF+11
                LD      (DECPTR), HL

P32_LOOP:
                CALL    DIV10_DECVAL         ; remainder in A, quotient in DECVAL
                LD      HL, (DECPTR)
                DEC     HL
                ADD     A, '0'
                LD      (HL), A
                LD      (DECPTR), HL

                ; if DECVAL == 0 stop
                LD      HL, DECVAL
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      NZ, P32_LOOP

                ; Print digits with commas
                LD      HL, (DECPTR)
                LD      DE, DECBUF+11
                OR      A
                SBC     HL, DE               ; HL = start - end (negative)
                ; Compute length = end - start
                LD      HL, DECBUF+11
                LD      DE, (DECPTR)
                OR      A
                SBC     HL, DE
                LD      B, L                 ; length (<=10)
                LD      D, B                 ; total length

                LD      HL, (DECPTR)

P32_PRT:
                LD      A, B
                OR      A
                JR      Z, P32_DONE

                ; if remaining != total and remaining mod 3 == 0, print comma
                LD      A, B
                CP      D
                JR      Z, P32_NOCOM
                LD      A, B
P32_MOD3:       CP      3
                JR      C, P32_MOD3D
                SUB     3
                JR      P32_MOD3
P32_MOD3D:      OR      A
                JR      NZ, P32_NOCOM
                LD      A, ','
                CALL    PRTCHR
P32_NOCOM:
                LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DEC     B
                JR      P32_PRT

P32_DONE:
                POP     HL
                POP     DE
                POP     BC
                POP     AF
                RET

; Divide DECVAL (32-bit LE) by 10. Stores quotient back in DECVAL, returns remainder in A.
DIV10_DECVAL:
                PUSH    BC
                PUSH    DE
                PUSH    HL

                ; Clear QUOT
                XOR     A
                LD      HL, QUOT
                LD      (HL), A
                INC     HL
                LD      (HL), A
                INC     HL
                LD      (HL), A
                INC     HL
                LD      (HL), A

                XOR     A                    ; remainder
                LD      B, 32

D10_LOOP:
                ; Shift QUOT left 1
                LD      HL, QUOT
                LD      C, (HL)
                SLA     C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C

                ; Shift DECVAL left 1, carry gets next input bit
                LD      HL, DECVAL
                LD      C, (HL)
                SLA     C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C
                INC     HL
                LD      C, (HL)
                RL      C
                LD      (HL), C

                ; remainder = remainder*2 + inputbit (carry from DECVAL shift)
                ADC     A, A

                CP      10
                JR      C, D10_NEXT
                SUB     10
                ; set quotient bit0
                LD      HL, QUOT
                SET     0, (HL)

D10_NEXT:
                DJNZ    D10_LOOP

                ; Copy QUOT back to DECVAL
                LD      HL, QUOT
                LD      DE, DECVAL
                LD      BC, 4
                LDIR

                POP     HL
                POP     DE
                POP     BC
                RET

PRTHEX8:        PUSH    AF
                PUSH    BC

                LD      B, A                ; Save original byte in B
                SRL     A
                SRL     A
                SRL     A
                SRL     A                   ; High nibble
                CALL    PRTHEX_NIB

                LD      A, B
                AND     0FH                 ; Low nibble
                CALL    PRTHEX_NIB

                POP     BC
                POP     AF
                RET

PRTHEX_NIB:     CP      0AH
                JR      C, HEX_DIGIT
                ADD     A, 'A' - 10
                JR      PRTHEX_OUT
HEX_DIGIT:      ADD     A, '0'
PRTHEX_OUT:     CALL    PRTCHR
                RET


;------------------------------------------------------------------------------
; Print string pointed to by DE (terminated by 0)
;------------------------------------------------------------------------------

PRTSTR:         LD      A, (DE)
                OR      A
                RET     Z
                CALL    PRTCHR
                INC     DE
                JR      PRTSTR

;------------------------------------------------------------------------------
; Print character in A
;------------------------------------------------------------------------------

PRTCHR:         PUSH    BC
                PUSH    DE
                PUSH    HL
                LD      E, A
                LD      C, 2
                CALL    BDOS
                POP     HL
                POP     DE
                POP     BC
                RET

;------------------------------------------------------------------------------
; Print CR/LF
;------------------------------------------------------------------------------

CRLF:           LD      A, CR
                CALL    PRTCHR
                LD      A, LF
                CALL    PRTCHR
                RET

;------------------------------------------------------------------------------
; Messages
;------------------------------------------------------------------------------

MSG_S_HEADER1:  .DB     CR, LF
                .DB     "VGM Music Chip Scanner v1.2 b", 0
MSG_S_HEADER2:  .DB     " - 21-Feb-2026", CR, LF
                .DB     "(c)2026 Joao Miguel Duraes - MIT License", CR, LF
                .DB     CR, LF
                .DB     "Filename  Chips Used", CR, LF
                .DB     0
MSG_S_DIVIDER:  .DB     "========  =====================", CR, LF
                .DB     0

MSG_HEADER1:    .DB     CR, LF
                .DB     "VGMINFO v1.2 b", 0

MSG_HEADER2:    .DB     " - 21-Feb-2026", CR, LF
                .DB     "(c)2026 Joao Miguel Duraes - MIT License", CR, LF
                .DB     CR, LF
                .DB     0

MSG_DBG_COUNT:  .DB     "DBG: .VGM files found = ", 0
MSG_DBG_PROC:   .DB     "DBG: processing ", 0

MSG_HELP:
                .DB     CR, LF
                .DB     "Usage:", CR, LF
                .DB     "  VGMINFO [options] [filename]", CR, LF
                .DB     CR, LF
                .DB     "Options:", CR, LF
                .DB     "  -h  Help (this text)", CR, LF
                .DB     "  -v  Verbose (long output)", CR, LF
                .DB     "  -d  Debug (verbose + debug)", CR, LF
                .DB     CR, LF
                .DB     "filename:", CR, LF
                .DB     "  Base name only; .VGM assumed", CR, LF
                .DB     "  Example: VGMINFO -v PITFAL02", CR, LF
                .DB     CR, LF
                .DB     "Verbose fields:", CR, LF
                .DB     "  Size  = file size (bytes)", CR, LF
                .DB     "  Data  = VGM data start offset", CR, LF
                .DB     "  GD3   = GD3 tag offset (0 if none)", CR, LF
                .DB     "  Title/Game/Sys/Auth/Date/By= GD3 tags", CR, LF
                .DB     CR, LF
                .DB     "Debug-only fields:", CR, LF
                .DB     "  Clk1/2= chip clocks from header", CR, LF
                .DB     0
MSG_DBG_MISMATCH:.DB    "DBG: MISMATCH", CR, LF, 0
MSG_DBG_EXP:    .DB     "DBG: expected=", 0
MSG_DBG_GOT:    .DB     " got=", 0
MSG_DBG_OPENF:  .DB     "DBG: openfail=", 0
MSG_DBG_BAD:    .DB     " badsig=", 0
MSG_DBG_DUP:    .DB     " dup=", 0
MSG_DBG_COL:    .DB     " collectEarly=", 0

MSG_FILE_PREFIX: .DB    "Filename(.VGM): ", 0
MSG_VER_PREFIX:  .DB    "Version: ", 0
MSG_CHIPS_PREFIX:.DB    "Chips Used: ", 0

MSG_DIVIDER:    .DB     "------------ ----- --------------------------------", CR, LF
                .DB     0

MSG_NOFILES:    .DB     "No .VGM files found in current directory", CR, LF
                .DB     0

MSG_SN76489:    .DB     "SN76489", 0
MSG_SN76489X2:  .DB     "2xSN76489", 0
MSG_YM2612:     .DB     "YM2612", 0
MSG_YM2612X2:   .DB     "2xYM2612", 0
MSG_YM2151:     .DB     "YM2151", 0
MSG_YM2151X2:   .DB     "2xYM2151", 0
MSG_OPL2:       .DB     "YM3812", 0
MSG_OPL3:       .DB     "YMF262", 0
MSG_AY8910:     .DB     "AY-3-8910", 0
MSG_AY8910X2:   .DB     "2xAY-3-8910", 0
MSG_UNKNOWN:    .DB     "Unknown/None", 0

; Details labels
MSG_L_SIZE:     .DB     "Size: ", 0
MSG_SIZE_DEC_OPEN:.DB    " (", 0
MSG_SIZE_DEC_CLOSE:.DB   " bytes)", 0
MSG_L_DATA:     .DB     " Data:", 0
MSG_L_GD3:      .DB     " GD3:", 0
MSG_L_CLK1:     .DB     "Clk1: SN=", 0
MSG_L_CLK_YM2612:.DB     " YM2612=", 0
MSG_L_CLK_YM2151:.DB     " YM2151=", 0
MSG_L_CLK2:     .DB     "Clk2: OPL2=", 0
MSG_L_CLK_OPL3: .DB     " OPL3=", 0
MSG_L_CLK_AY:   .DB     " AY=", 0

; GD3 labels
MSG_GD3_TITLE:  .DB     "Title: ", 0
MSG_GD3_GAME:   .DB     "Game : ", 0
MSG_GD3_SYS:    .DB     "Sys  : ", 0
MSG_GD3_AUTH:   .DB     "Auth : ", 0
MSG_GD3_DATE:   .DB     "Date : ", 0
MSG_GD3_BY:     .DB     "By   : ", 0

;------------------------------------------------------------------------------
; Data area
;------------------------------------------------------------------------------

; Search FCB for *.VGM
SEARCH_FCB:     .DB     0                   ; Default drive
                .DB     '?','?','?','?','?','?','?','?'  ; Filename (wildcard)
                .DB     'V','G','M'         ; Extension
                .FILL   24, 0               ; Rest of FCB

; FCB for opening files
FILE_FCB:       .DB     0                   ; Default drive
                .FILL   35, 0               ; Rest of FCB

DIR_CODE:       .DB     0                   ; Directory code from search
CHIP_FLAGS:     .DB     0                   ; Detected chip flags
                                            ; bit0 SN76489 #1, bit1 SN76489 #2
                                            ; bit2 YM2612 #1, bit3 YM2612 #2
                                            ; bit4 YM2151 #1, bit5 YM2151 #2
                                            ; bit6 AY #1, bit7 AY #2
CHIP_TYPES:     .DB     0                   ; Chip types present (OPL2/OPL3 use)
                                            ; bit4 OPL2 (YM3812), bit5 OPL3 (YMF262)

DIRIDX:         .DB     0                   ; (unused)

; Debug counters
DBG_TOTAL:       .DB     0
DBG_EXPECT:      .DB     0
DBG_PROC:        .DB     0
DBG_OPENFAIL:    .DB     0
DBG_BADSIG:      .DB     0
DBG_DUP:         .DB     0
RUN_MODE:        .DB     0
HELP_FLAG:       .DB     0
HAS_TARGET:      .DB     0

DBG_SNEXT_EARLY: .DB     0
DBG_COLLECT_EARLY:.DB     0
DBG_HAVE_PREV:   .DB     0
PROC_PRINTED:    .DB     0
PREVNAME:        .FILL   11, 0

; Single-file target
TARGETNAME:      .FILL   8, ' '
TARGETEXT:       .DB     'V','G','M'

; Collected file list
FILECOUNT:       .DB     0
LISTPTR:         .DW     0
FILELIST:        .FILL   (255*11), 0

SUM_LO:         .DB     0                   ; Low byte of 16-bit checksum
SUM_HI:         .DB     0                   ; High byte of 16-bit checksum
DBG_SUM:        .DB     0                   ; 0=disable checksum print, non-zero=enable

VER_MINOR:      .DB     0
HDR_SIZE:       .DW     0
GD3_INTRA:      .DB     0
GD3_CHRLO:      .DB     0
GD3_CHRHI:      .DB     0

; Random record counter for BDOS random reads (24-bit, little-endian)
RANDREC:        .DB     0, 0, 0

; 32-bit temporaries
TMP32:          .FILL   4, 0
DATA_ABS:       .FILL   4, 0
GD3_ABS:        .FILL   4, 0

; Decimal conversion temporaries
DECVAL:         .FILL   4, 0
QUOT:           .FILL   4, 0
DECPTR:         .DW     0
DECBUF:         .FILL   11, 0

; Buffers
; Buffer for VGM header + first data sector (256 bytes)
VGMBUF:         .FILL   512, 0

; GD3 buffer (reads 16 * 128-byte records = 2048 bytes)
GD3BUF:         .FILL   2048, 0

; Temporary printable string buffer
TMPSTR:         .FILL   64, 0

; Stack space (needs to be reasonably large to avoid corrupting data/FCBs)
                .FILL   256, 0
STACK:          .DW     0

                .END
