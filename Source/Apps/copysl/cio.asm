
BDOS   	    .EQU 5

; bdos commands
CONIN       .EQU 1
CONOUT      .EQU 2
DIRCONIO    .EQU 6

; TODO for more routines see assign.asm

; ===============
; INPUT

; Console Input
getchr:
    PUSH    BC
    PUSH    DE
    PUSH    HL
    LD      C,CONIN
    CALL    BDOS
    POP HL
    POP DE
    POP BC
    RET

; direct console io
; BDOS 6 - FF FE FD - commands
conread:
    RET
constatus:
    RET
coninput:
    RET

; =======================================
; STANDARD OUTPUT

;
; Print character in A without destroying any registers
;
prtchr:
    ; PUSH   AF
    PUSH   HL        ; We must preserve HL, as the BDOS call sets it
    PUSH   BC
    PUSH   DE
    LD     C, CONOUT
    LD     E, A
    CALL   BDOS
    POP    DE
    POP    BC
    POP    HL
    ; POP    AF
    RET
;
prtdot:
    push    af
    ld      a, '.'
    call    prtchr
    pop     af
    ret
;
; Print a zero terminated string at (HL) without destroying any registers
;
prtstr:
    PUSH   AF
    PUSH   BC
    push   de
prtstr1:
    ld      a,(hl)
    or      0
    jr      z,prtstr2
    ld      c, CONOUT
    ld      e,a
    push    hl
    call    BDOS
    pop     hl
    inc     hl
    jr      prtstr1
prtstr2:
    pop    de
    pop    bc
    pop    af
    ret

;
; Print the value in A in hex without destroying any registers
;
prthex:
    push    af      ; save AF
    push    de      ; save DE
    call    hexascii    ; convert value in A to hex chars in DE
    ld  a,d     ; get the high order hex char
    call    prtchr      ; print it
    ld  a,e     ; get the low order hex char
    call    prtchr      ; print it
    pop de      ; restore DE
    pop af      ; restore AF
    ret         ; done

;
; print the hex word value in bc
;
prthexword:
    push    af
    ld  a,b
    call    prthex
    ld  a,c
    call    prthex
    pop af
    ret
;
; Convert binary value in A to ascii hex characters in DE
;
hexascii:
    ld  d,a     ; save A in D
    call    hexconv     ; convert low nibble of A to hex
    ld  e,a     ; save it in E
    ld  a,d     ; get original value back
    rlca            ; rotate high order nibble to low bits
    rlca
    rlca
    rlca
    call    hexconv     ; convert nibble
    ld  d,a     ; save it in D
    ret         ; done
;
; Convert low nibble of A to ascii hex
;
hexconv:
    and 0Fh         ; low nibble only
    add a,90h
    daa
    adc a,40h
    daa
    ret
;
; Print the decimal value of A, with leading zero suppression
;
prtdec:
    push    hl
    ld  h,0
    ld  l,a
    call    prtdecword     ; print it
    pop hl
    ret
;
; Print the Decimal value (word) in HL
;
prtdecword:
    push    af
    push    bc
    push    de
    push    hl
    call    prtdec0
    pop hl
    pop de
    pop bc
    pop af
    ret
;
prtdec0:
    ld  e,'0'
    ld  bc,-10000
    call    prtdec1
    ld  bc,-1000
    call    prtdec1
    ld  bc,-100
    call    prtdec1
    ld  c,-10
    call    prtdec1
    ld  e,0
    ld  c,-1
prtdec1:
    ld  a,'0' - 1
prtdec2:
    inc a
    add hl,bc
    jr  c,prtdec2
    sbc hl,bc
    cp  e
    ret z
    ld  e,0
    call    prtchr
    ret
;
; Print a byte buffer in hex pointed to by DE
; Register A has size of buffer
;
prthexbuf:
    or  a
    ret z       ; empty buffer
prthexbuf1:
    ld  a,' '
    call    prtchr
    ld  a,(de)
    call    prthex
    inc de
    djnz    prthexbuf1
    ret
;
; Start a new Line
;
prtcrlf2:
    call prtcrlf
prtcrlf:
    	push hl
    	ld	hl, prtcrlf_msg
    	call 	prtstr
    	pop 	hl
    	ret
prtcrlf_msg:
    	.DB 	13,10,0

; =================================
; following is from dmamon util.asm
;
; IMMEDIATE PRINT
; =================================
;
; PRINT A CHARACTER REFERENCED BY POINTER AT TOP OF STACK
; USAGE:
;   CALL IPRTCHR
;   .DB  'X'
;
iprtchr:
    EX      (SP),HL
    PUSH    AF
    LD      A,(HL)
    CALL    prtchr
    POP     AF
    INC     HL
    EX      (SP),HL
    RET

; Print a string referenced by pointer at top of stack
; Usage
;   call iprtstr
;   .DB     "text", 0
;
iprtstr:
    EX      (SP),HL
    CALL    prtstr
    INC     HL
    EX      (SP),HL
    RET
;
; ===========================================================
;
;   Following is for INPUT, used to process command line args
;
; ===========================================================
;
; Skip whitespace at buffer adr in DE, returns with first
; non-whitespace character in A.
;
skipws:
    ld      a,(hl)  ; get next char
    or      a       ; check for eol
    ret     z       ; done if so
    cp      ' '     ; blank?
    ret     nz      ; nope, done
    inc     hl      ; bump buffer pointer
    jr      skipws  ; and loop

;
; Uppercase character in A
;
upcase:
    cp  'a'         ; below 'a'?
    ret c           ; if so, nothing to do
    cp  'z'+1       ; above 'z'?
    ret nc          ; if so, nothing to do
    and ~020h       ; convert character to lower
    ret             ; done

;
; Get numeric chars at HL and convert to number returned in A
; Carry flag set on overflow
; C is used as a working register
;
getnum:
    ld      c,0     ; C is working register

getnum1:
    ld      a,(hl)  ; get the active char
    cp      '0'     ; compare to ascii '0'
    jr      c,getnum2 ; abort if below
    cp      '9' + 1 ; compare to ascii '9'
    jr      nc,getnum2 ; abort if above
;
    ld      a,c     ; get working value to A
    rlca            ; multiply by 10
    ret     c       ; overflow, return with carry set
    rlca            ; ...
    ret     c       ; overflow, return with carry set
    add     a,c     ; ...
    ret     c       ; overflow, return with carry set
    rlca            ; ...
    ret     c       ; overflow, return with carry set
    ld      c,a     ; back to C
    ld      a,(hl)  ; get new digit
    sub     '0'     ; make binary
    add     a,c     ; add in working value
    ret     c       ; overflow, return with carry set
    ld      c,a     ; back to C
;
    inc hl      ; bump to next char
    jr  getnum1     ; loop
;
getnum2:
    ld  a,c     ; return result in A
    or  a       ; with flags set, CF is cleared
    ret
;
; Is character in A numeric? NZ if not
;
isnum:
    cp  '0'     ; compare to ascii '0'
    jr  c,isnum1    ; abort if below
    cp  '9' + 1     ; compare to ascii '9'
    jr  nc,isnum1   ; abort if above
    cp  a       ; set Z
    ret
isnum1:
    or  0FFh     ; set NZ
    ret         ; and done


