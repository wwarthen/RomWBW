
;
; Simple Block Compare for Comparison purposes
; Both HL and DL contain Block pointers to compare
; HL MUST start on an even block e.g. 8000h
; RET NZ - Failure, Z if no issue
;
_cmp20block
    ; inc de        ; uncommnet to test crc fail!
    ld      bc, 20h  ; 10t Size of Pointer Increment
_cmp20block1:
    ld      a, (de) ; 7t Do The comparison itself
    cp      (hl)    ; 7t
    JR      NZ, _cmp20block2 ; 7t / 12t = 21t

    add     hl, bc  ; 11t Add the Increment to both pointers
    ex      de, hl  ; 4t
    add     hl, bc  ; 11t
    ex      de, hl  ; 4t = 30t

    ld      a, h    ; 4t High order byte on Even Boundary
    bit     4, a    ; 8t has bit 4 been set then exceeded 1000h (4k boundary)
    JR      Z, _cmp20block1 ; 12t / 7t = 24t
    xor     a       ; 4t
    RET             ; 10t Return Success
_cmp20block2:
    scf             ; signal CARRY FLAG Also
    RET             ; This is the error

; clock cycles for above
; add 40h -> 64 (loop) * 73t =>>  4,672 - 1.56%
; add 20h ->128 (loop) * 73t =>>  9,344 - 3.13% <= WENT WITH THIS
; add 10h ->256 (loop) * 73t =>> 18,688 - 6.25%
; accuracy = 88/4096 => 2.1%

; =====================================================================
; From : https://tomdalby.com/other/crc.html
; And  : https://map.grauw.nl/sources/external/z80bits.html#6.1
; =====================================================================
;
; =====================================================================
; input - hl=start of memory to check, de=length of memory to check
; returns - a=result crc
; 20b
; =====================================================================

; THE COMMNETED LINES NEED TO BE UNCOMMENTED

_crc8b:
    xor a           ; 4t - initial value so first byte can be XORed in (CCITT)
;    ld      c, 07h  ; 7t - c=polyonimal used in loop (small speed up)
_byteloop8b:
    xor     (hl)    ; 7t - xor in next byte, for first pass a=(hl)
    inc     hl      ; 6t - next mem
;    ld      b, 8    ; 7t - loop over 8 bits
_rotate8b:
;    add     a,a     ; 4t - shift crc left one
;    jr      nc, _nextbit8b ; 12/7t - only xor polyonimal if msb set (carry=1)
;    xor     c       ; 4t - CRC8_CCITT = 0x07
_nextbit8b:
;    djnz    _rotate8b ; 13/8t
    ld      b,a     ; 4t - preserve a in b
    dec     de      ; 6t - counter-1
    ld      a,d     ; 4t - check if de=0
    or      e       ; 4t
    ld      a,b     ; 4t - restore a
    jr      nz, _byteloop8b ; 12/7t
    ret             ; 10t

; Clock Cycle For above with 4k bypes
; Loop = 4096 * 47 cycles + 11 => 192,523 x 2 (src/dest) => 385,046
; acuracy = 1 / 256 => 0.4 %

; =====================================================================
; CRC-CCITT
;
; CCITT polynomial 1021h
; Initial Value    FFFFh
;
; input - de=start of memory to check, bc=length of memory to check
; returns - hl=result crc
; =====================================================================

_crc16:
    ld      hl, 0ffffh ; 10t - initial crc = $ffff
_byte16:
;    push    bc ; 11t - preserve counter
    ld      a,(de) ; 7t - get byte
    inc     de ; 6t - next mem
;    xor     h ; 4t - xor byte into crc high byte
;    ld      h,a ; 4t - back into high byte
;    ld      b,8 ; 7t - rotate 8 bits
_rotate16:
;    add     hl,hl ; 11t - rotate crc left one
;    jr      nc,_nextbit16 ; 12/7t - only xor polyonimal if msb set
;    ld      a,h ; 4t
;    xor     10h ; 7t - high byte with $10
;    ld      h,a ; 4t
;    ld      a,l ; 4t
;    xor     21h ; 7t - low byte with $21
;    ld      l,a ; 4t - hl now xor $1021
_nextbit16:
;    djnz    _rotate16 ; 13/8t - loop over 8 bits
;    pop     bc ; 10t - bring back main counter
    dec     bc ; 6t
    ld      a,b ; 4t
    or      c ; 4t
    jr      nz,_byte16 ; 12/7t
    ret     ; 10t
;
