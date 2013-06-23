;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test65.asm 1.2 1997/11/29 13:07:53 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: 6502
;



#define FLAG1
#define TORG    $1234
        .org    $56
zlabel  .byte   $12
        .word   $1234
        .word   $1234/3
        .word   1234h
        .word   %0101010
        .word    0101010b
        .word   @1234
        .word    1234o
        .word   1234
        .word   1234d
        .word   0d
        .word   1d
        .word   2d
        .word   3d
        .word   4d
        .word   10d
        .word   20d
        .word   100d
        .word   *
        .word   $
        .word   3 * 7
        .word   3 + 7
        .word   3 - 7
        .word   73 % 7
        .word   $1234 >> 4
        .word   $1234 << 4
        .word   1 = 1
        .word   1 = 0
        .word   1 >= 1
        .word   1 >= 2
        .word   1 >= 0
        .word   1 <= 1
        .word   1 <= 2
        .word   1 <= 0
        .word   1 <= -1
        .word   TORG

        .org    $0234
alabel
        ADC   #zlabel
        ADC   (zlabel,X)
        ADC   (zlabel),Y
        ADC   (zlabel)
        ADC   (alabel & $ff)   ; suppress UNUSED DATA error
        ADC   zlabel,X
        ADC   zlabel,Y
        ADC   zlabel
        ADC   alabel

        AND   #zlabel
        AND   (zlabel,X)
        AND   (zlabel),Y
        AND   (zlabel)
        AND   zlabel,X
        AND   zlabel,Y
        AND   zlabel
        AND   alabel
                                          
        ASL   A
        ASL   zlabel,X
        ASL   zlabel
loop
        BCC   loop
        BCS   loop
        BEQ   loop
        BNE   loop
        BMI   loop
        BPL   loop
        BVC   loop
        BVS   loop

        BIT   #zlabel
        BIT   zlabel,X
        BIT   zlabel
        BIT   alabel

        BRK   

        CLC   
        CLD   
        CLI   
        CLV   

        CMP   #zlabel
        CMP   (zlabel,X)
        CMP   (zlabel),Y
        CMP   (zlabel)
        CMP   zlabel,X
        CMP   zlabel,Y
        CMP   zlabel
        CMP   alabel

        CPX   #zlabel
        CPX   zlabel
        CPX   alabel

        CPY   #zlabel
        CPY   zlabel
        CPY   alabel
            
        DEC   A
        DEC   zlabel,X
        DEC   alabel,X
        DEC   zlabel
        DEC   alabel

        DEX   
        DEY   

        EOR   #zlabel
        EOR   (zlabel,X)
        EOR   (zlabel),Y
        EOR   (zlabel)
        EOR   zlabel,X
        EOR   zlabel,Y
        EOR   zlabel
        EOR   alabel

        INC   A
        INC   zlabel,X
        INC   alabel,X
        INC   zlabel
        INC   alabel

        INX   
        INY   
                               
        JMP   (zlabel,X)
        JMP   (zlabel)
        JMP   zlabel

        JSR   zlabel
        JSR   alabel

        LDA   #zlabel
        LDA   (zlabel,X)
        LDA   (zlabel),Y
        LDA   (zlabel)
        LDA   zlabel,X
        LDA   zlabel,Y
        LDA   zlabel
        LDA   alabel

        LDX   #zlabel
        LDX   zlabel,Y
        LDX   zlabel
        LDX   alabel

        LDY   #zlabel
        LDY   zlabel,X
        LDY   zlabel
        LDY   alabel

        LSR   A
        LSR   zlabel,X
        LSR   zlabel
        LSR   alabel

        NOP   

        ORA   #zlabel
        ORA   (zlabel,X)
        ORA   (zlabel),Y
        ORA   (zlabel)
        ORA   zlabel,X
        ORA   zlabel,Y
        ORA   zlabel
        ORA   alabel
                                   
        PHA   
        PHP   
        PLA   
        PLP   

        ROL   A
        ROL   zlabel,X
        ROL   zlabel
        ROL   alabel

        ROR   A
        ROR   zlabel,X
        ROR   alabel,X
        ROR   zlabel
        ROR   alabel

        RTI   
        RTS   

        SBC   #zlabel
        SBC   (zlabel,X)
        SBC   (zlabel),Y
        SBC   (zlabel)
        SBC   zlabel,X
        SBC   zlabel,Y
        SBC   zlabel
        SBC   alabel
                                     
        SEC   
        SED   
        SEI   

        STA   (zlabel,X)
        STA   (zlabel),Y
        STA   (zlabel)
        STA   zlabel,X
        STA   zlabel,Y
        STA   zlabel
        STA   alabel

        STX   zlabel,Y
        STX   zlabel
        STX   alabel

        STY   zlabel,X
        STY   zlabel
        STY   alabel

        TAX   
        TAY   
        TSX   
        TXA   
        TXS   
        TYA   

        BRA   loop2
loop2
        BBR0   zlabel,loop2
        BBR1   zlabel,loop2
        BBR2   zlabel,loop2
        BBR3   zlabel,loop2
        BBR4   zlabel,loop2
        BBR5   zlabel,loop2
        BBR6   zlabel,loop2
        BBR7   zlabel,loop2
        
        BBS0   zlabel,loop2
        BBS1   zlabel,loop2
        BBS2   zlabel,loop2
        BBS3   zlabel,loop2
        BBS4   zlabel,loop2
        BBS5   zlabel,loop2
        BBS6   zlabel,loop2
        BBS7   zlabel,loop2

        MUL   

        PHX   
        PHY   
        PLX   
        PLY   

        RMB0   zlabel
        RMB1   zlabel
        RMB2   zlabel
        RMB3   zlabel
        RMB4   zlabel
        RMB5   zlabel
        RMB6   zlabel
        RMB7   zlabel

        SMB0   zlabel
        SMB1   zlabel
        SMB2   zlabel
        SMB3   zlabel
        SMB4   zlabel
        SMB5   zlabel
        SMB6   zlabel
        SMB7   zlabel

 
        STZ   zlabel,X
        STZ   zlabel
        STZ   alabel

        TRB   zlabel
        TSB   zlabel
        .end






