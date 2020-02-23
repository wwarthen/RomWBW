; lzsa1fta.asm time-efficient decompressor implementation for 808x CPUs.
; Turbo Assembler IDEAL mode dialect.
; (Is supposed to also assemble with NASM's IDEAL mode support, but YMMV.)
;
; This code assembles to about 3K of lookup tables and unrolled code,
; but the tradeoff for that size is the absolute fastest decompressor
; of LZSA1 block data for 808x CPUs.
; If you need moderately fast code with less size, see LZSA1FTA.ASM.
; If you need the smallest decompression code, see decompress_small_v1.S.
;
; Usual DOS assembler SMALL model assumptions apply.  This code:
; - Assumes it was invoked via NEAR call (change RET to RETF for FAR calls)
; - Is interrupt-safe
; - Is not re-entrant (do not decompress while already running decompression)
; - Trashes all data and segment registers
;
; Copyright (C) 2019 Jim Leonard, Emmanuel Marty
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;
; ===========================================================================
;
; The key area to concentrate on when optimizing LZSA1 decompression speed is
; reducing time spent handling the shortest matches. This is for two reasons:
;   1. shorter matches are more common
;   2. short matches are least efficient in terms of decomp speed per byte
; You can confirm #1 using the --stats mode of the compressor.
;
; Branches are costly on 8086.  To ensure we branch as little as possible, a
; jumptable will be used to branch directly to as many direct decode paths as
; possible.  This will burn up 512 bytes of RAM for a jumptable, and a few
; hundred bytes of duplicated program code (rather than JMP/CALL common code
; blocks, we inline them to avoid the branch overhead).
;
; ===========================================================================
;
; === LZSA1 block reference:
;
; Blocks encoded as LZSA1 are composed from consecutive commands.
; Each command follows this format:
;
; token: <O|LLL|MMMM>
; optional extra literal length
; literal values
; match offset low
; optional match offset high
; optional extra encoded match length
;
;
; === LZSA1 Token Reference:
;
; 7 6 5 4 3 2 1 0
; O L L L M M M M
;
; L: 3-bit literals length (0-6, or 7 if extended). If the number of literals for
; this command is 0 to 6, the length is encoded in the token and no extra bytes
; are required. Otherwise, a value of 7 is encoded and extra bytes follow as
; 'optional extra literal length'
;
; M: 4-bit encoded match length (0-14, or 15 if extended). Likewise, if the
; encoded match length for this command is 0 to 14, it is directly stored,
; otherwise 15 is stored and extra bytes follow as 'optional extra encoded match
; length'. Except for the last command in a block, a command always contains a
; match, so the encoded match length is the actual match length, offset by the
; minimum which is 3 bytes. For instance, an actual match length of 10 bytes to
; be copied, is encoded as 7.
;
; O: set for a 2-bytes match offset, clear for a 1-byte match offset
;
;
; === Decoding extended literal length:
;
; If the literals length is 7 or more, then an extra byte follows here, with
; three possible values:
;
;   0-248: the value is added to the 7 stored in the token.
;   250: a second byte follows. The final literals value is 256 + the second byte.
;   249: a little-endian 16-bit value follows, forming the final literals value.
;
;
; === Decoding match offsets:
;
; match offset low: The low 8 bits of the match offset follows.
;
; optional match offset high: If the 'O' bit (bit 7) is set in the token, the
; high 8 bits of the match offset follow, otherwise they are understood to be all
; set to 1. For instance, a short offset of 0x70 is interpreted as 0xff70
;
;
; === Decoding extra encoded match length:
;
; optional extra encoded match length: If the encoded match length is 15 or more,
; the 'M' bits in the token form the value 15, and an extra byte follows here,
; with three possible types of value.
;
;  0-237: the value is added to the 15 stored in the token. The final value is 3 + 15 + this byte.
;  239:   a second byte follows. The final match length is 256 + the second byte.
;  238:   a second and third byte follow, forming a little-endian 16-bit value.
;         The final encoded match length is that 16-bit value.
;
; ===========================================================================

        IDEAL   ; Use Turbo Assembler IDEAL syntax checking
        P8086   ; Restrict code generation to the 808x and later
        JUMPS   ; Perform fixups for out-of-bound conditional jumps
                ; This is required for the (L=07 & M=0Fh) decode paths as they
                ; have the most code, but these are uncommon paths so the
                ; tiny speed loss in just these paths is not a concern.

SEGMENT CODE para public

ASSUME  cs:CODE, ds:CODE

PUBLIC  lzsa1_decompress_speed_jumptable

; EQU helper statements (so we can construct a jump table without going crazy)

minmatch EQU 3
litrunlen EQU 7

leml1 EQU OFFSET lit_ext_mat_len_1b
leme1 EQU OFFSET lit_ext_mat_ext_1b
leml2 EQU OFFSET lit_ext_mat_len_2b
leme2 EQU OFFSET lit_ext_mat_ext_2b

;short-circuit special cases for 0 through 6 literal copies:
l6ml1 EQU OFFSET lit_len_mat_len_1b
l6me1 EQU OFFSET lit_len_mat_ext_1b
l6ml2 EQU OFFSET lit_len_mat_len_2b
l6me2 EQU OFFSET lit_len_mat_ext_2b
l5ml1 EQU OFFSET lit_len_mat_len_1b + 1
l5me1 EQU OFFSET lit_len_mat_ext_1b + 1
l5ml2 EQU OFFSET lit_len_mat_len_2b + 1
l5me2 EQU OFFSET lit_len_mat_ext_2b + 1
l4ml1 EQU OFFSET lit_len_mat_len_1b + 2
l4me1 EQU OFFSET lit_len_mat_ext_1b + 2
l4ml2 EQU OFFSET lit_len_mat_len_2b + 2
l4me2 EQU OFFSET lit_len_mat_ext_2b + 2
l3ml1 EQU OFFSET lit_len_mat_len_1b + 3
l3me1 EQU OFFSET lit_len_mat_ext_1b + 3
l3ml2 EQU OFFSET lit_len_mat_len_2b + 3
l3me2 EQU OFFSET lit_len_mat_ext_2b + 3
l2ml1 EQU OFFSET lit_len_mat_len_1b + 4
l2me1 EQU OFFSET lit_len_mat_ext_1b + 4
l2ml2 EQU OFFSET lit_len_mat_len_2b + 4
l2me2 EQU OFFSET lit_len_mat_ext_2b + 4
l1ml1 EQU OFFSET lit_len_mat_len_1b + 5
l1me1 EQU OFFSET lit_len_mat_ext_1b + 5
l1ml2 EQU OFFSET lit_len_mat_len_2b + 5
l1me2 EQU OFFSET lit_len_mat_ext_2b + 5
l0ml1 EQU OFFSET lit_len_mat_len_1b + 6 ; MMMM handling comes after LLL code
l0me1 EQU OFFSET lit_len_mat_ext_1b + 6 ; MMMM handling comes after LLL code
l0ml2 EQU OFFSET lit_len_mat_len_2b + 6 ; MMMM handling comes after LLL code
l0me2 EQU OFFSET lit_len_mat_ext_2b + 6 ; MMMM handling comes after LLL code

; === Hand-written (!) jumptable actually begins here.
; Located before the program code results in an extra JMP and 3 wasted bytes,
; but it makes the code easier to follow in this location.
; Relocate the jump table after the ENDP directive to save 3 bytes.
;
; 7 6 5 4 3 2 1 0
; O L L L M M M M
;
;         0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
jtbl DW l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0ml1,l0me1 ;0
     DW l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1ml1,l1me1 ;1
     DW l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2ml1,l2me1 ;2
     DW l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3ml1,l3me1 ;3
     DW l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4ml1,l4me1 ;4
     DW l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5ml1,l5me1 ;5
     DW l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6ml1,l6me1 ;6
     DW leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leml1,leme1 ;7
     DW l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0ml2,l0me2 ;8
     DW l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1ml2,l1me2 ;9
     DW l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2ml2,l2me2 ;a
     DW l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3ml2,l3me2 ;b
     DW l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4ml2,l4me2 ;c
     DW l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5ml2,l5me2 ;d
     DW l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6ml2,l6me2 ;e
     DW leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leml2,leme2 ;f

PROC    lzsa1_decompress_speed_jumptable  NEAR
; ---------------------------------------------------------------------------
; Decompress raw LZSA1 block
; inputs:
; * ds:si: raw LZSA1 block
; * es:di: output buffer
; output:
; * ax:    decompressed size
; ---------------------------------------------------------------------------

MACRO get_byte_match_offset
        mov     ah,0ffh         ;O=0, so set up offset's high byte
        lodsb                   ;load low byte; ax=match offset
        xchg    bp,ax           ;bp=match offset  ax=00 + original token
ENDM

MACRO get_word_match_offset
        lodsw                   ;ax=match offset
        xchg    bp,ax           ;bp=match offset  ax=00 + original token
ENDM

MACRO do_match_copy_long
LOCAL do_run, do_run_w
; Copies a long match as optimally as possible.
; requirements: cx=length, bp=negative offset, ds:si=compdata, es:di=output
; trashes: ax, bx
; must leave cx=0 at exit
        mov     bx,ds           ;save ds
        mov     ax,es
        mov     ds,ax           ;ds=es
        xchg    ax,si           ;save si
        lea     si,[bp+di]      ;si = output buffer + negative match offset
        cmp     bp,-2           ;do we have a byte/word run to optimize?
        jae     do_run          ;perform a run if so, otherwise fall through
;You may be tempted to change "jae" to "jge" because DX is a signed number.
;Don't!  The total window is 64k, so if you treat this as a signed comparison,
;you will get incorrect results for offsets over 32K.

;If we're here, we have a long copy and it isn't byte-overlapping (if it
;overlapped, we'd be in @@do_run)  So, let's copy faster with REP MOVSW.
;This affects 8088 only slightly, but is a bigger win on 8086 and higher.
        shr     cx,1
        rep     movsw
        adc     cl,0
        rep     movsb
        xchg    si,ax           ;restore si
        mov     ds,bx           ;restore ds
        jmp     decode_token

do_run:
        je      do_run_w        ;if applicable, handle word-sized value faster
        xchg    dx,ax           ;save si into dx, as ax is getting trashed
        lodsb                   ;load first byte of run into al
        mov     ah,al
        shr     cx,1
        rep     stosw           ;perform word run
        adc     cl,0
        rep     stosb           ;finish word run
        mov     si,dx           ;restore si
        mov     ds,bx           ;restore ds
        jmp     decode_token

do_run_w:
        xchg    dx,ax           ;save si into dx, as ax is getting trashed
        lodsw                   ;load first word of run
        shr     cx,1
        rep     stosw           ;perform word run
        adc     cl,0            ;despite 2-byte offset, compressor might
        rep     stosb           ;output odd length. better safe than sorry.
        mov     si,dx           ;restore si
        mov     ds,bx           ;restore ds
        jmp     decode_token
ENDM

MACRO do_match_copy
; Copies a shorter match with as little overhead as possible.
; requirements: cx=length, bp=negative offset, ds:si=compdata, es:di=output
; trashes: ax, bx
; must leave cx=0 at exit
        mov     bx,ds           ;save ds
        mov     ax,es
        mov     ds,ax           ;ds=es
        xchg    ax,si           ;save si
        lea     si,[bp+di]      ;si = output buffer + negative match offset
        rep     movsb
        xchg    si,ax           ;restore si
        mov     ds,bx           ;restore ds
        jmp     decode_token
ENDM

MACRO do_literal_copy
; Copies a literal sequence using words.
; Meant for longer lengths; for 128 bytes or less, use REP MOVSB.
; requirements: cx=length, ds:si=compdata, es:di=output
; must leave cx=0 at exit
        shr     cx,1
        rep     movsw
        adc     cl,0
        rep     movsb
ENDM

MACRO copy_small_match_len
        and     al,0FH          ;isolate length in token (MMMM)
        add     al,minmatch     ;ax=match length
        xchg    cx,ax           ;cx=match length
        do_match_copy           ;copy match with cx=length, bp=offset
ENDM

MACRO copy_large_match_len
LOCAL val239, val238, EOD
; Handle MMMM=Fh
; Assumptions: ah=0 from get_????_match_offset's xchg
        lodsb                   ;grab extra match length byte
        add     al,0Fh+minmatch ;add MATCH_RUN_LEN + MIN_MATCH_SIZE
        jz      val238          ;if zf & cf, 238: get 16-bit match length
        jc      val239          ;if cf,      239: get extra match length byte
        xchg    cx,ax           ;otherwise, we have our match length
        do_match_copy_long      ;copy match with cx=length, bp=offset
val239:
        lodsb                   ;ah=0; grab single extra length byte
        inc     ah              ;ax=256+length byte
        xchg    cx,ax
        do_match_copy_long      ;copy match with cx=length, bp=offset
val238:
        lodsw                   ;grab 16-bit length
        xchg    cx,ax
        jcxz    EOD             ;is it the EOD marker? Exit if so
        do_match_copy_long      ;copy match with cx=length, bp=offset
EOD:
        jmp     done_decompressing
ENDM


lzsa1_start:
        push    di              ;remember decompression offset
        cld                     ;ensure string ops move forward
        xor     cx,cx

decode_token:
        xchg    cx,ax           ;clear ah (cx = 0 from match copy's REP)
        lodsb                   ;read token byte: O|LLL|MMMM
        mov     bp,ax           ;preserve 0+token in bp for later MMMM handling
        mov     bx,ax           ;prep for table lookup
        shl     bx,1            ;adjust for offset word size
        jmp     [cs:jtbl+bx]    ;jump directly to relevant decode path

; There are eight basic decode paths for an LZSA1 token.  Each of these
; paths perform only the necessary actions to decode the token and then
; fetch the next token.  This results in a lot of code duplication, but
; it is the only way to get down to two branches per token (jump to unique
; decode path, then jump back to next token) for the most common cases.

; Path #1: LLL=0-6, MMMM=0-Eh, O=0 (1-byte match offset)
; Handle LLL=0-6 by jumping directly into # of bytes to copy (6 down to 1)
lit_len_mat_len_1b:
        movsb
        movsb
        movsb
        movsb
        movsb
        movsb
        get_byte_match_offset
        copy_small_match_len


; Path #2: LLL=0-6, MMMM=Fh,   O=0 (1-byte match offset)
lit_len_mat_ext_1b:
        movsb
        movsb
        movsb
        movsb
        movsb
        movsb
        get_byte_match_offset
        copy_large_match_len


; Path #3: LLL=7,   MMMM=0-Eh, O=0 (1-byte match offset)
lit_ext_mat_len_1b:
; on entry: ax=0 + token, bp=ax
        lodsb                   ;grab extra literal length byte
        add     al,litrunlen    ;add 7h literal run length
        jz      @@val249_3      ;if zf & cf, 249: get 16-bit literal length
        jc      @@val250_3      ;if cf,      250: get extra literal length byte
        xchg    cx,ax           ;otherwise, we have our literal length
        do_literal_copy         ;this might be better as rep movsw !!! benchmark
        get_byte_match_offset
        copy_small_match_len
@@val250_3:
        lodsb                   ;ah=0; grab single extra length byte
        inc     ah              ;ax=256+length byte
        xchg    cx,ax
        do_literal_copy
        get_byte_match_offset
        copy_small_match_len
@@val249_3:
        lodsw                   ;grab 16-bit length
        xchg    cx,ax
        do_literal_copy
        get_byte_match_offset
        copy_small_match_len


; Path #4: LLL=7,   MMMM=Fh,   O=0 (1-byte match offset)
lit_ext_mat_ext_1b:
; on entry: ax=0 + token, bp=ax
        lodsb                   ;grab extra literal length byte
        add     al,litrunlen    ;add 7h literal run length
        jz      @@val249_4      ;if zf & cf, 249: get 16-bit literal length
        jc      @@val250_4      ;if cf,      250: get extra literal length byte
        xchg    cx,ax           ;otherwise, we have our literal length
        do_literal_copy         ;this might be better as rep movsw !!! benchmark
        get_byte_match_offset
        copy_large_match_len
@@val250_4:
        lodsb                   ;ah=0; grab single extra length byte
        inc     ah              ;ax=256+length byte
        xchg    cx,ax
        do_literal_copy
        get_byte_match_offset
        copy_large_match_len
@@val249_4:
        lodsw                   ;grab 16-bit length
        xchg    cx,ax
        do_literal_copy
        get_byte_match_offset
        copy_large_match_len


; Path #5: LLL=0-6, MMMM=0-Eh, O=1 (2-byte match offset)
; Handle LLL=0-6 by jumping directly into # of bytes to copy (6 down to 1)
lit_len_mat_len_2b:
        movsb
        movsb
        movsb
        movsb
        movsb
        movsb
        get_word_match_offset
        copy_small_match_len


; Path #6: LLL=0-6, MMMM=Fh,   O=1 (2-byte match offset)
lit_len_mat_ext_2b:
        movsb
        movsb
        movsb
        movsb
        movsb
        movsb
        get_word_match_offset
        copy_large_match_len


; Path #7: LLL=7,   MMMM=0-Eh, O=1 (2-byte match offset)
lit_ext_mat_len_2b:
; on entry: ax=0 + token, bp=ax
        lodsb                   ;grab extra literal length byte
        add     al,litrunlen    ;add 7h literal run length
        jz      @@val249_7      ;if zf & cf, 249: get 16-bit literal length
        jc      @@val250_7      ;if cf,      250: get extra literal length byte
        xchg    cx,ax           ;otherwise, we have our literal length
        do_literal_copy         ;this might be better as rep movsw !!! benchmark
        get_word_match_offset
        copy_small_match_len
@@val250_7:
        lodsb                   ;ah=0; grab single extra length byte
        inc     ah              ;ax=256+length byte
        xchg    cx,ax
        do_literal_copy
        get_word_match_offset
        copy_small_match_len
@@val249_7:
        lodsw                   ;grab 16-bit length
        xchg    cx,ax
        do_literal_copy
        get_word_match_offset
        copy_small_match_len


; Path #8: LLL=7,   MMMM=Fh,   O=1 (2-byte match offset)
lit_ext_mat_ext_2b:
; on entry: ax=0 + token, bp=ax
        lodsb                   ;grab extra literal length byte
        add     al,litrunlen    ;add 7h literal run length
        jz      @@val249_8      ;if zf & cf, 249: get 16-bit literal length
        jc      @@val250_8      ;if cf,      250: get extra literal length byte
        xchg    cx,ax           ;otherwise, we have our literal length
        do_literal_copy         ;this might be better as rep movsw !!! benchmark
        get_word_match_offset
        copy_large_match_len
@@val250_8:
        lodsb                   ;ah=0; grab single extra length byte
        inc     ah              ;ax=256+length byte
        xchg    cx,ax
        do_literal_copy
        get_word_match_offset
        copy_large_match_len
@@val249_8:
        lodsw                   ;grab 16-bit length
        xchg    cx,ax
        do_literal_copy
        get_word_match_offset
        copy_large_match_len


done_decompressing:
;return # of decompressed bytes in ax
        pop     ax              ;retrieve the original decompression offset
        sub     di,ax           ;adjust for original offset
        xchg    di,ax           ;return adjusted value in ax
        ret                     ;done decompressing, exit to caller

ENDP    lzsa1_decompress_speed_jumptable

ENDS    CODE

END

;Speed optimization history (decompression times in microseconds @ 4.77 MHz):
; defer add MIN_MATCH_SIZE  shuttle  97207 alice 57200 robotron 362884 ++*
; jumptable rewrite, no RLE shuttle  97744 alice 46905 robotron 309032 -++
; adc cx,0 -> adc cl,0      shuttle  97744 alice 46893 robotron 309032 .+.!
; jumptable rewrite w/RLE   shuttle  88776 alice 50433 robotron 319222 +--
; short match copies movsb  shuttle  97298 alice 49769 robotron 326282 ---rb
; long match copy #1 16-bit shuttle  92490 alice 46905 robotron 308722 +*+
; long match copy #2 extraB shuttle  92464 alice 46905 robotron 308371 +.+
; long match copy #3 0f->ed shuttle  86765 alice 46864 robotron 303895 +++!
