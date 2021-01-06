; ***************************************************************************
; ***************************************************************************
;
; lzsa1_6502.s
;
; NMOS 6502 decompressor for data stored in Emmanuel Marty's LZSA1 format.
;
; This code is written for the ACME assembler.
;
; Optional code is presented for one minor 6502 optimization that breaks
; compatibility with the current LZSA1 format standard.
;
; The code is 168 bytes for the small version, and 205 bytes for the normal.
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

                !if     LZSA_SMALL_SIZE {
LZSA_NO_INLINE  =       1
                } else {
LZSA_NO_INLINE  =       0
                }

                ;
                ; Use smaller code for copying literals?
                ;
                ; This saves 11 bytes of code at the cost of 15% speed.
                ;

                !if     LZSA_SMALL_SIZE {
LZSA_SHORT_CP   =       1
                } else {
LZSA_SHORT_CP   =       0
                }

                ;
                ; Use smaller code for copying literals?
                ;
                ; This saves 11 bytes of code at the cost of 30% speed.
                ;

                !if     LZSA_SMALL_SIZE {
LZSA_SHORT_LZ   =       1
                } else {
LZSA_SHORT_LZ   =       0
                }

                ;
                ; Macro to increment the source pointer to the next page.
                ;
                ; This should call a subroutine to determine if a bank
                ; has been crossed, and a new bank should be paged in.
                ;

                !macro  LZSA_INC_PAGE {
                        inc     <lzsa_srcptr + 1
                }

                ;
                ; Macro to read a byte from the compressed source data.
                ;

                !if     LZSA_NO_INLINE {

                        !macro LZSA_GET_SRC {
                        jsr     lzsa1_get_byte
                        }

                } else {

                        !macro LZSA_GET_SRC {
                        lda     (lzsa_srcptr),y
                        inc     <lzsa_srcptr + 0
                        bne     .skip
                        +LZSA_INC_PAGE
.skip:
                        }

                }



; ***************************************************************************
; ***************************************************************************
;
; Data usage is last 8 bytes of zero-page.
;

                !if     (LZSA_SHORT_CP | LZSA_SHORT_LZ) {
lzsa_length     =       $F8                     ; 1 byte.
                }

lzsa_cmdbuf     =       $F9                     ; 1 byte.
lzsa_winptr     =       $FA                     ; 1 word.
lzsa_srcptr     =       $FC                     ; 1 word.
lzsa_dstptr     =       $FE                     ; 1 word.

LZSA_SRC_LO     =       $FC
LZSA_SRC_HI     =       $FD
LZSA_DST_LO     =       $FE
LZSA_DST_HI     =       $FF


; ***************************************************************************
; ***************************************************************************
;
; lzsa1_unpack - Decompress data stored in Emmanuel Marty's LZSA1 format.
;
; Args: lzsa_srcptr = ptr to compessed data
; Args: lzsa_dstptr = ptr to output buffer
; Uses: lots!
;

DECOMPRESS_LZSA1_FAST:
lzsa1_unpack:   ldy     #0                      ; Initialize source index.
                ldx     #0                      ; Initialize hi-byte of length.

                ;
                ; Copy bytes from compressed source data.
                ;
                ; N.B. X=0 is expected and guaranteed when we get here.
                ;

