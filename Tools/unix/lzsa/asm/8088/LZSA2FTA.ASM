;  lzsa2fta.asm - LZSA v2 time-efficient decompressor implementation for 8088
;  Turbo Assembler IDEAL mode dialect; can also be assembled with NASM.
;
;  Usual DOS assembler SMALL model assumptions apply.  This code:
;  - Assumes it was invoked via NEAR call (change RET to RETF for FAR calls)
;  - Is interrupt-safe
;  - Is not re-entrant (do not decompress while already running decompression)
;  - Trashes all data and segment registers
;
;  Copyright (C) 2019 Jim Leonard, Emmanuel Marty
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

        IDEAL
        P8086
        MODEL SMALL

        CODESEG

;While LZSA2 is technically capable of generating a match offset of -2,
;this sequence never actually showed up in my LZSA2 test corpus, likely due
;to compressor optimizations and the LZSA2 format itself.  If you know your
;test data will contain a match offset of -2, you can enable code to write
;out the sequence very quickly at the cost of 18 bytes of code.
HANDLE_WORD_RUN EQU 0

PUBLIC  lzsa2_decompress_speed

;  ---------------------------------------------------------------------------
;  Decompress raw LZSA2 block
;  inputs:
;  * ds:si: raw LZSA2 block
;  * es:di: output buffer
;  output:
;  * ax:    decompressed size
;  ---------------------------------------------------------------------------

PROC    lzsa2_decompress_speed  NEAR

MACRO get_nybble
LOCAL has_nybble
        neg     bh              ;nybble ready?
        jns     has_nybble
        xchg    bx,ax
        lodsb                   ;load two nybbles
        xchg    bx,ax
has_nybble:
        mov     cl,4            ;swap 4 high and low bits of nybble
        ror     bl,cl
        mov     cl,0FH
        and     cl,bl
ENDM

lzsa2_speed_start:
        push    di              ;remember decompression offset
        cld                     ;make string operations go forward
        xor     cx,cx
        mov     bx,0100H        ;bx used by get_nybble

@@decode_token:
        mov     ax,cx           ;clear ah - cx is zero (and must stay that way)
        lodsb                   ;read token byte: XYZ|LL|MMMM
        mov     dx,ax           ;keep copy of token in dl

        and     al,018H         ;isolate literals length in token (LL)
        jz      @@check_offset  ;no literals? stop decoding, go to matches

;At this point, al can be in three (unshifted) states: 1, 2, or 3.
;3 = not done yet.
        cmp     al,(2 shl 3)    ;LITERALS_RUN_LEN_V2? (original: cmp al,03h)
        jb      @@lit1b         ;LZSA2 output 1-byte more often, so test first
        je      @@lit2b

        mov     cl,3
        shr     al,cl           ;shift literals length into place
        get_nybble              ;cl := get extra literals length nybble
        add     al,cl           ;add len from token to nybble
        cmp     al,012H         ;LITERALS_RUN_LEN_V2 + 15 ?
        jne     @@got_literals  ;if not, we have the full literals count
        lodsb                   ;grab extra length byte
        add     al,012H         ;overflow?
        jnc     @@got_literals_big ;if not, we have a big full literals count
        lodsw                   ;grab 16-bit extra length

;For larger counts, it pays to set up a faster copy
@@got_literals_big:
        xchg    cx,ax
        shr     cx,1
        rep     movsw
        adc     cx,0
        rep     movsb
        jmp     @@check_offset

@@got_literals:
        xchg    cx,ax
        rep     movsb           ;copy cx literals from ds:si to es:di
        jmp     @@check_offset

;LZSA2 likes to produce tiny literals of 1 or 2 bytes.  Handle them here.
@@lit2b:movsb
@@lit1b:movsb

@@check_offset:
        test    dl,dl           ;check match offset mode in token (X bit)
        js      @@rep_match_or_large_offset

        cmp     dl,040H         ;check if this is a 5 or 9-bit offset (Y bit)
        jnb     @@offset_9_bit

        ;5 bit offset:
        xchg    cx,ax           ;clear ah - cx is zero from prior rep movs
        mov     al,020H         ;shift Z (offset bit 4) in place
        and     al,dl
        shl     al,1
        shl     al,1
        get_nybble              ;get nybble for offset bits 0-3
        or      al,cl           ;merge nybble
        rol     al,1
        xor     al,0E1H         ;set offset bits 7-5 to 1
        dec     ah              ;set offset bits 15-8 to 1
        jmp     @@get_match_length

@@rep_match_or_16_bit:
        test    dl,020H         ;test bit Z (offset bit 8)
        jne     @@repeat_match  ;rep-match

        ;16 bit offset:
        lodsw                   ;Get 2-byte match offset
        xchg    ah,al
        jmp     @@get_match_length

@@offset_9_bit:
        ;9 bit offset:
        xchg    cx,ax           ;clear ah - cx is zero from prior rep movs
        lodsb                   ;get 8 bit offset from stream in A
        dec     ah              ;set offset bits 15-8 to 1
        test    dl,020H         ;test bit Z (offset bit 8)
        je      @@get_match_length
        dec     ah              ;clear bit 8 if Z bit is clear
        jmp     @@get_match_length

@@rep_match_or_large_offset:
        cmp     dl,0c0H         ;check if this is a 13-bit offset
                                ;or a 16-bit offset/rep match (Y bit)
        jnb     @@rep_match_or_16_bit

        ;13 bit offset:
        mov     ah,020H         ;shift Z (offset bit 12) in place
        and     ah,dl
        shl     ah,1
        shl     ah,1
        get_nybble              ;get nybble for offset bits 8-11
        or      ah,cl           ;merge nybble
        rol     ah,1
        xor     ah,0E1H         ;set offset bits 15-13 to 1
        sub     ah,2            ;substract 512
        lodsb                   ;load match offset bits 0-7

