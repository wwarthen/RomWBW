;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test96.asm 1.1 1997/11/23 15:51:20 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: 8096/8XC196KC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;

;         CPU    "8096.TBL"    ; CPU TABLE
;         HOF    "INT8"        ; HEX FORMAT

#define EQU .equ
#define END .end
#define ORG .org
#define DWL .dw
#define IF  #if
#define ENDI #endif

wreg:   EQU    12h             ; word register even address
wreg1:  EQU    22h             ; word register even address
wreg2:  EQU    32h             ; word register even address
wreg3:  EQU    42h             ; word register even address
lreg1:  EQU    44h             ; long register (32 bit)
lreg2:  EQU    48h             ; long register (32 bit)
breg:   EQU    wreg+1          ; low byte of reg. where odd is allowed
breg1:  EQU    wreg+3          ; low byte of reg. where odd is allowed
breg2:  EQU    wreg+5          ; low byte of reg. where odd is allowed
breg3:  EQU    wreg+7          ; low byte of reg. where odd is allowed

imm8:   EQU    88H
imm16:  EQU    4321H

addr8:  EQU    12H
addr16: EQU    3456H

ishort: EQU    12H
ishrt:  EQU    12H
ilong:  EQU    4567H

count:  EQU    7H

         ORG   7418h

dtable: DWL $1234
	DWL $5678
	DWL $1234


;-------------------------------------
; ADD
        add     wreg1,#imm8
        add     wreg1,#imm16
        add     wreg1,wreg2
        add     wreg1,addr16
        add     wreg1,[wreg2]
        add     wreg1,[wreg2]+
        add     wreg1,addr8[wreg2]
        add     wreg1,addr16[wreg2]

        add     wreg1,wreg2,#imm8
        add     wreg1,wreg2,#imm16
        add     wreg1,wreg2,wreg3
        add     wreg1,wreg2,addr16
        add     wreg1,wreg2,[wreg3]
        add     wreg1,wreg2,[wreg3]+
        add     wreg1,wreg2,addr8[wreg3]
        add     wreg1,wreg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; ADDB
        addb    breg1,#imm8
        addb    breg1,breg2
        addb    breg1,addr16
        addb    breg1,[wreg2]
        addb    breg1,[wreg2]+
        addb    breg1,addr8[wreg2]
        addb    breg1,addr16[wreg2]

        addb    breg1,breg2,#imm8
        addb    breg1,breg2,breg3
        addb    breg1,breg2,addr16
        addb    breg1,breg2,[wreg3]
        addb    breg1,breg2,[wreg3]+
        addb    breg1,breg2,addr8[wreg3]
        addb    breg1,breg2,addr16[wreg3]
;-------------------------------------


;-------------------------------------
; ADDB
        addc    wreg1,#imm8
        addc    wreg1,#imm16
        addc    wreg1,wreg2
        addc    wreg1,addr16
        addc    wreg1,[wreg2]
        addc    wreg1,[wreg2]+
        addc    wreg1,addr8[wreg2]
        addc    wreg1,addr16[wreg2]

        ; No three arg form for addc
;-------------------------------------

;-------------------------------------
; ADDCB
        addcb   breg1,#imm8
        addcb   breg1,breg2
        addcb   breg1,addr16
        addcb   breg1,[wreg2]
        addcb   breg1,[wreg2]+
        addcb   breg1,addr8[wreg2]
        addcb   breg1,addr16[wreg2]

        ; No three arg form for addcb
;-------------------------------------