.cp_length:     +LZSA_GET_SRC
                sta     <lzsa_cmdbuf            ; Preserve this for later.
                and     #$70                    ; Extract literal length.
                beq     .lz_offset              ; Skip directly to match?

                lsr                             ; Get 3-bit literal length.
                lsr
                lsr
                lsr
                cmp     #$07                    ; Extended length?
                bne     .got_cp_len

                jsr     .get_length             ; CS from CMP, X=0.

                !if     LZSA_SHORT_CP {

.got_cp_len:    cmp     #0                      ; Check the lo-byte of length.
                beq     .put_cp_len

                inx                             ; Increment # of pages to copy.

.put_cp_len:    stx     <lzsa_length
                tax

.cp_page:       lda     (lzsa_srcptr),y
                sta     (lzsa_dstptr),y
                inc     <lzsa_srcptr + 0
                bne     .skip1
                inc     <lzsa_srcptr + 1
.skip1:         inc     <lzsa_dstptr + 0
                bne     .skip2
                inc     <lzsa_dstptr + 1
.skip2:         dex
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

                ;
                ; Copy bytes from decompressed window.
                ;
                ; N.B. X=0 is expected and guaranteed when we get here.
                ;

.lz_offset:     +LZSA_GET_SRC
                clc
                adc     <lzsa_dstptr + 0
                sta     <lzsa_winptr + 0

                lda     #$FF
                bit     <lzsa_cmdbuf
                bpl     .hi_offset
                +LZSA_GET_SRC

.hi_offset:     adc     <lzsa_dstptr + 1
                sta     <lzsa_winptr + 1

.lz_length:     lda     <lzsa_cmdbuf            ; X=0 from previous loop.
                and     #$0F
                adc     #$03 - 1                ; CS from previous ADC.
                cmp     #$12                    ; Extended length?
                bne     .got_lz_len

                jsr     .get_length             ; CS from CMP, X=0.

                !if     LZSA_SHORT_LZ {

.got_lz_len:    cmp     #0                      ; Check the lo-byte of length.
                beq     .put_lz_len

                inx                             ; Increment # of pages to copy.

.put_lz_len:    stx     <lzsa_length
                tax

.lz_page:       lda     (lzsa_winptr),y
                sta     (lzsa_dstptr),y
                inc     <lzsa_winptr + 0
                bne     .skip3
                inc     <lzsa_winptr + 1
.skip3:         inc     <lzsa_dstptr + 0
                bne     .skip4
                inc     <lzsa_dstptr + 1
.skip4:         dex
                bne     .lz_page
                dec     <lzsa_length            ; Any full pages left to copy?
                bne     .lz_page

                jmp     .cp_length              ; Loop around to the beginning.

                } else {

.got_lz_len:    tay                             ; Check the lo-byte of length.
                beq     .lz_page

                inx                             ; Increment # of pages to copy.

.get_lz_win:    clc                             ; Calc address of partial page.
                adc     <lzsa_winptr + 0
                sta     <lzsa_winptr + 0
                bcs     .get_lz_dst
                dec     <lzsa_winptr + 1

.get_lz_dst:    tya
                clc                             ; Calc address of partial page.
                adc     <lzsa_dstptr + 0
                sta     <lzsa_dstptr + 0
                bcs     .get_lz_idx
                dec     <lzsa_dstptr + 1

.get_lz_idx:    tya                             ; Negate the lo-byte of length.
                eor     #$FF
                tay
                iny

.lz_page:       lda     (lzsa_winptr),y
                sta     (lzsa_dstptr),y
                iny
                bne     .lz_page
                inc     <lzsa_winptr + 1
                inc     <lzsa_dstptr + 1
                dex                             ; Any full pages left to copy?
                bne     .lz_page

                jmp     .cp_length              ; Loop around to the beginning.

                }

                ;
                ; Get 16-bit length in X:A register pair.
                ;
                ; N.B. X=0 is expected and guaranteed when we get here.
                ;

.get_length:    clc                             ; Add on the next byte to get
                adc     (lzsa_srcptr),y         ; the length.
                inc     <lzsa_srcptr + 0
                bne     .skip_inc
                +LZSA_INC_PAGE

.skip_inc:      bcc     .got_length             ; No overflow means done.
                cmp     #$00                    ; Overflow to 256 or 257?
                beq     .extra_word

.extra_byte:    inx
                jmp     lzsa1_get_byte          ; So rare, this can be slow!

.extra_word:    jsr     lzsa1_get_byte          ; So rare, this can be slow!
                pha
                jsr     lzsa1_get_byte          ; So rare, this can be slow!
                tax
                beq     .finished               ; Length-hi == 0 at EOF.
                pla                             ; Length-lo.
                rts

lzsa1_get_byte:
                lda     (lzsa_srcptr),y         ; Subroutine version for when
                inc     <lzsa_srcptr + 0        ; inlining isn't advantageous.
                beq     lzsa1_next_page
.got_length:    rts

lzsa1_next_page:
                inc     <lzsa_srcptr + 1        ; Inc & test for bank overflow.
                rts

.finished:      pla                             ; Length-lo.
                pla                             ; Decompression completed, pop
                pla                             ; return address.
                rts
