; -----------------------------------------------------------------------------
; Decompress raw LZSA1 block. Create one with lzsa -r <original_file> <compressed_file>
;
; in:
; * LZSA_SRC_LO and LZSA_SRC_HI contain the compressed raw block address
; * LZSA_DST_LO and LZSA_DST_HI contain the destination buffer address
;
; out:
; * LZSA_DST_LO and LZSA_DST_HI contain the last decompressed byte address, +1
;
; -----------------------------------------------------------------------------
; Backward decompression is also supported, use lzsa -r -b <original_file> <compressed_file>
; To use it, also define BACKWARD_DECOMPRESS=1 before including this code!
;
; in:
; * LZSA_SRC_LO/LZSA_SRC_HI must contain the address of the last byte of compressed data
; * LZSA_DST_LO/LZSA_DST_HI must contain the address of the last byte of the destination buffer
;
; out:
; * LZSA_DST_LO/LZSA_DST_HI contain the last decompressed byte address, -1
;
; -----------------------------------------------------------------------------
;
;  Copyright (C) 2019 Emmanuel Marty, Peter Ferrie
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.
; -----------------------------------------------------------------------------

DECOMPRESS_LZSA1_FAST
   LDY #$00

DECODE_TOKEN
   JSR GETSRC                           ; read token byte: O|LLL|MMMM
   PHA                                  ; preserve token on stack

   AND #$70                             ; isolate literals count
   BEQ NO_LITERALS                      ; skip if no literals to copy
   CMP #$70                             ; LITERALS_RUN_LEN?
   BNE PREPARE_COPY_LITERALS            ; if not, count is directly embedded in token

   JSR GETSRC                           ; get extra byte of variable literals count
                                        ; the carry is always set by the CMP above
                                        ; GETSRC doesn't change it
   SBC #$F9                             ; (LITERALS_RUN_LEN)
   BCC PREPARE_COPY_LITERALS_DIRECT
   BEQ LARGE_VARLEN_LITERALS            ; if adding up to zero, go grab 16-bit count

   JSR GETSRC                           ; get single extended byte of variable literals count
   INY                                  ; add 256 to literals count
   BCS PREPARE_COPY_LITERALS_DIRECT     ; (*like JMP PREPARE_COPY_LITERALS_DIRECT but shorter)

LARGE_VARLEN_LITERALS                   ; handle 16 bits literals count
                                        ; literals count = directly these 16 bits
   JSR GETLARGESRC                      ; grab low 8 bits in X, high 8 bits in A
   TAY                                  ; put high 8 bits in Y
   TXA
   BCS PREPARE_COPY_LARGE_LITERALS      ; (*like JMP PREPARE_COPY_LITERALS_DIRECT but shorter)

PREPARE_COPY_LITERALS
   TAX
   LDA SHIFT_TABLE-1,X                  ; shift literals length into place
                                        ; -1 because position 00 is reserved
PREPARE_COPY_LITERALS_DIRECT
   TAX

PREPARE_COPY_LARGE_LITERALS
   BEQ COPY_LITERALS
   INY

COPY_LITERALS
   JSR GETPUT                           ; copy one byte of literals
   DEX
   BNE COPY_LITERALS
   DEY
   BNE COPY_LITERALS
   
NO_LITERALS
   PLA                                  ; retrieve token from stack
   PHA                                  ; preserve token again
   BMI GET_LONG_OFFSET                  ; $80: 16 bit offset

   JSR GETSRC                           ; get 8 bit offset from stream in A
   TAX                                  ; save for later
   LDA #$FF                             ; high 8 bits
   BNE GOT_OFFSET                       ; go prepare match
                                        ; (*like JMP GOT_OFFSET but shorter)

SHORT_VARLEN_MATCHLEN
   JSR GETSRC                           ; get single extended byte of variable match len
   INY                                  ; add 256 to match length

PREPARE_COPY_MATCH
   TAX
PREPARE_COPY_MATCH_Y
   TXA
   BEQ COPY_MATCH_LOOP
   INY

COPY_MATCH_LOOP
   LDA $AAAA                            ; get one byte of backreference
   JSR PUTDST                           ; copy to destination

!ifdef BACKWARD_DECOMPRESS {

   ; Backward decompression -- put backreference bytes backward

   LDA COPY_MATCH_LOOP+1
   BEQ GETMATCH_ADJ_HI
GETMATCH_DONE
   DEC COPY_MATCH_LOOP+1

} else {

   ; Forward decompression -- put backreference bytes forward

   INC COPY_MATCH_LOOP+1
   BEQ GETMATCH_ADJ_HI
GETMATCH_DONE

}

   DEX
   BNE COPY_MATCH_LOOP
   DEY
   BNE COPY_MATCH_LOOP
   BEQ DECODE_TOKEN                     ; (*like JMP DECODE_TOKEN but shorter)

