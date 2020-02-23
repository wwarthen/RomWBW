;  decompress_small_v2.asm - space-efficient decompressor implementation for x86
;
;  Copyright (C) 2019 Emmanuel Marty
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

    segment .text
    bits 32

;  ---------------------------------------------------------------------------
;  Decompress raw LZSA2 block
;  inputs:
;  * esi: raw LZSA2 block
;  * edi: output buffer
;  output:
;  * eax:    decompressed size
;  ---------------------------------------------------------------------------
    
    %ifndef BIN
      global lzsa2_decompress
      global _lzsa2_decompress
    %endif
    
lzsa2_decompress:
_lzsa2_decompress:
    pushad
    
    ;mov    edi, [esp+32+4]      ; edi = outbuf
    ;mov    esi, [esp+32+8]      ; esi = inbuf
    
    xor    ecx, ecx
    xor    ebx, ebx             ; ebx = 0100H
    inc    bh
    xor    ebp, ebp

.decode_token:
    mul    ecx
    lodsb                       ; read token byte: XYZ|LL|MMMM
    mov    dl, al               ; keep token in dl
   
    and    al, 018H             ; isolate literals length in token (LL)
    shr    al, 3                ; shift literals length into place

    cmp    al, 03H              ; LITERALS_RUN_LEN_V2?
    jne    .got_literals        ; no, we have the full literals count from the token, go copy

    call   .get_nibble          ; get extra literals length nibble
    add    al, cl               ; add len from token to nibble 
    cmp    al, 012H             ; LITERALS_RUN_LEN_V2 + 15 ?
    jne    .got_literals        ; if not, we have the full literals count, go copy

    lodsb                       ; grab extra length byte
    add    al,012H              ; overflow?
    jnc    .got_literals        ; if not, we have the full literals count, go copy

    lodsw                       ; grab 16-bit extra length

.got_literals:
    xchg   ecx, eax
    rep    movsb                ; copy ecx literals from esi to edi

    test   dl, 0C0h             ; check match offset mode in token (X bit)
    js     .rep_match_or_large_offset

    ;;cmp dl,040H               ; check if this is a 5 or 9-bit offset (Y bit)
                                ; discovered via the test with bit 6 set
    xchg   ecx, eax             ; clear ah - cx is zero from the rep movsb above
    jne    .offset_9_bit

                                ; 5 bit offset
    cmp    dl, 020H             ; test bit 5
    call   .get_nibble_x
    jmp    .dec_offset_top

.offset_9_bit:                  ; 9 bit offset
    lodsb                       ; get 8 bit offset from stream in A
    dec    ah                   ; set offset bits 15-8 to 1
    test   dl, 020H             ; test bit Z (offset bit 8)
    je     .get_match_length
.dec_offset_top:
    dec    ah                   ; clear bit 8 if Z bit is clear
                                ; or set offset bits 15-8 to 1
    jmp    .get_match_length

.rep_match_or_large_offset:
    ;;cmp dl,0c0H               ; check if this is a 13-bit offset or a 16-bit offset/rep match (Y bit)
    jpe    .rep_match_or_16_bit

                                ; 13 bit offset

    cmp    dl, 0A0H             ; test bit 5 (knowing that bit 7 is also set)
    xchg   ah, al
    call   .get_nibble_x
    sub    al, 2                ; substract 512
    jmp    .get_match_length_1

.rep_match_or_16_bit:
    test   dl, 020H             ; test bit Z (offset bit 8)
    jne    .repeat_match        ; rep-match

                                ; 16 bit offset
    lodsb                       ; Get 2-byte match offset

.get_match_length_1:
    xchg   ah, al
    lodsb                       ; load match offset bits 0-7

.get_match_length:
    xchg   ebp, eax             ; ebp: offset
.repeat_match:
    xchg   eax, edx             ; ax: original token
    and    al, 07H              ; isolate match length in token (MMM)
    add    al, 2                ; add MIN_MATCH_SIZE_V2

    cmp    al, 09H              ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2?
    jne    .got_matchlen        ; no, we have the full match length from the token, go copy

    call   .get_nibble          ; get extra literals length nibble
    add    al, cl               ; add len from token to nibble 
    cmp    al, 018H             ; MIN_MATCH_SIZE_V2 + MATCH_RUN_LEN_V2 + 15?
    jne    .got_matchlen        ; no, we have the full match length from the token, go copy

    lodsb                       ; grab extra length byte
    add    al,018H              ; overflow?
    jnc    .got_matchlen        ; if not, we have the entire length
    je     .done_decompressing  ; detect EOD code

    lodsw                       ; grab 16-bit length

.got_matchlen:
    xchg   ecx, eax             ; copy match length into ecx
    xchg   esi, eax          
    movsx  ebp, bp              ; sign-extend bp to 32-bits
    lea    esi,[ebp+edi]        ; esi now points at back reference in output data
    rep    movsb                ; copy match
    xchg   esi, eax             ; restore esi
    jmp    .decode_token        ; go decode another token

.done_decompressing:
    sub    edi, [esp+32+4]
    mov    [esp+28], edi
    popad
    ret                         ; done

.get_nibble_x:
    cmc                         ; carry set if bit 4 was set
    rcr    al, 1
    call   .get_nibble          ; get nibble for offset bits 0-3
    or     al, cl               ; merge nibble
    rol    al, 1
    xor    al, 0E1H             ; set offset bits 7-5 to 1
    ret

.get_nibble:
    neg    bh                   ; nibble ready?
    jns    .has_nibble
   
    xchg   ebx, eax
    lodsb                       ; load two nibbles
    xchg   ebx, eax

.has_nibble:
    mov    cl, 4                ; swap 4 high and low bits of nibble
    ror    bl, cl
    mov    cl, 0FH
    and    cl, bl
    ret