;-------------------------------------
; AND  
        and     wreg1,#imm8
        and     wreg1,#imm16
        and     wreg1,wreg2
        and     wreg1,addr16
        and     wreg1,[wreg2]
        and     wreg1,[wreg2]+
        and     wreg1,addr8[wreg2]
        and     wreg1,addr16[wreg2]

        and     wreg1,wreg2,#imm8
        and     wreg1,wreg2,#imm16
        and     wreg1,wreg2,wreg3
        and     wreg1,wreg2,addr16
        and     wreg1,wreg2,[wreg3]
        and     wreg1,wreg2,[wreg3]+
        and     wreg1,wreg2,addr8[wreg3]
        and     wreg1,wreg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; ANDB 
        andb    breg1,#imm8
        andb    breg1,breg2
        andb    breg1,addr16
        andb    breg1,[wreg2]
        andb    breg1,[wreg2]+
        andb    breg1,addr8[wreg2]
        andb    breg1,addr16[wreg2]

        andb    breg1,breg2,#imm8
        andb    breg1,breg2,breg3
        andb    breg1,breg2,addr16
        andb    breg1,breg2,[wreg3]
        andb    breg1,breg2,[wreg3]+
        andb    breg1,breg2,addr8[wreg3]
        andb    breg1,breg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; BMOV 
        bmov    lreg1,wreg1
        bmov    lreg1,wreg2
;-------------------------------------

;-------------------------------------
; BR   
        br      [wreg1]
;-------------------------------------

;-------------------------------------
; MISC CLR  
        clr     wreg1
        clrb    breg1
        clrc
        clrvt
;-------------------------------------



;-------------------------------------
; CMP 
        cmp     wreg1,#imm8
        cmp     wreg1,#imm16
        cmp     wreg1,wreg2
        cmp     wreg1,addr16
        cmp     wreg1,[wreg2]
        cmp     wreg1,[wreg2]+
        cmp     wreg1,addr8[wreg2]
        cmp     wreg1,addr16[wreg2]

        ; No three arg form for cmp 
;-------------------------------------

;-------------------------------------
; CMPB 
        cmpb    breg1,#imm8
        cmpb    breg1,breg2
        cmpb    breg1,addr16
        cmpb    breg1,[wreg2]
        cmpb    breg1,[wreg2]+
        cmpb    breg1,addr8[wreg2]
        cmpb    breg1,addr16[wreg2]

        ; No three arg form for cmpb 
;-------------------------------------

;-------------------------------------
; CMPL 
        cmpl    lreg1,lreg2
;-------------------------------------

;-------------------------------------
; DEC 
        dec     wreg1
        decb    breg1
;-------------------------------------

;-------------------------------------
; DEC 
        di
;-------------------------------------


;-------------------------------------
; DIV 
        div     lreg1,#imm8
        div     lreg1,#imm16
        div     lreg1,wreg2
        div     lreg1,addr16
        div     lreg1,[wreg2]
        div     lreg1,[wreg2]+
        div     lreg1,addr8[wreg2]
        div     lreg1,addr16[wreg2]

        ; No three arg form for div 
;-------------------------------------

;-------------------------------------
; DIVB 
        divb    wreg1,#imm8
        divb    wreg1,breg2
        divb    wreg1,addr16
        divb    wreg1,[wreg2]
        divb    wreg1,[wreg2]+
        divb    wreg1,addr8[wreg2]
        divb    wreg1,addr16[wreg2]

        ; No three arg form for divb 
;-------------------------------------


;-------------------------------------
; DIVU 
        divu    lreg1,#imm8
        divu    lreg1,#imm16
        divu    lreg1,wreg2
        divu    lreg1,addr16
        divu    lreg1,[wreg2]
        divu    lreg1,[wreg2]+
        divu    lreg1,addr8[wreg2]
        divu    lreg1,addr16[wreg2]

        ; No three arg form for divu
;-------------------------------------

;-------------------------------------
; DIVUB 
        divub   wreg1,#imm8
        divub   wreg1,breg2
        divub   wreg1,addr16
        divub   wreg1,[wreg2]
        divub   wreg1,[wreg2]+
        divub   wreg1,addr8[wreg2]
        divub   wreg1,addr16[wreg2]

        ; No three arg form for divub
;-------------------------------------


;-------------------------------------
; DJNZ 
rtest1: ;backward reference
        djnz    breg1,rtest1
        djnz    breg1,rtest1
        djnz    breg1,rtest2
        djnz    breg1,rtest2
