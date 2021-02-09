; ***************************************************************************
; ***************************************************************************
;
; lzsa2_6502.s
;
; NMOS 6502 decompressor for data stored in Emmanuel Marty's LZSA2 format.
;
; This code is written for the ACME assembler.
;
; Optional code is presented for two minor 6502 optimizations that break
; compatibility with the current LZSA2 format standard.
;
; The code is 241 bytes for the small version, and 267 bytes for the normal.
;
; Copyright John Brandwood 2019.
;
; Distributed under the Boost Software License, Version 1.0.
; (See accompanying file LICENSE_1_0.txt or copy at
;  http://www.boost.org/LICENSE_1_0.txt)
;
; ***************************************************************************
; ***************************************************************************



; ***************************************************************************
; ***************************************************************************
;
; Decompression Options & Macros
;

                ;
                ; Choose size over space (within sane limits)?
                ;

LZSA_SMALL_SIZE =       0

                ;
                ; Remove code inlining to save space?
                ;
                ; This saves 15 bytes of code at the cost of 7% speed.
                ;

                !if      LZSA_SMALL_SIZE {
LZSA_NO_INLINE  =       1
                } else {
LZSA_NO_INLINE  =       0
                }

                ;
                ; Use smaller code for copying literals?
                ;
                ; This saves 11 bytes of code at the cost of 5% speed.
                ;

                !if      LZSA_SMALL_SIZE {
LZSA_SHORT_CP   =       1
                } else {
LZSA_SHORT_CP   =       0
                }

                ;
                ; We will read from or write to $FFFF.  This prevents the
                ; use of the "INC ptrhi / BNE" trick and reduces speed.
                ;

LZSA_USE_FFFF  =        0

                ;
                ; Macro to increment the source pointer to the next page.
                ;

                !macro LZSA_INC_PAGE {
                        inc     <lzsa_srcptr + 1
                }

                ;
                ; Macro to read a byte from the compressed source data.
                ;

                !if     LZSA_NO_INLINE {

                        !macro  LZSA_GET_SRC {
                        jsr     lzsa2_get_byte
                        }

                } else {

                        !macro  LZSA_GET_SRC {
                        lda     (lzsa_srcptr),y
                        inc     <lzsa_srcptr + 0
                        bne     .skip
                        +LZSA_INC_PAGE
.skip:
                        }

                }

                ;
                ; Macro to speed up reading 50% of nibbles.
                ;
                ; This seems to save very few cycles compared to the
                ; increase in code size, and it isn't recommended.
                ;

LZSA_SLOW_NIBL  =       1

                !if     (LZSA_SLOW_NIBL + LZSA_SMALL_SIZE) {

                        !macro  LZSA_GET_NIBL {
                        jsr     lzsa2_get_nibble        ; Always call a function.
                        }

                } else {

                        !macro  LZSA_GET_NIBL {
                        lsr     <lzsa_nibflg            ; Is there a nibble waiting?
                        lda     <lzsa_nibble            ; Extract the lo-nibble.
                        bcs     .skip
                        jsr     lzsa2_new_nibble        ; Extract the hi-nibble.
.skip:                  ora     #$F0
                        }

                }



; ***************************************************************************
; ***************************************************************************
;
; Data usage is last 11 bytes of zero-page.
;

lzsa_cmdbuf     =       $F5                     ; 1 byte.
lzsa_nibflg     =       $F6                     ; 1 byte.
lzsa_nibble     =       $F7                     ; 1 byte.
lzsa_offset     =       $F8                     ; 1 word.
lzsa_winptr     =       $FA                     ; 1 word.
lzsa_srcptr     =       $FC                     ; 1 word.
lzsa_dstptr     =       $FE                     ; 1 word.

lzsa_length     =       lzsa_winptr             ; 1 word.

LZSA_SRC_LO     =       $FC
LZSA_SRC_HI     =       $FD
LZSA_DST_LO     =       $FE
LZSA_DST_HI     =       $FF



; ***************************************************************************
; ***************************************************************************
;
; lzsa2_unpack - Decompress data stored in Emmanuel Marty's LZSA2 format.
;
; Args: lzsa_srcptr = ptr to compessed data
; Args: lzsa_dstptr = ptr to output buffer
; Uses: lots!
;

DECOMPRESS_LZSA2_FAST:
lzsa2_unpack:   ldy     #0                      ; Initialize source index.
                sty     <lzsa_nibflg            ; Initialize nibble buffer.

                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) = 0 {

                beq     .cp_length              ; always taken
.incsrc1:
                inc     <lzsa_srcptr + 1
                bne     .resume_src1            ; always taken

                !if     LZSA_SHORT_CP {
.incsrc2:
                inc     <lzsa_srcptr + 1
                bne     .resume_src2            ; always taken

.incdst:
                inc     <lzsa_dstptr + 1
                bne     .resume_dst             ; always taken

                }

                }

                ;
                ; Copy bytes from compressed source data.
                ;

