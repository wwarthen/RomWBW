;  decompress_small_v1.asm - space-efficient decompressor implementation for x86
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
;  Decompress raw LZSA1 block
;  inputs:
;  * esi: raw LZSA1 block
;  * edi: output buffer
;  output:
;  * eax:    decompressed size
;  ---------------------------------------------------------------------------

    %ifndef BIN
      global lzsa1_decompress
      global _lzsa1_decompress
    %endif
    
lzsa1_decompress:
_lzsa1_decompress:
    pushad
    
    ;mov    edi, [esp+32+4]    ; edi = outbuf
    ;mov    esi, [esp+32+8]    ; esi = inbuf
    
    xor    ecx, ecx
.decode_token:
    mul    ecx
    lodsb                     ; read token byte: O|LLL|MMMM
    mov    dl, al             ; keep token in dl
   
    and    al, 070H           ; isolate literals length in token (LLL)
    shr    al, 4              ; shift literals length into place

    cmp    al, 07H            ; LITERALS_RUN_LEN?
    jne    .got_literals      ; no, we have the full literals count from the token, go copy

    lodsb                     ; grab extra length byte
    add    al, 07H            ; add LITERALS_RUN_LEN
    jnc    .got_literals      ; if no overflow, we have the full literals count, go copy
    jne    .mid_literals

    lodsw                     ; grab 16-bit extra length
    jmp    .got_literals

.mid_literals:
    lodsb                     ; grab single extra length byte
    inc    ah                 ; add 256

.got_literals:
    xchg   ecx, eax
    rep    movsb              ; copy cx literals from ds:si to es:di

    test   dl, dl             ; check match offset size in token (O bit)
    js     .get_long_offset

    dec     ecx
    xchg    eax, ecx          ; clear ah - cx is zero from the rep movsb above
    lodsb
    jmp     .get_match_length

.get_long_offset:
    lodsw                     ; Get 2-byte match offset

.get_match_length:
    xchg    eax, edx          ; edx: match offset  eax: original token
    and     al, 0FH           ; isolate match length in token (MMMM)
    add     al, 3             ; add MIN_MATCH_SIZE

    cmp     al, 012H          ; MATCH_RUN_LEN?
    jne     .got_matchlen     ; no, we have the full match length from the token, go copy

    lodsb                     ; grab extra length byte
    add     al,012H           ; add MIN_MATCH_SIZE + MATCH_RUN_LEN
    jnc     .got_matchlen     ; if no overflow, we have the entire length
    jne     .mid_matchlen       

    lodsw                     ; grab 16-bit length
    test    eax, eax          ; bail if we hit EOD
    je      .done_decompressing 
    jmp     .got_matchlen

.mid_matchlen:
    lodsb                     ; grab single extra length byte
    inc     ah                ; add 256

.got_matchlen:
    xchg    ecx, eax          ; copy match length into ecx
    xchg    esi, eax          
    mov     esi, edi          ; esi now points at back reference in output data
    movsx   edx, dx           ; sign-extend dx to 32-bits.
    add     esi, edx
    rep     movsb             ; copy match
    xchg    esi, eax          ; restore esi
    jmp     .decode_token     ; go decode another token

.done_decompressing:
    sub    edi, [esp+32+4]
    mov    [esp+28], edi      ; eax = decompressed size
    popad
    ret                       ; done
