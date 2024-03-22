;  unlzsa2b.s - 6809 backward decompression routine for raw LZSA2 - 171 bytes
;  compress with lzsa -f2 -r -b <original_file> <compressed_file>
;
;  in:  x = last byte of compressed data
;       y = last byte of decompression buffer
;  out: y = first byte of decompressed data
;
;  Copyright (C) 2020 Emmanuel Marty
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

decompress_lzsa2
         clr <lz2nibct,pcr ; reset nibble available flag
         leax 1,x
         leay 1,y

lz2token ldb ,-x           ; load next token into B: XYZ|LL|MMM
         pshs b            ; save it

         andb #$18         ; isolate LLL (embedded literals count) in B
         beq lz2nolt       ; skip if no literals
         cmpb #$18         ; LITERALS_RUN_LEN_V2?
         bne lz2declt      ; if not, we have the complete count, go unshift

         bsr lz2nibl       ; get extra literals length nibble in B
         addb #$03         ; add LITERALS_RUN_LEN_V2
         cmpb #$12         ; LITERALS_RUN_LEN_V2 + 15 ?
         bne lz2gotla      ; if not, we have the full literals count, go copy

         addb ,-x          ; add extra literals count byte + LITERALS_RUN_LEN + 15
         bcc lz2gotla      ; if no overflow, we got the complete count, copy

         ldd ,--x          ; load 16 bit count in D (low part in B, high in A)
         bra lz2gotlt      ; we now have the complete count, go copy

lz2declt lsrb              ; shift literals count into place
         lsrb
         lsrb
lz2gotla clra              ; clear A (high part of literals count)

lz2gotlt leau ,x
         tfr d,x           ; transfer 16-bit count into X
lz2cpylt lda ,-u           ; copy literal byte
         sta ,-y
         leax -1,x         ; decrement X and update Z flag
         bne lz2cpylt      ; loop until all literal bytes are copied
         leax ,u

lz2nolt  ldb ,s            ; get token again, don't pop it from the stack

         lslb              ; push token's X flag bit into carry
         bcs lz2replg      ; if token's X bit is set, rep or large offset

         lslb              ; push token's Y flag bit into carry
         sex               ; push token's Z flag bit into reg A (carry flag is not effected)
         bcs lz2offs9      ; if token's Y bit is set, 9 bits offset

         bsr lz2nibl       ; get offset nibble in B
         lsla              ; retrieve token's Z flag bit and push into carry

         rolb              ; shift Z flag from carry into bit 0 of B
         eorb #$e1         ; set bits 5-7 of offset, reverse bit 0
         sex               ; set bits 8-15 of offset to $FF
         bra lz2gotof

lz2offs9 deca              ; set bits 9-15 of offset, reverse bit 8
         bra lz2lowof

lz2nibct fcb $00           ; nibble ready flag

lz2nibl  ldb #$aa
         com <lz2nibct,pcr ; toggle nibble ready flag and check
         bpl lz2gotnb

         ldb ,-x           ; load two nibbles
         stb <lz2nibl+1,pcr ; store nibble for next time (low 4 bits)

         lsrb              ; shift 4 high bits of nibble down
         lsrb
         lsrb
         lsrb

lz2gotnb andb #$0f         ; only keep low 4 bits
lz2done  rts

lz2replg lslb              ; push token's Y flag bit into carry
         bcs lz2rep16      ; if token's Y bit is set, rep or 16 bit offset

         sex               ; push token's Z flag bit into reg A
         bsr lz2nibl       ; get offset nibble in B
         lsla              ; retrieve token's Z flag bit and push into carry

         rolb              ; shift Z flag from carry into bit 0 of B
         eorb #$e1         ; set bits 13-15 of offset, reverse bit 8
         tfr b,a           ; copy bits 8-15 of offset into A
         suba #$02         ; substract 512 from offset
         bra lz2lowof

lz2rep16 bmi lz2repof      ; if token's Z flag bit is set, rep match

         lda ,-x           ; load high 8 bits of (negative, signed) offset
lz2lowof ldb ,-x           ; load low 8 bits of offset

lz2gotof nega              ; reverse sign of offset in D
         negb
         sbca #0
         std <lz2repof+2,pcr ; store match offset

lz2repof leau $aaaa,y      ; put backreference start address in U (dst+offset)

         ldd #$0007        ; clear MSB match length and set mask for MMM
         andb ,s+          ; isolate MMM (embedded match length) in token

         addb #$02         ; add MIN_MATCH_SIZE_V2
         cmpb #$09         ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2?
         bne lz2gotln      ; no, we have the full match length, go copy

         bsr lz2nibl       ; get offset nibble in B
         addb #$09         ; add MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2
         cmpb #$18         ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15?
         bne lz2gotln      ; if not, we have the full match length, go copy

         addb ,-x          ; add extra length byte + MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15
         bcc lz2gotln      ; if no overflow, we have the full length
         beq lz2done       ; detect EOD code

         ldd ,--x          ; load 16-bit len in D (low part in B, high in A)

lz2gotln pshs x            ; save source compressed data pointer
         tfr d,x           ; copy match length to X

lz2cpymt lda ,-u           ; copy matched byte
         sta ,-y
         leax -1,x         ; decrement X
         bne lz2cpymt      ; loop until all matched bytes are copied

         puls x            ; restore source compressed data pointer
         lbra lz2token     ; go decode next token