rtest2: ;forward reference
;-------------------------------------

;-------------------------------------
; DJNZW
        djnzw   wreg1,rtest1
        djnzw   wreg1,rtest1
        djnzw   wreg1,rtest3
        djnzw   wreg1,rtest3
rtest3: ;forward reference
;-------------------------------------

;-------------------------------------
; DPTS
        dpts
;-------------------------------------

;-------------------------------------
; EI
        ei
;-------------------------------------

;-------------------------------------
; EPTS
        epts
;-------------------------------------

;-------------------------------------
; EXT & EXTB
        ext     lreg1
        ext     lreg2
        extb    wreg1
        extb    wreg2
;-------------------------------------

;-------------------------------------
; IDLPD
        idlpd #1
        idlpd #2
;-------------------------------------

;-------------------------------------
; INC & INCB
        inc     wreg1
        inc     wreg2
        incb    breg1
        incb    breg2
;-------------------------------------


FLAG:   EQU    3
;-------------------------------------
; JBC
        jbc     breg1,0,rtest1
        jbc     breg1,1,rtest1
        jbc     breg1,2,rtest1
        jbc     breg1,3,rtest1
        jbc     breg1,4,rtest1
        jbc     breg1,5,rtest1
        jbc     breg1,6,rtest1
        jbc     breg1,7,rtest1
;-------------------------------------

;-------------------------------------
; JBS
        jbs     breg1,0,rtest1
        jbs     breg1,1,rtest1
        jbs     breg1,2,rtest1
        jbs     breg1,3,rtest1
        jbs     breg1,4,rtest1
        jbs     breg1,5,rtest1
        jbs     breg1,6,rtest1
        jbs     breg1,7,rtest1
;-------------------------------------

;-------------------------------------
; MISC Jump backward
        jc      rtest1
        je      rtest1
        jge     rtest1
        jgt     rtest1
        jh      rtest1
        jle     rtest1
        jlt     rtest1
        jnc     rtest1
        jne     rtest1
        jnh     rtest1
        jnst    rtest1
        jnv     rtest1
        jnvt    rtest1
        jst     rtest1
        jv      rtest1
        jvt     rtest1
;-------------------------------------

;-------------------------------------
; MISC Jump forward
        jc      rtest4
        je      rtest4
        jge     rtest4
        jgt     rtest4
        jh      rtest4
        jle     rtest4
        jlt     rtest4
        jnc     rtest4
        jne     rtest4
        jnh     rtest4
        jnst    rtest4
        jnv     rtest4
        jnvt    rtest4
        jst     rtest4
        jv      rtest4
rtest4: jvt     rtest4
;-------------------------------------

;-------------------------------------
; LCALL
        lcall   rtest1
        lcall   rtest2
        lcall   rtest4
        lcall   addr8
        lcall   addr16
;-------------------------------------


;-------------------------------------
; LD 
        ld      wreg1,#imm8
        ld      wreg1,#imm16
        ld      wreg1,wreg2
        ld      wreg1,addr16
        ld      wreg1,[wreg2]
        ld      wreg1,[wreg2]+
        ld      wreg1,addr8[wreg2]
        ld      wreg1,addr16[wreg2]

        ; No three arg form for ld  
;-------------------------------------

;-------------------------------------
; LDB  
        ldb     breg1,#imm8
        ldb     breg1,breg2
        ldb     breg1,addr16
        ldb     breg1,[wreg2]
        ldb     breg1,[wreg2]+
        ldb     breg1,addr8[wreg2]
        ldb     breg1,addr16[wreg2]

        ; No three arg form for ldb  
;-------------------------------------

;-------------------------------------
; LDBSE 
        ldbse   wreg1,#imm8
        ldbse   wreg1,breg2
        ldbse   wreg1,addr16
        ldbse   wreg1,[wreg2]
        ldbse   wreg1,[wreg2]+
        ldbse   wreg1,addr8[wreg2]
        ldbse   wreg1,addr16[wreg2]

        ; No three arg form for ldbse  