!ifdef BACKWARD_DECOMPRESS {

GETMATCH_ADJ_HI
   DEC COPY_MATCH_LOOP+2
   JMP GETMATCH_DONE

} else {

GETMATCH_ADJ_HI
   INC COPY_MATCH_LOOP+2
   JMP GETMATCH_DONE

}

GET_LONG_OFFSET                         ; handle 16 bit offset:
   JSR GETLARGESRC                      ; grab low 8 bits in X, high 8 bits in A

GOT_OFFSET

!ifdef BACKWARD_DECOMPRESS {

   ; Backward decompression - substract match offset

   STA OFFSHI                           ; store high 8 bits of offset
   STX OFFSLO

   SEC                                  ; substract dest - match offset
   LDA PUTDST+1
OFFSLO = *+1
   SBC #$AA                             ; low 8 bits
   STA COPY_MATCH_LOOP+1                ; store back reference address
   LDA PUTDST+2
OFFSHI = *+1
   SBC #$AA                             ; high 8 bits
   STA COPY_MATCH_LOOP+2                ; store high 8 bits of address
   SEC

} else {

   ; Forward decompression - add match offset

   STA OFFSHI                           ; store high 8 bits of offset
   TXA

   CLC                                  ; add dest + match offset
   ADC PUTDST+1                         ; low 8 bits
   STA COPY_MATCH_LOOP+1                ; store back reference address
OFFSHI = *+1
   LDA #$AA                             ; high 8 bits

   ADC PUTDST+2
   STA COPY_MATCH_LOOP+2                ; store high 8 bits of address
   
}

   PLA                                  ; retrieve token from stack again
   AND #$0F                             ; isolate match len (MMMM)
   ADC #$02                             ; plus carry which is always set by the high ADC
   CMP #$12                             ; MATCH_RUN_LEN?
   BCC PREPARE_COPY_MATCH               ; if not, count is directly embedded in token

   JSR GETSRC                           ; get extra byte of variable match length
                                        ; the carry is always set by the CMP above
                                        ; GETSRC doesn't change it
   SBC #$EE                             ; add MATCH_RUN_LEN and MIN_MATCH_SIZE to match length
   BCC PREPARE_COPY_MATCH
   BNE SHORT_VARLEN_MATCHLEN

                                        ; Handle 16 bits match length
   JSR GETLARGESRC                      ; grab low 8 bits in X, high 8 bits in A
   TAY                                  ; put high 8 bits in Y
                                        ; large match length with zero high byte?
   BNE PREPARE_COPY_MATCH_Y             ; if not, continue

DECOMPRESSION_DONE
   RTS

SHIFT_TABLE
   !BYTE     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
   !BYTE $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
   !BYTE $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
   !BYTE $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
   !BYTE $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
   !BYTE $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
   !BYTE $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
   !BYTE $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07

!ifdef BACKWARD_DECOMPRESS {

   ; Backward decompression -- get and put bytes backward

GETPUT
   JSR GETSRC
PUTDST
LZSA_DST_LO = *+1
LZSA_DST_HI = *+2
   STA $AAAA
   LDA PUTDST+1
   BEQ PUTDST_ADJ_HI
   DEC PUTDST+1
   RTS

PUTDST_ADJ_HI
   DEC PUTDST+2
   DEC PUTDST+1
   RTS

GETLARGESRC
   JSR GETSRC                           ; grab low 8 bits
   TAX                                  ; move to X
                                        ; fall through grab high 8 bits

GETSRC
LZSA_SRC_LO = *+1
LZSA_SRC_HI = *+2
   LDA $AAAA
   PHA
   LDA GETSRC+1
   BEQ GETSRC_ADJ_HI
   DEC GETSRC+1
   PLA
   RTS

GETSRC_ADJ_HI
   DEC GETSRC+2
   DEC GETSRC+1
   PLA
   RTS

} else {

   ; Forward decompression -- get and put bytes forward

GETPUT
   JSR GETSRC
PUTDST
LZSA_DST_LO = *+1
LZSA_DST_HI = *+2
   STA $AAAA
   INC PUTDST+1
   BEQ PUTDST_ADJ_HI
   RTS

PUTDST_ADJ_HI
   INC PUTDST+2
   RTS

GETLARGESRC
   JSR GETSRC                           ; grab low 8 bits
   TAX                                  ; move to X
                                        ; fall through grab high 8 bits

GETSRC
LZSA_SRC_LO = *+1
LZSA_SRC_HI = *+2
   LDA $AAAA
   INC GETSRC+1
   BEQ GETSRC_ADJ_HI
   RTS

GETSRC_ADJ_HI
   INC GETSRC+2
   RTS
}
