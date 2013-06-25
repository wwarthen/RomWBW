;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test85.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: 8080/8085
;



idata16  .equ    1234h
idata8   .equ    12h
port     .equ    34h
addr16   .equ    5678h

        .org 1000h

start:
        nop
        lxi     b,idata16
        stax    b
        inx     b
        inr     b
        dcr     b
        mvi     b,idata8
        rlc

        dad     b
        ldax    b
        dcx     b
        inr     c
        dcr     c
        mvi     c,idata8
        rrc

;       ---                     ; 10
        lxi     d,idata16
        stax    d
        inx     d
        inr     d
        dcr     d
        mvi     d,idata8
        ral
;       ---
        dad     d
        ldax    d
        dcx     d
        inr     e
        dcr     e
        mvi     e,idata8
        rar

        rim                     ; 20
        lxi     h,idata16
        shld    addr16
        inx     h
        inr     h
        dcr     h
        mvi     h,idata8
        daa
;       ---
        dad     h
        lhld    addr16
        dcx     h
        inr     l
        dcr     l
        mvi     l,idata8
        cma

        sim                     ; 30
        lxi     sp,idata16
        sta     addr16
        inx     sp
        inr     m
        dcr     m
        mvi     m,idata8
        stc
;       ---
        dad     sp
        lda     addr16
        dcx     sp
        inr     a
        dcr     a
        mvi     a,idata8
        cmc

        mov     b,b             ; 40
        mov     b,c
        mov     b,d
        mov     b,e
        mov     b,h
        mov     b,l
        mov     b,m
        mov     b,a
        mov     c,b
        mov     c,c
        mov     c,d
        mov     c,e
        mov     c,h
        mov     c,l
        mov     c,m
        mov     c,a

        mov     d,b             ; 50
        mov     d,c
        mov     d,d
        mov     d,e
        mov     d,h
        mov     d,l
        mov     d,m
        mov     d,a
        mov     e,b
        mov     e,c
        mov     e,d
        mov     e,e
        mov     e,h
        mov     e,l
        mov     e,m
        mov     e,a

        mov     h,b             ; 60
        mov     h,c
        mov     h,d
        mov     h,e
        mov     h,h
        mov     h,l
        mov     h,m
        mov     h,a
        mov     l,b
        mov     l,c
        mov     l,d
        mov     l,e
        mov     l,h
        mov     l,l
        mov     l,m
        mov     l,a

        mov     m,b             ; 70
        mov     m,c
        mov     m,d
        mov     m,e
        mov     m,h
        mov     m,l
        hlt
        mov     m,a
        mov     a,b
        mov     a,c
        mov     a,d
        mov     a,e
        mov     a,h
        mov     a,l
        mov     a,m
        mov     a,a

        add     b               ; 80
        add     c
        add     d
        add     e
        add     h
        add     l
        add     m
        add     a
        adc     b               ; 88
        adc     c
        adc     d
        adc     e
        adc     h
        adc     l
        adc     m
        adc     a

        sub     b               ; 90
        sub     c
        sub     d
        sub     e
        sub     h
        sub     l
        sub     m
        sub     a
        sbb     b               ; 98
        sbb     c
        sbb     d
        sbb     e
        sbb     h
        sbb     l
        sbb     m
        sbb     a

        ana     b               ; a0
        ana     c
        ana     d
        ana     e
        ana     h
        ana     l
        ana     m
        ana     a
        xra     b               ; a8
        xra     c
        xra     d
        xra     e
        xra     h
        xra     l
        xra     m
        xra     a

        ora     b               ; b0
        ora     c
        ora     d
        ora     e
        ora     h
        ora     l
        ora     m
        ora     a
        cmp     b               ; b8
        cmp     c
        cmp     d
        cmp     e
        cmp     h
        cmp     l
        cmp     m
        cmp     a

        rnz                     ; c0
        pop     b
        jnz     start
        jmp     start
        cnz     start
        push    b
        adi     idata8
        rst     0
        rz
        ret
        jz      start
;       ---
        cz      start
        call    start
        aci     idata8
        rst     1

        rnc                     ; d0
        pop     d
        jnc     start
        out     port
        cnc     start
        push    d
        sui     idata8
        rst     2
        rc
;       ---
        jc      start
        in      port
        cc      start
;       ---
        sbi     idata8
        rst     3

        rpo                     ; e0
        pop     h
        jpo     start
        xthl
        cpo     start
        push    h
        ani     idata8
        rst     4
        rpe
        pchl
        jpe     start
        xchg
        cpe     start
;       ---
        xri     idata8
        rst     5

        rp                      ; f0
        pop     psw
        jp      start
        di
        cp      start
        push    psw
        ori     idata8
        rst     6
        rm
        sphl
        jm      start
        ei
        cm      start
;       ---
        cpi     idata8
        rst     7

        .END

