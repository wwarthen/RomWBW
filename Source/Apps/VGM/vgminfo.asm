;------------------------------------------------------------------------------
; VGM File Info Display for CP/M
;------------------------------------------------------------------------------
;
; Scans all .VGM files in current directory and displays chip information
; in a formatted table
;
; (c) 2025 Joao Miguel Duraes
; Licensed under the MIT License
;
; Version: 1.1 - 06-Dec-2025
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
SETDMA          .equ    26                  ; BDOS set DMA address
SFIRST          .equ    17                  ; BDOS search first
SNEXT           .equ    18                  ; BDOS search next

CR              .equ    0DH                 ; carriage return
LF              .equ    0AH                 ; line feed

;------------------------------------------------------------------------------
; VGM Header offsets
;------------------------------------------------------------------------------

DEBUG_SUM       .equ    1                   ; 1 = build with checksum support

VGM_IDENT       .equ    00H                 ; "Vgm " identifier
VGM_VERSION     .equ    08H                 ; Version
VGM_SN76489_CLK .equ    0CH                 ; SN76489 clock (4 bytes, little-endian)
VGM_YM2612_CLK  .equ    2CH                 ; YM2612 clock (4 bytes, little-endian)
VGM_YM2151_CLK  .equ    30H                 ; YM2151 clock (4 bytes, little-endian)
VGM_DATAOFF     .equ    34H                 ; VGM data offset (relative to 0x34)
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
                
                ; Parse command tail for debug flags (e.g. "D" or "/D")
                CALL    PARSE_DEBUG
                
                ; Display header
                LD      DE, MSG_HEADER
                CALL    PRTSTR
                LD      DE, MSG_DIVIDER
                CALL    PRTSTR

                ; Setup search for *.VGM files
                LD      DE, SEARCH_FCB
                LD      C, SFIRST
                CALL    BDOS
                CP      0FFH                ; No files found?
                JP      Z, NO_FILES

FILE_LOOP:      
                ; A contains directory entry index (0-3)
                ; Each entry is 32 bytes, so multiply by 32
                AND     03H                 ; Mask to 0-3
                RLCA
                RLCA
                RLCA
                RLCA
                RLCA                        ; Multiply by 32
                LD      L, A
                LD      H, 0
                LD      DE, BUFF
                ADD     HL, DE              ; HL now points to directory entry
                
                ; Copy filename from directory entry to our FCB
                INC     HL                  ; Skip user number
                LD      DE, FILE_FCB+1      ; Destination
                LD      BC, 11              ; 8+3 filename
                LDIR
                
                ; Open and process this file
                CALL    PROCESS_FILE
                
                ; Search for next file
                LD      DE, SEARCH_FCB
                LD      C, SNEXT
                CALL    BDOS
                CP      0FFH
                JP      NZ, FILE_LOOP

                ; Done
                LD      DE, MSG_DIVIDER
                CALL    PRTSTR
                JP      BOOT                ; Exit to CP/M

NO_FILES:       LD      DE, MSG_NOFILES
                CALL    PRTSTR
                JP      BOOT

;------------------------------------------------------------------------------
; Process a VGM file - read header and display info
;------------------------------------------------------------------------------

PROCESS_FILE:   
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
                RET     Z                   ; Can't open, skip
                
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
                
                ; Close file
                LD      DE, FILE_FCB
                LD      C, CLOSEF
                CALL    BDOS
                
                ; Check if valid VGM
                LD      HL, VGMBUF
                LD      A, (HL)
                CP      'V'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      'g'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      'm'
                RET     NZ
                INC     HL
                LD      A, (HL)
                CP      ' '
                RET     NZ
                
                ; Display filename (exactly 8 chars from FCB)
                LD      HL, FILE_FCB+1
                LD      B, 8
PRINT_NAME:     LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DJNZ    PRINT_NAME
                
                ; Add 2-space gap
                LD      A, ' '
                CALL    PRTCHR
                LD      A, ' '
                CALL    PRTCHR

#if DEBUG_SUM
                ; Compute and optionally print 512-byte checksum over VGMBUF
                CALL    CALC_SUM512
                LD      A, (DBG_SUM)
                OR      A
                JR      Z, PAD_DONE

                ; Print space + [HHLL] + space between filename and chips
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
                LD      A, ' '
                CALL    PRTCHR
#endif

PAD_DONE:
                
                ; Check and display chip info
                CALL    CHECK_CHIPS
                
                ; New line
                CALL    CRLF
                
                RET

;------------------------------------------------------------------------------
; Check which chips are used: hybrid approach
; 1. Check header clocks to see which chip types are present
; 2. Scan commands to detect multiple instances of same chip type
;------------------------------------------------------------------------------