;-------------------------------------

;-------------------------------------
; LDBZE 
        ldbze   wreg1,#imm8
        ldbze   wreg1,breg2
        ldbze   wreg1,addr16
        ldbze   wreg1,[wreg2]
        ldbze   wreg1,[wreg2]+
        ldbze   wreg1,addr8[wreg2]
        ldbze   wreg1,addr16[wreg2]

        ; No three arg form for ldbze  
;-------------------------------------

;-------------------------------------
; LJMP 
        ljmp    addr8
        ljmp    addr16
;-------------------------------------


;-------------------------------------
; MUL 
        mul     lreg1,#imm8
        mul     lreg1,#imm16
        mul     lreg1,wreg2
        mul     lreg1,addr16
        mul     lreg1,[wreg2]
        mul     lreg1,[wreg2]+
        mul     lreg1,addr8[wreg2]
        mul     lreg1,addr16[wreg2]

        mul     lreg1,wreg2,#imm8
        mul     lreg1,wreg2,#imm16
        mul     lreg1,wreg2,wreg3
        mul     lreg1,wreg2,addr16
        mul     lreg1,wreg2,[wreg3]
        mul     lreg1,wreg2,[wreg3]+
        mul     lreg1,wreg2,addr8[wreg3]
        mul     lreg1,wreg2,addr16[wreg3]

;-------------------------------------


;-------------------------------------
; MULB 
        mulb    wreg1,#imm8
        mulb    wreg1,breg2
        mulb    wreg1,addr16
        mulb    wreg1,[wreg2]
        mulb    wreg1,[wreg2]+
        mulb    wreg1,addr8[wreg2]
        mulb    wreg1,addr16[wreg2]

        mulb    wreg1,breg2,#imm8
        mulb    wreg1,breg2,breg3
        mulb    wreg1,breg2,addr16
        mulb    wreg1,breg2,[wreg3]
        mulb    wreg1,breg2,[wreg3]+
        mulb    wreg1,breg2,addr8[wreg3]
        mulb    wreg1,breg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; MULU 
        mulu    lreg1,#imm8
        mulu    lreg1,#imm16
        mulu    lreg1,wreg2
        mulu    lreg1,addr16
        mulu    lreg1,[wreg2]
        mulu    lreg1,[wreg2]+
        mulu    lreg1,addr8[wreg2]
        mulu    lreg1,addr16[wreg2]

        mulu    lreg1,wreg2,#imm8
        mulu    lreg1,wreg2,#imm16
        mulu    lreg1,wreg2,wreg3
        mulu    lreg1,wreg2,addr16
        mulu    lreg1,wreg2,[wreg3]
        mulu    lreg1,wreg2,[wreg3]+
        mulu    lreg1,wreg2,addr8[wreg3]
        mulu    lreg1,wreg2,addr16[wreg3]

;-------------------------------------


;-------------------------------------
; MULUB
        mulub   wreg1,#imm8
        mulub   wreg1,breg2
        mulub   wreg1,addr16
        mulub   wreg1,[wreg2]
        mulub   wreg1,[wreg2]+
        mulub   wreg1,addr8[wreg2]
        mulub   wreg1,addr16[wreg2]

        mulub   wreg1,breg2,#imm8
        mulub   wreg1,breg2,breg3
        mulub   wreg1,breg2,addr16
        mulub   wreg1,breg2,[wreg3]
        mulub   wreg1,breg2,[wreg3]+
        mulub   wreg1,breg2,addr8[wreg3]
        mulub   wreg1,breg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; NEG & NEGB
        neg     wreg1
        negb    breg1
;-------------------------------------

;-------------------------------------
; NOP
        nop
;-------------------------------------

;-------------------------------------
; NORML
        norml   lreg1,breg1
;-------------------------------------

;-------------------------------------
; NOT & NOTB
        not     wreg1
        notb    breg1
;-------------------------------------