@@get_match_length:
        mov     bp,ax           ;bp:=offset
@@repeat_match:
        mov     ax,dx           ;ax: original token
        and     al,07H          ;isolate match length in token (MMM)
        add     al,2            ;add MIN_MATCH_SIZE_V2

        cmp     al,09H          ;MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2?
        jne     @@got_matchlen  ;no, we have full match length from token

        get_nybble              ;get extra literals length nybble
        add     al,cl           ;add len from token to nybble
        cmp     al,018H         ;MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15?
        jne     @@got_matchlen  ;no, we have full match length from token

        lodsb                   ;grab extra length byte
        add     al,018H         ;overflow?
        jnc     @@got_matchlen_big  ;if not, we have entire (big) length
        je      @@done_decompressing ; detect EOD code

        lodsw                   ;grab 16-bit length

;If we're here, we have a larger match copy and can optimize how we do that
@@got_matchlen_big:
        xchg    cx,ax           ;copy match length into cx
        mov     dx,ds           ;save ds
        mov     ax,es
        mov     ds,ax           ;ds:=es
        xchg    si,ax           ;dx:ax = old ds:si
        mov     si,di           ;ds:si now points at back reference in output data
        add     si,bp
IF HANDLE_WORD_RUN
        cmp     bp,-2           ;do we have a byte/word run to optimize?
        jae     @@do_run        ;perform a run
ELSE
        cmp     bp,-1           ;do we have a byte run to optimize?
        je      @@do_run_1      ;perform a byte run
ENDIF
;You may be tempted to change "jae" to "jge" because DX is a signed number.
;Don't!  The total window is 64k, so if you treat this as a signed comparison,
;you will get incorrect results for offsets over 32K.
;
;If we're here, we have a long copy and it isn't byte-overlapping (if it
;overlapped, we'd be in @@do_run_1)  So, let's copy faster with REP MOVSW.
;This won't affect 8088 that much, but it speeds up 8086 and higher.
        shr     cx,1
        rep     movsw
        adc     cx,0
        rep     movsb
        xchg    si,ax
        mov     ds,dx           ;restore ds:si
        jmp     @@decode_token  ;go decode another token

;Smaller match copies handled here:
@@got_matchlen:
        xchg    cx,ax           ;copy match length into cx
        mov     dx,ds           ;save ds
        mov     ax,es
        mov     ds,ax           ;ds:=es
        xchg    si,ax           ;dx:ax = old ds:si
        mov     si,di           ;ds:si = back reference in output data
        add     si,bp
        rep     movsb           ;copy match
        xchg    si,ax
        mov     ds,dx           ;restore ds:si
        jmp     @@decode_token  ;go decode another token

@@done_decompressing:
        pop     ax              ;retrieve the original decompression offset
        xchg    di,ax           ;compute decompressed size
        sub     ax,di
        ret                     ;done

IF HANDLE_WORD_RUN
@@do_run:
        je      @@do_run_2      ;fall through to byte (common) if not word run
ENDIF

@@do_run_1:
        push    ax
        lodsb                   ;load first byte of run into al
        mov     ah,al
        shr     cx,1
        rep     stosw           ;perform word run
        adc     cx,0
        rep     stosb           ;finish word run
        pop     si
        mov     ds,dx
        jmp     @@decode_token  ;go decode another token

IF HANDLE_WORD_RUN
@@do_run_2:
        push    ax
        lodsw                   ;load first word of run
        shr     cx,1
        rep     stosw           ;perform word run
        adc     cx,0            ;despite 2-byte offset, compressor might
        rep     stosb           ;output odd length. better safe than sorry.
        pop     si
        mov     ds,dx
        jmp     @@decode_token  ;go decode another token
ENDIF

ENDP    lzsa2_decompress_speed

ENDS

END

;Speed optimization history (decompression times in microseconds @ 4.77 MHz):
;Compression corpus:shuttle alice robotro rletest largetx linewar ...... ..
;Start of exercise   160828 113311 665900  238507 1053865 1004237 ******
;add al,val -> al,cl 160813 113296 668721  237484 1053604 1003815 ++-+++
;sub ah,2 -> dec dec 160907 113585 666744  237484 1056651 1005172 --+*-- rb
;mov ax,cx->xchgcxax 159741 112460 660594  237477 1046770  998323 ++++++
;unroll get_nibble   152552 106327 621119  237345  982381  942373 ++++++
;early exit if LL=0  147242 103842 615559  239318  946863  942932 +++-+-
;push/pop->mov/mov   145447 100832 604822  237288  927017  931366 ++++++
;push/pop->mov/mov(2)143214  98817 592920  239298  908217  910955 +++-++
;rep stos for -1, -2 143289 102812 617087  237164  942081  940688 ---+-- rb
;larger literal cpys 143214  98817 591940  238296  907237  909657 **++++
;larger copys & runs 132440  98802 586551  178768  904129  896709 ++++++ :-)
;smaller lit. copies 131991  99131 583933  177760  901824  898308 +-+++-
;swap smal lit compa 131828  99022 585121  177757  901793  894054 ++-*++
;compare before shif 130587  95970 569908  177753  889221  872461 +++*++
;getmatchlength base 130587  95970 570634  177753  893536  871556 ...... ===
; f->rep_match_or_16 xxxxxx  xxxxx 569910  xxxxxx  889266  871435 ..+.++
; f->rep_match_or_la 129966  94748 566169  xxxxxx  880870  867030 +++.++ +++
; f->offset_9_bit    132126  95258 568869  xxxxxx  893169  870364 -++.-+
;final fallthrough   129966  94748 566169  177753  880870  865023 ******
