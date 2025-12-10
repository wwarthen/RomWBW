;------------------------------------------------------------------------------
; VGM File Info Display - Debug Version
;------------------------------------------------------------------------------

BOOT            .equ    0000H
BDOS            .equ    0005H
BUFF            .equ    0080H
SFIRST          .equ    17
SNEXT           .equ    18
CR              .equ    0DH
LF              .equ    0AH

                .ORG    100H

START:          LD      SP, STACK
                
                ; Display header
                LD      DE, MSG_HEADER
                CALL    PRTSTR
                
                ; Setup search
                LD      DE, SEARCH_FCB
                LD      C, SFIRST
                CALL    BDOS
                LD      B, A                ; Save result
                
                ; Display result code
                LD      A, 'F'
                CALL    PRTCHR
                LD      A, ':'
                CALL    PRTCHR
                LD      A, B
                CALL    PRTHEX
                CALL    CRLF
                
                LD      A, B
                CP      0FFH
                JP      Z, NO_FILES
                
FILE_LOOP:      LD      A, B
                CALL    PRTHEX
                LD      A, ':'
                CALL    PRTCHR
                
                ; Calculate offset
                LD      A, B
                AND     03H
                RLCA
                RLCA
                RLCA
                RLCA
                RLCA
                LD      L, A
                LD      H, 0
                LD      DE, BUFF
                ADD     HL, DE
                
                ; Print filename from directory entry
                INC     HL                  ; Skip user
                LD      B, 11               ; 8+3 filename
PRINT_LOOP:     LD      A, (HL)
                CALL    PRTCHR
                INC     HL
                DJNZ    PRINT_LOOP
                
                CALL    CRLF
                
                ; Search next
                LD      DE, SEARCH_FCB
                LD      C, SNEXT
                CALL    BDOS
                LD      B, A
                CP      0FFH
                JP      NZ, FILE_LOOP
                
                JP      BOOT

NO_FILES:       LD      DE, MSG_NOFILES
                CALL    PRTSTR
                JP      BOOT

PRTSTR:         LD      A, (DE)
                OR      A
                RET     Z
                CALL    PRTCHR
                INC     DE
                JR      PRTSTR

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

PRTHEX:         PUSH    AF
                RRCA
                RRCA
                RRCA
                RRCA
                CALL    PRHEX1
                POP     AF
PRHEX1:         AND     0FH
                ADD     A, '0'
                CP      '9'+1
                JR      C, PRHEX2
                ADD     A, 7
PRHEX2:         CALL    PRTCHR
                RET

CRLF:           LD      A, CR
                CALL    PRTCHR
                LD      A, LF
                CALL    PRTCHR
                RET

MSG_HEADER:     .DB     CR, LF, "VGM Debug Test", CR, LF, LF, 0
MSG_NOFILES:    .DB     "No files found", CR, LF, 0

SEARCH_FCB:     .DB     0
                .DB     '?','?','?','?','?','?','?','?'
                .DB     'V','G','M'
                .FILL   24, 0

                .FILL   64, 0
STACK:          .DW     0

                .END