;-------------------------------------
; OR 
        or      wreg1,#imm8
        or      wreg1,#imm16
        or      wreg1,wreg2
        or      wreg1,addr16
        or      wreg1,[wreg2]
        or      wreg1,[wreg2]+
        or      wreg1,addr8[wreg2]
        or      wreg1,addr16[wreg2]

        ; No three arg form for or  
;-------------------------------------

;-------------------------------------
; ORB  
        orb     breg1,#imm8
        orb     breg1,breg2
        orb     breg1,addr16
        orb     breg1,[wreg2]
        orb     breg1,[wreg2]+
        orb     breg1,addr8[wreg2]
        orb     breg1,addr16[wreg2]

        ; No three arg form for orb  
;-------------------------------------


;-------------------------------------
; POP  
        pop     wreg1
        pop     [wreg1]
        pop     [wreg1]+
        pop     addr8[wreg1]
        pop     addr16[wreg1]

        popa
        popf
;-------------------------------------

;-------------------------------------
; PUSH 
        push    wreg1
        push    [wreg1]
        push    [wreg1]+
        push    addr8[wreg1]
        push    addr16[wreg1]

        pusha
        pushf
;-------------------------------------


;-------------------------------------
; RET - return
        ret
;-------------------------------------

;-------------------------------------
; RST - reset
        rst
;-------------------------------------

;-------------------------------------
; SCALL - short call
scall1:
scall2: EQU scall1-1015
        scall   scall1
        scall   scall1
        scall   scall2
        scall   scall2
        scall   scall3
        scall   scall4
scall3:
scall4: EQU scall3+1020
;-------------------------------------

;-------------------------------------
; SETC - set carry
        setc
;-------------------------------------

;-------------------------------------
; shl - shift word left
        shl     wreg1,#count
        shl     wreg2,breg1
;-------------------------------------

;-------------------------------------
; shlb - shift byte left
        shlb    breg1,#count
        shlb    breg2,breg1
;-------------------------------------

;-------------------------------------
; shll - shift long word left
        shll    lreg1,#count
        shll    lreg1,breg1
;-------------------------------------

;-------------------------------------
; shr - logical shift word right
        shr     wreg1,#count
        shr     wreg2,breg1
;-------------------------------------

;-------------------------------------
; shra - arithmetic shift word right
        shra    wreg1,#count
        shra    wreg2,breg1
;-------------------------------------

;-------------------------------------
; shrab - arithmetic shift byte right
        shrab   breg1,#count
        shrab   breg2,breg1
;-------------------------------------

;-------------------------------------
; shral - arithmetic shift long word right
        shral   lreg1,#count
        shral   lreg1,breg1
;-------------------------------------

;-------------------------------------
; shrb - logical shift byte right
        shrb    breg1,#count
        shrb    breg2,breg1
;-------------------------------------

;-------------------------------------
; shrl - logical shift long word right
        shrl    lreg1,#count
        shrl    lreg1,breg1
;-------------------------------------


;-------------------------------------
; SJMP - short jump
sjump1:
sjump2: EQU sjump1-1015
        sjmp    sjump1
        sjmp    sjump1
        sjmp    sjump2
        sjmp    sjump2
        sjmp    sjump3
        sjmp    sjump4
sjump3:
sjump4: EQU sjump3+1020
;-------------------------------------

;-------------------------------------
; skip - two byte nop
        skip    breg1
;-------------------------------------


;-------------------------------------
; ST - store word
        st      wreg1,wreg2
        st      wreg1,addr16
        st      wreg1,[wreg2]
        st      wreg1,[wreg2]+
        st      wreg1,addr8[wreg2]
        st      wreg1,addr16[wreg2]

        ; No three arg form for st; No immediate
;-------------------------------------

;-------------------------------------
; STB - store byte
        stb     breg1,breg2
        stb     breg1,addr16
        stb     breg1,[wreg2]
        stb     breg1,[wreg2]+
        stb     breg1,addr8[wreg2]
        stb     breg1,addr16[wreg2]

        ; No three arg form for stb; No immediate
