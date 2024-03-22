;  unlzsa1-6309.s - Hitachi 6309 decompression routine for raw LZSA1 - 92 bytes
;  compress with lzsa -f1 -r <original_file> <compressed_file>
;
;  in:  x = start of compressed data
;       y = start of decompression buffer
;  out: y = end of decompression buffer + 1
;
;  Copyright (C) 2020 Emmanuel Marty, Doug Masten
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

decompress_lzsa1 equ lz1token

lz1bigof lda ,x+           ; O set: load MSB 16-bit (negative, signed) offest
lz1gotof leau d,y          ; put backreference start address in U (dst+offset)

         ldd #$000f        ; clear MSB match length and set mask for MMMM
         andb ,s+          ; isolate MMMM (embedded match length) in token
         addb #$03         ; add MIN_MATCH_SIZE
         cmpb #$12         ; MATCH_RUN_LEN?
         bne lz1gotln      ; no, we have the full match length, go copy

         addb ,x+          ; add extra match length byte + MIN_MATCH_SIZE + MATCH_RUN_LEN
         bcc lz1gotln      ; if no overflow, we have the full length
         bne lz1midln

         ldb ,x+           ; load 16-bit len in D (low part in B, high in A)
         lda ,x+           ; (little endian)
         bne lz1gotln      ; check if we hit EOD (16-bit length = 0)
         tstb
         bne lz1gotln      ; go copy matched bytes if not

         rts               ; done, bail

lz1midln tfr b,a           ; copy high part of len into A
         ldb ,x+           ; grab low 8 bits of len in B

lz1gotln tfr d,w           ; set W with match length for TFM instruction
         tfm u+,y+         ; copy match bytes

lz1token ldb ,x+           ; load next token into B: O|LLL|MMMM
         pshs b            ; save it

         andb #$70         ; isolate LLL (embedded literals count) in B
         beq lz1nolt       ; skip if no literals
         cmpb #$70         ; LITERALS_RUN_LEN?
         bne lz1declt      ; if not, we have the complete count, go unshift

         ldb ,x+           ; load extra literals count byte
         addb #$07         ; add LITERALS_RUN_LEN
         bcc lz1gotla      ; if no overflow, we got the complete count, copy
         bne lz1midlt

         ldb ,x+           ; load low 8 bits of little-endian literals count
         lda ,x+           ; load high 8 bits of literal count
         bra lz1gotlt      ; we now have the complete count, go copy

lz1midlt tfr b,a           ; copy high part of literals count into A
         ldb ,x+           ; load low 8 bits of literals count
         bra lz1gotlt      ; we now have the complete count, go copy

lz1declt lsrb              ; shift literals count into place
         lsrb
         lsrb
         lsrb

lz1gotla clra              ; clear A (high part of literals count)
lz1gotlt tfr d,w           ; set W with literals count for TFM instruction
         tfm x+,y+         ; copy literal bytes

lz1nolt  ldb ,x+           ; load either 8-bit or LSB 16-bit offset (negative, signed)
         lda ,s            ; get token again, don't pop it from the stack
         bmi lz1bigof      ; test O bit (small or large offset)

         lda #$ff          ; set high 8 bits
         bra lz1gotof
