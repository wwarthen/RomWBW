; -----------------------------------------------------------------------------
; Decompress raw LZSA2 block.
; Create one with lzsa -r -f2 <original_file> <compressed_file>
;
; in:
; * LZSA_SRC_LO and LZSA_SRC_HI contain the compressed raw block address
; * LZSA_DST_LO and LZSA_DST_HI contain the destination buffer address
;
; out:
; * LZSA_DST_LO and LZSA_DST_HI contain the last decompressed byte address, +1
;
; -----------------------------------------------------------------------------
; Backward decompression is also supported, use lzsa -r -b -f2 <original_file> <compressed_file>
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

NIBCOUNT = $FC                          ; zero-page location for temp offset

DECOMPRESS_LZSA2_FAST
   LDY #$00
   STY NIBCOUNT

DECODE_TOKEN
   JSR GETSRC                           ; read token byte: XYZ|LL|MMM
   PHA                                  ; preserve token on stack

   AND #$18                             ; isolate literals count (LL)
   BEQ NO_LITERALS                      ; skip if no literals to copy
   CMP #$18                             ; LITERALS_RUN_LEN_V2?
   BCC PREPARE_COPY_LITERALS            ; if less, count is directly embedded in token

   JSR GETNIBBLE                        ; get extra literals length nibble
                                        ; add nibble to len from token
   ADC #$02                             ; (LITERALS_RUN_LEN_V2) minus carry
   CMP #$12                             ; LITERALS_RUN_LEN_V2 + 15 ?
   BCC PREPARE_COPY_LITERALS_DIRECT     ; if less, literals count is complete

   JSR GETSRC                           ; get extra byte of variable literals count
                                        ; the carry is always set by the CMP above
                                        ; GETSRC doesn't change it
   SBC #$EE                             ; overflow?
   JMP PREPARE_COPY_LITERALS_DIRECT

PREPARE_COPY_LITERALS_LARGE
                                        ; handle 16 bits literals count
                                        ; literals count = directly these 16 bits
   JSR GETLARGESRC                      ; grab low 8 bits in X, high 8 bits in A
   TAY                                  ; put high 8 bits in Y
   BCS PREPARE_COPY_LITERALS_HIGH       ; (*same as JMP PREPARE_COPY_LITERALS_HIGH but shorter)

PREPARE_COPY_LITERALS
   LSR                                  ; shift literals count into place
   LSR
   LSR

PREPARE_COPY_LITERALS_DIRECT
   TAX
   BCS PREPARE_COPY_LITERALS_LARGE      ; if so, literals count is large

PREPARE_COPY_LITERALS_HIGH
   TXA
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
   ASL
   BCS REPMATCH_OR_LARGE_OFFSET         ; 1YZ: rep-match or 13/16 bit offset

   ASL                                  ; 0YZ: 5 or 9 bit offset
   BCS OFFSET_9_BIT         
    
                                        ; 00Z: 5 bit offset

   LDX #$FF                             ; set offset bits 15-8 to 1

   JSR GETCOMBINEDBITS                  ; rotate Z bit into bit 0, read nibble for bits 4-1
   ORA #$E0                             ; set bits 7-5 to 1
   BNE GOT_OFFSET_LO                    ; go store low byte of match offset and prepare match
   
OFFSET_9_BIT                            ; 01Z: 9 bit offset
   ROL                                  ; carry: Z bit; A: xxxxxxx1 (carry known set from BCS OFFSET_9_BIT)
   ADC #$00                             ; if Z bit is set, add 1 to A (bit 0 of A is now 0), otherwise bit 0 is 1
   ORA #$FE                             ; set offset bits 15-9 to 1. reversed Z is already in bit 0
   BNE GOT_OFFSET_HI                    ; go store high byte, read low byte of match offset and prepare match
                                        ; (*same as JMP GOT_OFFSET_HI but shorter)

REPMATCH_OR_LARGE_OFFSET
   ASL                                  ; 13 bit offset?
   BCS REPMATCH_OR_16_BIT               ; handle rep-match or 16-bit offset if not

                                        ; 10Z: 13 bit offset

   JSR GETCOMBINEDBITS                  ; rotate Z bit into bit 8, read nibble for bits 12-9
   ADC #$DE                             ; set bits 15-13 to 1 and substract 2 (to substract 512)
   BNE GOT_OFFSET_HI                    ; go store high byte, read low byte of match offset and prepare match
                                        ; (*same as JMP GOT_OFFSET_HI but shorter)