;-------------------------------------


;-------------------------------------
; SUB - subtract word
        sub     wreg1,#imm8
        sub     wreg1,#imm16
        sub     wreg1,wreg2
        sub     wreg1,addr16
        sub     wreg1,[wreg2]
        sub     wreg1,[wreg2]+
        sub     wreg1,addr8[wreg2]
        sub     wreg1,addr16[wreg2]

        sub     wreg1,wreg2,#imm8
        sub     wreg1,wreg2,#imm16
        sub     wreg1,wreg2,wreg3
        sub     wreg1,wreg2,addr16
        sub     wreg1,wreg2,[wreg3]
        sub     wreg1,wreg2,[wreg3]+
        sub     wreg1,wreg2,addr8[wreg3]
        sub     wreg1,wreg2,addr16[wreg3]
;-------------------------------------

;-------------------------------------
; SUBB - subtract byte
        subb    breg1,#imm8
        subb    breg1,breg2
        subb    breg1,addr16
        subb    breg1,[wreg2]
        subb    breg1,[wreg2]+
        subb    breg1,addr8[wreg2]
        subb    breg1,addr16[wreg2]

        subb    breg1,breg2,#imm8
        subb    breg1,breg2,breg3
        subb    breg1,breg2,addr16
        subb    breg1,breg2,[wreg3]
        subb    breg1,breg2,[wreg3]+
        subb    breg1,breg2,addr8[wreg3]
        subb    breg1,breg2,addr16[wreg3]
;-------------------------------------


;-------------------------------------
; SUBC - subtract word with carry
        subc    wreg1,#imm8
        subc    wreg1,#imm16
        subc    wreg1,wreg2
        subc    wreg1,addr16
        subc    wreg1,[wreg2]
        subc    wreg1,[wreg2]+
        subc    wreg1,addr8[wreg2]
        subc    wreg1,addr16[wreg2]

        ; No three arg form for subc
;-------------------------------------

;-------------------------------------
; SUBCB - subtract byte with carry
        subcb   breg1,#imm8
        subcb   breg1,breg2
        subcb   breg1,addr16
        subcb   breg1,[wreg2]
        subcb   breg1,[wreg2]+
        subcb   breg1,addr8[wreg2]
        subcb   breg1,addr16[wreg2]

        ; No three arg form for subcb
;-------------------------------------


;-------------------------------------
; tijmp - table indirect jump
        tijmp   wreg1,[wreg2],#imm8
        tijmp   wreg2,[wreg1],#imm8
        tijmp   wreg3,[wreg2],#13
;-------------------------------------

;-------------------------------------
; TRAP - software trap
        trap
;-------------------------------------

;-------------------------------------
; XCH - exchange word
        xch     wreg1,wreg2
        xch     wreg1,addr16
        xch     wreg1,addr8[wreg2]
        xch     wreg1,addr16[wreg2]
;-------------------------------------

;-------------------------------------
; XCHB - exchange byte
        xchb    breg1,breg2
        xchb    breg1,addr16
        xchb    breg1,addr8[wreg2]
        xchb    breg1,addr16[wreg2]
;-------------------------------------


;-------------------------------------
; XOR 
        xor     wreg1,#imm8
        xor     wreg1,#imm16
        xor     wreg1,wreg2
        xor     wreg1,addr16
        xor     wreg1,[wreg2]
        xor     wreg1,[wreg2]+
        xor     wreg1,addr8[wreg2]
        xor     wreg1,addr16[wreg2]

        ; No three arg form for xor 
;-------------------------------------

;-------------------------------------
; XORB  
        xorb    breg1,#imm8
        xorb    breg1,breg2
        xorb    breg1,addr16
        xorb    breg1,[wreg2]
        xorb    breg1,[wreg2]+
        xorb    breg1,addr8[wreg2]
        xorb    breg1,addr16[wreg2]

        ; No three arg form for xorb 
;-------------------------------------

        END