.cp_length:     ldx     #$00                    ; Hi-byte of length or offset.

                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) {

                +LZSA_GET_SRC

                } else {

                lda     (lzsa_srcptr),y
                inc     <lzsa_srcptr + 0
                beq     .incsrc1

                }

.resume_src1:
                sta     <lzsa_cmdbuf            ; Preserve this for later.
                and     #$18                    ; Extract literal length.
                beq     .lz_offset              ; Skip directly to match?

                lsr                             ; Get 2-bit literal length.
                lsr
                lsr
                cmp     #$03                    ; Extended length?
                bne     .got_cp_len

                jsr     .get_length             ; X=0 table index for literals.

                !if     LZSA_SHORT_CP {

.got_cp_len:    cmp     #0                      ; Check the lo-byte of length.
                beq     .put_cp_len

                inx                             ; Increment # of pages to copy.

.put_cp_len:    stx     <lzsa_length
                tax

.cp_page:       lda     (lzsa_srcptr),y
                sta     (lzsa_dstptr),y
                inc     <lzsa_srcptr + 0

                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) {

                bne     .skip1
                inc     <lzsa_srcptr + 1
.skip1:         inc     <lzsa_dstptr + 0
                bne     .skip2
                inc     <lzsa_dstptr + 1
.skip2:

                } else {

                beq     .incsrc2
.resume_src2:
                inc     <lzsa_dstptr + 0
                beq     .incdst
.resume_dst:

                }

                dex
                bne     .cp_page
                dec     <lzsa_length            ; Any full pages left to copy?
                bne     .cp_page

                } else {

.got_cp_len:    tay                             ; Check the lo-byte of length.
                beq     .cp_page

                inx                             ; Increment # of pages to copy.

.get_cp_src:    clc                             ; Calc address of partial page.
                adc     <lzsa_srcptr + 0
                sta     <lzsa_srcptr + 0
                bcs     .get_cp_dst
                dec     <lzsa_srcptr + 1

.get_cp_dst:    tya
                clc                             ; Calc address of partial page.
                adc     <lzsa_dstptr + 0
                sta     <lzsa_dstptr + 0
                bcs     .get_cp_idx
                dec     <lzsa_dstptr + 1

.get_cp_idx:    tya                             ; Negate the lo-byte of length.
                eor     #$FF
                tay
                iny

.cp_page:       lda     (lzsa_srcptr),y
                sta     (lzsa_dstptr),y
                iny
                bne     .cp_page
                inc     <lzsa_srcptr + 1
                inc     <lzsa_dstptr + 1
                dex                             ; Any full pages left to copy?
                bne     .cp_page

                }

                ; ================================
                ; xyz  
                ; 00z  5-bit offset
                ; 01z  9-bit offset
                ; 10z  13-bit offset
                ; 110  16-bit offset
                ; 111  repeat offset

.lz_offset:     lda     <lzsa_cmdbuf
                asl
                bcs     .get_13_16_rep
                asl
                bcs     .get_9_bits

.get_5_bits:    dex                             ; X=$FF
.get_13_bits:   asl
                php
                +LZSA_GET_NIBL                  ; Always returns with CS.
                plp
                rol                             ; Shift into position, set C.
                eor     #$01
                cpx     #$00                    ; X=$FF for a 5-bit offset.
                bne     .set_offset
                sbc     #2                      ; Subtract 512 because 13-bit
                                                ; offset starts at $FE00.
                bne     .get_low8x              ; Always NZ from previous SBC.

.get_9_bits:    dex                             ; X=$FF if CS, X=$FE if CC.
                asl
                bcc     .get_low8
                dex
                bcs     .get_low8               ; Always VS from previous BIT.

.get_13_16_rep: asl
                bcc     .get_13_bits            ; Shares code with 5-bit path.

.get_16_rep:    bmi     .lz_length              ; Repeat previous offset.

                ;
                ; Copy bytes from decompressed window.
                ;
                ; N.B. X=0 is expected and guaranteed when we get here.
                ;

.get_16_bits:   jsr     lzsa2_get_byte          ; Get hi-byte of offset.

.get_low8x:     tax

.get_low8:
                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) {

                +LZSA_GET_SRC                   ; Get lo-byte of offset.

                } else {

                lda     (lzsa_srcptr),y
                inc     <lzsa_srcptr + 0
                beq     .incsrc3
.resume_src3:

                }

.set_offset:    stx     <lzsa_offset + 1        ; Save new offset.
                sta     <lzsa_offset + 0