REPMATCH_OR_16_BIT                      ; rep-match or 16 bit offset
   BMI REP_MATCH                        ; reuse previous offset if so (rep-match)
   
                                        ; 110: handle 16 bit offset
   JSR GETSRC                           ; grab high 8 bits
GOT_OFFSET_HI
   TAX
   JSR GETSRC                           ; grab low 8 bits
GOT_OFFSET_LO
   STA OFFSLO                           ; store low byte of match offset
   STX OFFSHI                           ; store high byte of match offset

REP_MATCH
!ifdef BACKWARD_DECOMPRESS {

   ; Backward decompression - substract match offset

   SEC                                  ; add dest + match offset
   LDA PUTDST+1                         ; low 8 bits
OFFSLO = *+1
   SBC #$AA
   STA COPY_MATCH_LOOP+1                ; store back reference address
   LDA PUTDST+2
OFFSHI = *+1
   SBC #$AA                             ; high 8 bits
   STA COPY_MATCH_LOOP+2                ; store high 8 bits of address
   SEC

} else {

   ; Forward decompression - add match offset

   CLC                                  ; add dest + match offset
   LDA PUTDST+1                         ; low 8 bits
OFFSLO = *+1
   ADC #$AA
   STA COPY_MATCH_LOOP+1                ; store back reference address
OFFSHI = *+1
   LDA #$AA                             ; high 8 bits
   ADC PUTDST+2
   STA COPY_MATCH_LOOP+2                ; store high 8 bits of address
   
}
   
   PLA                                  ; retrieve token from stack again
   AND #$07                             ; isolate match len (MMM)
   ADC #$01                             ; add MIN_MATCH_SIZE_V2 and carry
   CMP #$09                             ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2?
   BCC PREPARE_COPY_MATCH               ; if less, length is directly embedded in token

   JSR GETNIBBLE                        ; get extra match length nibble
                                        ; add nibble to len from token
   ADC #$08                             ; (MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2) minus carry
   CMP #$18                             ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15?
   BCC PREPARE_COPY_MATCH               ; if less, match length is complete

   JSR GETSRC                           ; get extra byte of variable match length
                                        ; the carry is always set by the CMP above
                                        ; GETSRC doesn't change it
   SBC #$E8                             ; overflow?

PREPARE_COPY_MATCH
   TAX
   BCC PREPARE_COPY_MATCH_Y             ; if not, the match length is complete
   BEQ DECOMPRESSION_DONE               ; if EOD code, bail

                                        ; Handle 16 bits match length
   JSR GETLARGESRC                      ; grab low 8 bits in X, high 8 bits in A
   TAY                                  ; put high 8 bits in Y

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
   JMP DECODE_TOKEN

!ifdef BACKWARD_DECOMPRESS {

GETMATCH_ADJ_HI
   DEC COPY_MATCH_LOOP+2
   JMP GETMATCH_DONE

} else {

GETMATCH_ADJ_HI
   INC COPY_MATCH_LOOP+2
   JMP GETMATCH_DONE

}

GETCOMBINEDBITS
   EOR #$80
   ASL
   PHP

   JSR GETNIBBLE                        ; get nibble into bits 0-3 (for offset bits 1-4)
   PLP                                  ; merge Z bit as the carry bit (for offset bit 0)
   ROL                                  ; nibble -> bits 1-4; carry(!Z bit) -> bit 0 ; carry cleared
DECOMPRESSION_DONE
   RTS

GETNIBBLE
NIBBLES = *+1
   LDA #$AA
   LSR NIBCOUNT
   BCC NEED_NIBBLES
   AND #$0F                             ; isolate low 4 bits of nibble
   RTS

NEED_NIBBLES
   INC NIBCOUNT
   JSR GETSRC                           ; get 2 nibbles
   STA NIBBLES
   LSR 
   LSR 
   LSR 
   LSR 
   SEC
   RTS

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