CHECK_CHIPS:    
                ; Initialize chip flags
                XOR     A
                LD      (CHIP_FLAGS), A
                LD      (CHIP_TYPES), A         ; Types present from header
                
                ; Check SN76489 clock (4 bytes at 0x0C)
                LD      HL, VGMBUF+VGM_SN76489_CLK
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      Z, CHK_YM2612_CLK
                LD      A, (CHIP_TYPES)
                OR      01H                     ; bit 0 = SN76489 present
                LD      (CHIP_TYPES), A
                
CHK_YM2612_CLK:
                ; Check YM2612 clock (4 bytes at 0x2C)
                LD      HL, VGMBUF+VGM_YM2612_CLK
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      Z, CHK_YM2151_CLK
                LD      A, (CHIP_TYPES)
                OR      02H                     ; bit 1 = YM2612 present
                LD      (CHIP_TYPES), A
                
CHK_YM2151_CLK:
                ; Check YM2151 clock (4 bytes at 0x30)
                LD      HL, VGMBUF+VGM_YM2151_CLK
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      Z, CHK_AY_CLK
                LD      A, (CHIP_TYPES)
                OR      04H                     ; bit 2 = YM2151 present
                LD      (CHIP_TYPES), A
                
CHK_AY_CLK:
                ; Check AY-3-8910 clock (4 bytes at 0x74, only valid in VGM v1.51+)
                LD      HL, VGMBUF+VGM_VERSION
                LD      A, (HL)                 ; Get low byte of version
                CP      51H                     ; Check if >= 0x51 (v1.51)
                JR      C, START_CMD_SCAN       ; Skip if < v1.51
                INC     HL
                LD      A, (HL)                 ; Get high byte
                CP      01H                     ; Must be 0x01
                JR      NZ, START_CMD_SCAN      ; Skip if not v1.xx
                
                LD      HL, VGMBUF+VGM_AY8910_CLK
                LD      A, (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                INC     HL
                OR      (HL)
                JR      Z, START_CMD_SCAN
                LD      A, (CHIP_TYPES)
                OR      08H                     ; bit 3 = AY present
                LD      (CHIP_TYPES), A
                
START_CMD_SCAN:
                ; Clear AY flags if AY is not present in header
                LD      A, (CHIP_TYPES)
                BIT     3, A                      ; Check if AY is present
                JR      NZ, SCAN_CMDS            ; If present, continue
                LD      A, (CHIP_FLAGS)
                AND     3FH                       ; Clear bits 6 and 7 (AY flags)
                LD      (CHIP_FLAGS), A
SCAN_CMDS:
                ; If chip type is present, scan commands to detect multiples
                ; Set base flags from types
                LD      A, (CHIP_TYPES)
                BIT     0, A
                JR      Z, NO_SN_BASE
                LD      A, (CHIP_FLAGS)
                OR      01H                     ; Set SN #1
                LD      (CHIP_FLAGS), A
NO_SN_BASE:
                LD      A, (CHIP_TYPES)
                BIT     1, A
                JR      Z, NO_YM2612_BASE
                LD      A, (CHIP_FLAGS)
                OR      04H                     ; Set YM2612 #1
                LD      (CHIP_FLAGS), A
NO_YM2612_BASE:
                LD      A, (CHIP_TYPES)
                BIT     2, A
                JR      Z, NO_YM2151_BASE
                ; Do NOT pre-mark YM2151 as used from the header alone.
                ; YM2151 will only be marked used when a command is seen.
NO_YM2151_BASE:
                ; Do NOT pre-mark AY as used from the header alone.
                ; AY will only be marked used when an 0xA0 command is seen.
NO_AY_BASE:

COMPUTE_DATA_START:
                LD      HL, (VGMBUF+VGM_DATAOFF)
                LD      A, H
                OR      L
                JR      NZ, GOT_OFFSET
                LD      HL, 000CH           ; Default for VGM < 1.50 (0x40-0x34)
GOT_OFFSET:     LD      DE, VGMBUF+VGM_DATAOFF
                ADD     HL, DE              ; HL = VGMBUF + 0x34 + offset
                
                ; Constrain to our 256-byte buffer
                LD      DE, VGMBUF
                SBC     HL, DE              ; HL = offset from VGMBUF base
                ADD     HL, DE              ; restore HL absolute inside VGMBUF
                
                ; Scan up to 255 commands or until EOD
                LD      C, 255
SCAN_LOOP:      LD      A, (HL)
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
                LD      A, (CHIP_TYPES)     ; Only if SN76489 is present
                BIT     0, A
                JR      Z, SCAN_NEXT_1
                LD      A, (CHIP_FLAGS)
                OR      02H                 ; bit 1 = SN #2
                LD      (CHIP_FLAGS), A
SCAN_NEXT_1:    INC     HL
                JP      SCAN_NEXT
                
CHK_YM2612:     CP      VGM_YM26121_W
                JR      Z, GOT_YM2612_1
                CP      VGM_YM26122_W
                JR      Z, GOT_YM2612_1
                CP      VGM_YM26123_W
                JR      Z, GOT_YM2612_2
                CP      VGM_YM26124_W
                JP      NZ, CHK_YM2151
GOT_YM2612_2:   LD      A, (CHIP_TYPES)     ; Only if YM2612 is present
                BIT     1, A
                JR      Z, SCAN_NEXT_2
                LD      A, (CHIP_FLAGS)
                OR      08H                 ; bit 3 = YM2612 #2
                LD      (CHIP_FLAGS), A
SCAN_NEXT_2:    INC     HL
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
                LD      A, (CHIP_TYPES)     ; Only if YM2151 is present
                BIT     2, A
                JR      Z, SCAN_NEXT_3
                LD      A, (CHIP_FLAGS)
                OR      20H                 ; bit 5 = YM2151 #2
                LD      (CHIP_FLAGS), A
SCAN_NEXT_3:    INC     HL
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
                LD      A, (CHIP_TYPES)     ; Only if AY is present
                BIT     3, A
                JR      Z, SCAN_SKIP_AY     ; Skip if AY not present in header
                LD      A, (HL)             ; Get register/chip byte
                BIT     7, A                ; Bit 7 = chip 2?
                JR      Z, GOT_AY1
                LD      A, (CHIP_FLAGS)
                OR      80H                 ; bit 7 = AY #2
                LD      (CHIP_FLAGS), A
                JR      SCAN_SKIP_AY
GOT_AY1:        LD      A, (CHIP_FLAGS)
                OR      40H                 ; bit 6 = AY #1
                LD      (CHIP_FLAGS), A
SCAN_SKIP_AY:    INC     HL
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
; Parse CP/M command tail for debug flag (D or /D) -> sets DBG_SUM
;------------------------------------------------------------------------------

PARSE_DEBUG:    LD      HL, BUFF            ; CP/M command tail buffer
                LD      A, (HL)             ; length byte
                OR      A
                RET     Z                   ; empty tail, no flags

                LD      B, A                ; B = remaining chars
                INC     HL                  ; HL -> first character

PD_LOOP:        LD      A, (HL)
                CP      ' '                 ; skip spaces
                JR      Z, PD_NEXT

                CP      '/'
                JR      Z, PD_SLASH

                CP      'D'
                JR      Z, PD_SET
                CP      'd'
                JR      Z, PD_SET
                JR      PD_NEXT

PD_SLASH:       ; look at next char for D/d
                INC     HL
                DJNZ    PD_CHECK2
                RET

PD_CHECK2:      LD      A, (HL)
                CP      'D'
                JR      Z, PD_SET
                CP      'd'
                JR      Z, PD_SET
                JR      PD_NEXT_CONT

PD_NEXT:        INC     HL
PD_NEXT_CONT:   DJNZ    PD_LOOP
                RET

PD_SET:         LD      A, 1
                LD      (DBG_SUM), A
                RET


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
; Print A as two hex digits
;------------------------------------------------------------------------------

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

MSG_HEADER:     .DB     CR, LF
                .DB     "VGM Music Chip Scanner v1.1 - 06-Dec-2025", CR, LF
                .DB     "(c)2025 Joao Miguel Duraes - MIT License", CR, LF
                .DB     CR, LF
                .DB     "Filename  Chips Used", CR, LF
                .DB     0

MSG_DIVIDER:    .DB     "========  =====================", CR, LF
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
CHIP_TYPES:     .DB     0                   ; Chip types present from header
                                            ; bit0 SN76489, bit1 YM2612
                                            ; bit2 YM2151, bit3 AY-3-8910
                                            ; bit4 OPL2 (YM3812), bit5 OPL3 (YMF262)

SUM_LO:         .DB     0                   ; Low byte of 16-bit checksum
SUM_HI:         .DB     0                   ; High byte of 16-bit checksum
DBG_SUM:        .DB     0                   ; 0=disable checksum print, non-zero=enable

; Buffer for VGM header + first data sector (256 bytes)
VGMBUF:         .FILL   512, 0

; Stack space
                .FILL   64, 0
STACK:          .DW     0

                .END