.lz_length:     ldx     #$00                    ; Hi-byte of length.

                lda     <lzsa_cmdbuf
                and     #$07
                clc
                adc     #$02
                cmp     #$09                    ; Extended length?
                bne     .got_lz_len

                inx
                jsr     .get_length             ; X=1 table index for match.

.got_lz_len:    eor     #$FF                    ; Negate the lo-byte of length
                tay                             ; and check for zero.
                iny
                beq     .calc_lz_addr
                eor     #$FF

                inx                             ; Increment # of pages to copy.

                clc                             ; Calc destination for partial
                adc     <lzsa_dstptr + 0        ; page.
                sta     <lzsa_dstptr + 0
                bcs     .calc_lz_addr
                dec     <lzsa_dstptr + 1

.calc_lz_addr:  clc                             ; Calc address of match.
                lda     <lzsa_dstptr + 0        ; N.B. Offset is negative!
                adc     <lzsa_offset + 0
                sta     <lzsa_winptr + 0
                lda     <lzsa_dstptr + 1
                adc     <lzsa_offset + 1
                sta     <lzsa_winptr + 1

.lz_page:       lda     (lzsa_winptr),y
                sta     (lzsa_dstptr),y
                iny
                bne     .lz_page
                inc     <lzsa_winptr + 1
                inc     <lzsa_dstptr + 1
                dex                             ; Any full pages left to copy?
                bne     .lz_page

                jmp     .cp_length              ; Loop around to the beginning.

                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) = 0 {

.incsrc3:
                inc     <lzsa_srcptr + 1
                bne     .resume_src3            ; always taken

                }

                ;
                ; Lookup tables to differentiate literal and match lengths.
                ;

.nibl_len_tbl:  !byte   3 + $10                 ; 0+3 (for literal).
                !byte   9 + $10                 ; 2+7 (for match).

.byte_len_tbl:  !byte   18 - 1                  ; 0+3+15 - CS (for literal).
                !byte   24 - 1                  ; 2+7+15 - CS (for match).

                ;
                ; Get 16-bit length in X:A register pair.
                ;

.get_length:    +LZSA_GET_NIBL
                cmp     #$FF                    ; Extended length?
                bcs     .byte_length
                adc     .nibl_len_tbl,x         ; Always CC from previous CMP.

.got_length:    ldx     #$00                    ; Set hi-byte of 4 & 8 bit
                rts                             ; lengths.

.byte_length:   jsr     lzsa2_get_byte          ; So rare, this can be slow!
                adc     .byte_len_tbl,x         ; Always CS from previous CMP.
                bcc     .got_length
                beq     .finished

.word_length:   jsr     lzsa2_get_byte          ; So rare, this can be slow!
                pha
                jsr     lzsa2_get_byte          ; So rare, this can be slow!
                tax
                pla
                rts

lzsa2_get_byte: 
                lda     (lzsa_srcptr),y         ; Subroutine version for when
                inc     <lzsa_srcptr + 0        ; inlining isn't advantageous.
                beq     lzsa2_next_page
                rts

lzsa2_next_page:
                inc     <lzsa_srcptr + 1        ; Inc & test for bank overflow.
                rts

.finished:      pla                             ; Decompression completed, pop
                pla                             ; return address.
                rts

                ;
                ; Get a nibble value from compressed data in A.
                ;

                !if     (LZSA_SLOW_NIBL | LZSA_SMALL_SIZE) {

lzsa2_get_nibble:
                lsr     <lzsa_nibflg            ; Is there a nibble waiting?
                lda     <lzsa_nibble            ; Extract the lo-nibble.
                bcs     .got_nibble

                inc     <lzsa_nibflg            ; Reset the flag.
                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) {

                +LZSA_GET_SRC

                } else {

                lda     (lzsa_srcptr),y
                inc     <lzsa_srcptr + 0
                beq     .incsrc4
.resume_src4:

                }

                sta     <lzsa_nibble            ; Preserve for next time.
                lsr                             ; Extract the hi-nibble.
                lsr
                lsr
                lsr

.got_nibble:    ora     #$F0
                rts

                } else {

lzsa2_new_nibble:
                inc     <lzsa_nibflg            ; Reset the flag.
                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) {

                +LZSA_GET_SRC

                } else {

                lda     (lzsa_srcptr),y
                inc     <lzsa_srcptr + 0
                beq     .incsrc4
.resume_src4:

                }

                sta     <lzsa_nibble            ; Preserve for next time.
                lsr                             ; Extract the hi-nibble.
                lsr
                lsr
                lsr
                rts

                }

                !if     (LZSA_NO_INLINE | LZSA_USE_FFFF) = 0 {

.incsrc4:
                inc     <lzsa_srcptr + 1
                bne     .resume_src4            ; always taken

                }
