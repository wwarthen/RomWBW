;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test3210.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor: TMS32010
;


        .org 100h
shift   .equ 4
shift0  .equ 0
addr    .equ 12h
port    .equ 2
arp     .equ 1
ar      .equ 1
const   .equ 34h
const1  .equ  1h

        ABS                ;7F88 2 NOP 1
        
        ADD  *+,shift,arp  ;00A0 2 T1   1 8 0F00
        ADD  *-,shift,arp  ;0090 2 T1   1 8 0F00
        ADD  *,shift,arp   ;0080 2 T1   1 8 0F00
        ADD  *+,shift      ;00A8 2 T1   1 8 0F00
        ADD  *-,shift      ;0098 2 T1   1 8 0F00
        ADD  *,shift       ;0088 2 T1   1 8 0F00
        ADD  *+            ;00A8 2 NOP  1
        ADD  *-            ;0098 2 NOP  1
        ADD  *             ;0088 2 NOP  1
        ADD  addr,shift    ;0000 2 TDMA 1 8 0F00
        ADD  addr          ;0000 2 T1   1 0 007F
        
        ADDH *+,arp        ;60A0 2 T1   1 0 01
        ADDH *-,arp        ;6090 2 T1   1 0 01
        ADDH *,arp         ;6080 2 T1   1 0 01
        ADDH *+            ;60A8 2 NOP  1
        ADDH *-            ;6098 2 NOP  1
        ADDH *             ;6088 2 NOP  1
        ADDH addr          ;6000 2 T1   1 0 007F
        
        ADDS *+,arp        ;61A0 2 T1   1 0 01
        ADDS *-,arp        ;6190 2 T1   1 0 01
        ADDS *,arp         ;6180 2 T1   1 0 01
        ADDS *+            ;61A8 2 NOP  1
        ADDS *-            ;6198 2 NOP  1
        ADDS *             ;6188 2 NOP  1
        ADDS addr          ;6100 2 T1   1 0 007F
        
        AND  *+,arp        ;79A0 2 T1   1 0 01
        AND  *-,arp        ;7990 2 T1   1 0 01
        AND  *,arp         ;7980 2 T1   1 0 01
        AND  *+            ;79A8 2 NOP  1
        AND  *-            ;7998 2 NOP  1
        AND  *             ;7988 2 NOP  1
        AND  addr          ;7900 2 T1   1 0 7F
        
        APAC               ;7F8F 2 NOP  1

loop1:
        B    loop1         ;F900 4 SWAP 1
        BANZ loop1         ;F400 4 SWAP 1
        BGEZ loop1         ;FD00 4 SWAP 1
        BGZ  loop1         ;FC00 4 SWAP 1
        BIOZ loop1         ;F600 4 SWAP 1
        BLEZ loop1         ;FB00 4 SWAP 1
        BLZ  loop1         ;FA00 4 SWAP 1
        BNZ  loop1         ;FE00 4 SWAP 1
        BV   loop1         ;F500 4 SWAP 1
        BZ   loop1         ;FF00 4 SWAP 1

        CALA               ;7F8C 2 NOP  1
        CALL loop1         ;F800 4 SWAP 1
        DINT               ;7F81 2 NOP  1
        
        DMOV *+,arp        ;69A0 2 T1   1 0 01
        DMOV *-,arp        ;6990 2 T1   1 0 01
        DMOV *,arp         ;6980 2 T1   1 0 01
        DMOV *+            ;69A8 2 NOP  1
        DMOV *-            ;6998 2 NOP  1
        DMOV *             ;6988 2 NOP  1
        DMOV addr          ;6900 2 T1   1 0 007F
        
        EINT               ;7F82 2 NOP  1
        
        IN   *+,port ,arp  ;40A0 2 T1   1 8 0700
        IN   *-,port ,arp  ;4090 2 T1   1 8 0700
        IN   * ,port ,arp  ;4080 2 T1   1 8 0700
        IN   *+,port       ;40A8 2 T1   1 8 0700
        IN   *-,port       ;4098 2 T1   1 8 0700
        IN   * ,port       ;4088 2 T1   1 8 0700
        IN   addr,port     ;4000 2 TDMA 1 8 0700
        
        LAC  *+,shift,arp  ;20A0 2 T1   1 8 0F00
        LAC  *-,shift,arp  ;2090 2 T1   1 8 0F00
        LAC  *,shift,arp   ;2080 2 T1   1 8 0F00
        LAC  *+,shift      ;20A8 2 T1   1 8 0F00
        LAC  *-,shift      ;2098 2 T1   1 8 0F00
        LAC  *,shift       ;2088 2 T1   1 8 0F00
        LAC  *+            ;20A8 2 NOP  1
        LAC  *-            ;2098 2 NOP  1
        LAC  *             ;2088 2 NOP  1
        LAC  addr,shift    ;2000 2 TDMA 1 8 0F00
        LAC  addr          ;2000 2 T1   1 0 007F
        
        LACK const         ;7E00 2 T1   1 0 00FF
        
        LAR  ar,*+,arp     ;38A0 2 TAR  1 0 0001
        LAR  ar,*-,arp     ;3890 2 TAR  1 0 0001
        LAR  ar,*,arp      ;3880 2 TAR  1 0 0001
        LAR  ar,*+         ;38A8 2 TAR  1 0 0001
        LAR  ar,*-         ;3898 2 TAR  1 0 0001
        LAR  ar,*          ;3888 2 TAR  1 0 0001
        LAR  ar, addr      ;3800 2 TAR  1 0 007F
        
        LARK ar,const      ;7000 2 TAR  1 0 00FF
        LARP const1        ;6880 2 T1   1 0 0001
        
        LDP  *+,arp        ;6FA0 2 T1   1 0 01
        LDP  *-,arp        ;6F90 2 T1   1 0 01
        LDP  *,arp         ;6F80 2 T1   1 0 01
        LDP  *+            ;6FA8 2 NOP  1
        LDP  *-            ;6F98 2 NOP  1
        LDP  *             ;6F88 2 NOP  1
        LDP  addr          ;6F00 2 T1   1 0 007F
        
        LDPK const1        ;6E00 2 T1   1 0 01
        
        LST  *+,arp        ;7BA0 2 T1   1 0 01
        LST  *-,arp        ;7B90 2 T1   1 0 01
        LST  *,arp         ;7B80 2 T1   1 0 01
        LST  *+            ;7BA8 2 NOP  1
        LST  *-            ;7B98 2 NOP  1
        LST  *             ;7B88 2 NOP  1
        LST  addr          ;7B00 2 T1   1 0 007F
        
        LT   *+,arp        ;6AA0 2 T1   1 0 01
        LT   *-,arp        ;6A90 2 T1   1 0 01
        LT   *,arp         ;6A80 2 T1   1 0 01
        LT   *+            ;6AA8 2 NOP  1
        LT   *-            ;6A98 2 NOP  1
        LT   *             ;6A88 2 NOP  1
        LT   addr          ;6A00 2 T1   1 0 007F
        
        LTA  *+,arp        ;6CA0 2 T1   1 0 01
        LTA  *-,arp        ;6C90 2 T1   1 0 01
        LTA  *,arp         ;6C80 2 T1   1 0 01
        LTA  *+            ;6CA8 2 NOP  1
        LTA  *-            ;6C98 2 NOP  1
        LTA  *             ;6C88 2 NOP  1
        LTA  addr          ;6C00 2 T1   1 0 007F
        
        LTD  *+,arp        ;6BA0 2 T1   1 0 01
        LTD  *-,arp        ;6B90 2 T1   1 0 01
        LTD  *,arp         ;6B80 2 T1   1 0 01
        LTD  *+            ;6BA8 2 NOP  1
        LTD  *-            ;6B98 2 NOP  1
        LTD  *             ;6B88 2 NOP  1
        LTD  addr          ;6B00 2 T1   1 0 007F
        
        MAR  *+,arp        ;68A0 2 T1   1 0 01
        MAR  *-,arp        ;6890 2 T1   1 0 01
        MAR  *,arp         ;6880 2 T1   1 0 01
        MAR  *+            ;68A8 2 NOP  1
        MAR  *-            ;6898 2 NOP  1
        MAR  *             ;6888 2 NOP  1
        MAR  addr          ;6800 2 T1   1 0 007F
        
        MPY  *+,arp        ;6DA0 2 T1   1 0 01
        MPY  *-,arp        ;6D90 2 T1   1 0 01
        MPY  *,arp         ;6D80 2 T1   1 0 01
        MPY  *+            ;6DA8 2 NOP  1
        MPY  *-            ;6D98 2 NOP  1
        MPY  *             ;6D88 2 NOP  1
        MPY  addr          ;6D00 2 T1   1 0 007F
        
        MPYK const         ;8000 2 T1   1 0 1FFF
        
        NOP                ;7F80 2 NOP  1
        
        OR   *+,arp        ;7AA0 2 T1   1 0 01
        OR   *-,arp        ;7A90 2 T1   1 0 01
        OR   *,arp         ;7A80 2 T1   1 0 01
        OR   *+            ;7AA8 2 NOP  1
        OR   *-            ;7A98 2 NOP  1
        OR   *             ;7A88 2 NOP  1
        OR   addr          ;7A00 2 T1   1 0 007F
        
        OUT  *+,port,arp   ;48A0 2 T1   1 8 0700
        OUT  *-,port,arp   ;4890 2 T1   1 8 0700
        OUT  *, port,arp   ;4880 2 T1   1 8 0700
        OUT  *+,port       ;48A8 2 T1   1 8 0700
        OUT  *-,port       ;4898 2 T1   1 8 0700
        OUT  *, port       ;4888 2 T1   1 8 0700
        OUT  addr,port     ;4800 2 TDMA 1 8 0700
        
        PAC                ;7F8E 2 NOP  1
        POP                ;7F9D 2 NOP  1
        PUSH               ;7F9C 2 NOP  1
        RET                ;7F8D 2 NOP  1
        ROVM               ;7F8A 2 NOP  1

;Note that shift count can only be 0,1, or 4.  
;Mask also allows 5.  Beware.
        SACH *+,shift,arp  ;58A0 2 T1   1 8 0500
        SACH *-,shift,arp  ;5890 2 T1   1 8 0500
        SACH *, shift,arp  ;5880 2 T1   1 8 0500
        SACH *+,shift      ;58A8 2 T1   1 8 0500
        SACH *-,shift      ;5898 2 T1   1 8 0500
        SACH *, shift      ;5888 2 T1   1 8 0500
        SACH *+            ;58A8 2 NOP  1
        SACH *-            ;5898 2 NOP  1
        SACH *             ;5888 2 NOP  1
        SACH addr,shift    ;5800 2 TDMA 1 8 0500
        SACH addr          ;5800 2 T1   1 0 007F
  
; Shift count must be zero  for SACL      
        SACL *+,shift0,arp ;50A0 2 T1   1 8 0000
        SACL *-,shift0,arp ;5090 2 T1   1 8 0000
        SACL *, shift0,arp ;5080 2 T1   1 8 0000
        SACL *+,shift0     ;50A8 2 T1   1 8 0000
        SACL *-,shift0     ;5098 2 T1   1 8 0000
        SACL *, shift0     ;5088 2 T1   1 8 0000
        SACL *+            ;50A8 2 NOP  1
        SACL *-            ;5098 2 NOP  1
        SACL *             ;5088 2 NOP  1
        SACL addr,shift0   ;5000 2 TDMA 1 8 0000
        SACL addr          ;5000 2 T1   1 0 007F
        
        SAR  ar,*+,arp     ;30A0 2 TAR  1 0 0001
        SAR  ar,*-,arp     ;3090 2 TAR  1 0 0001
        SAR  ar,*,arp      ;3080 2 TAR  1 0 0001
        SAR  ar,*+         ;30A8 2 TAR  1 0 0001
        SAR  ar,*-         ;3098 2 TAR  1 0 0001
        SAR  ar,*          ;3088 2 TAR  1 0 0001
        SAR  ar,addr       ;3000 2 TAR  1 0 007F
        
        SOVM               ;7F8B 2 NOP  1
        SPAC               ;7F90 2 NOP  1
        
        SST  *+,arp        ;7CA0 2 T1   1 0 0001
        SST  *-,arp        ;7C90 2 T1   1 0 0001
        SST  *,arp         ;7C80 2 T1   1 0 0001
        SST  *+            ;7CA8 2 NOP  1
        SST  *-            ;7C98 2 NOP  1
        SST  *             ;7C88 2 NOP  1
        SST  addr          ;7C00 2 T1   1 0 007F
        
        SUB  *+,shift,arp  ;10A0 2 T1   1 8 0F00
        SUB  *-,shift,arp  ;1090 2 T1   1 8 0F00
        SUB  *, shift,arp  ;1080 2 T1   1 8 0F00
        SUB  *+,shift      ;10A8 2 T1   1 8 0F00
        SUB  *-,shift      ;1098 2 T1   1 8 0F00
        SUB  *, shift      ;1088 2 T1   1 8 0F00
        SUB  *+            ;10A8 2 NOP  1
        SUB  *-            ;1098 2 NOP  1
        SUB  *             ;1088 2 NOP  1
        SUB  addr,shift    ;1000 2 TDMA 1 8 0F00
        SUB  addr          ;1000 2 T1   1 0 007F
        
        SUBC *+,arp        ;64A0 2 T1   1 0 01
        SUBC *-,arp        ;6490 2 T1   1 0 01
        SUBC *,arp         ;6480 2 T1   1 0 01
        SUBC *+            ;64A8 2 NOP  1
        SUBC *-            ;6498 2 NOP  1
        SUBC *             ;6488 2 NOP  1
        SUBC addr          ;6400 2 T1   1 0 007F
        
        SUBH *+,arp        ;62A0 2 T1   1 0 01
        SUBH *-,arp        ;6290 2 T1   1 0 01
        SUBH *,arp         ;6280 2 T1   1 0 01
        SUBH *+            ;62A8 2 NOP  1
        SUBH *-            ;6298 2 NOP  1
        SUBH *             ;6288 2 NOP  1
        SUBH addr          ;6200 2 T1   1 0 007F
        
        SUBS *+,arp        ;63A0 2 T1   1 0 01
        SUBS *-,arp        ;6390 2 T1   1 0 01
        SUBS *,arp         ;6380 2 T1   1 0 01
        SUBS *+            ;63A8 2 NOP  1
        SUBS *-            ;6398 2 NOP  1
        SUBS *             ;6388 2 NOP  1
        SUBS addr          ;6300 2 T1   1 0 007F
        
        TBLR *+,arp        ;67A0 2 T1   1 0 01
        TBLR *-,arp        ;6790 2 T1   1 0 01
        TBLR *,arp         ;6780 2 T1   1 0 01
        TBLR *+            ;67A8 2 NOP  1
        TBLR *-            ;6798 2 NOP  1
        TBLR *             ;6788 2 NOP  1
        TBLR addr          ;6700 2 T1   1 0 007F
        
        TBLW *+,arp        ;7DA0 2 T1   1 0 01
        TBLW *-,arp        ;7D90 2 T1   1 0 01
        TBLW *,arp         ;7D80 2 T1   1 0 01
        TBLW *+            ;7DA8 2 NOP  1
        TBLW *-            ;7D98 2 NOP  1
        TBLW *             ;7D88 2 NOP  1
        TBLW addr          ;7D00 2 T1   1 0 007F
        
        XOR  *+,arp        ;78A0 2 T1   1 0 01
        XOR  *-,arp        ;7890 2 T1   1 0 01
        XOR  *,arp         ;7880 2 T1   1 0 01
        XOR  *+            ;78A8 2 NOP  1
        XOR  *-            ;7898 2 NOP  1
        XOR  *             ;7888 2 NOP  1
        XOR addr           ;7800 2 T1   1 0 007F
        
        ZAC                ;7F89 2 NOP  1
        
        ZALH *+,arp        ;65A0 2 T1   1 0 01
        ZALH *-,arp        ;6590 2 T1   1 0 01
        ZALH *,arp         ;6580 2 T1   1 0 01
        ZALH *+            ;65A8 2 NOP  1
        ZALH *-            ;6598 2 NOP  1
        ZALH *             ;6588 2 NOP  1
        ZALH addr          ;6500 2 T1   1 0 007F
        
        ZALS *+,arp        ;66A0 2 T1   1 0 01
        ZALS *-,arp        ;6690 2 T1   1 0 01
        ZALS *,arp         ;6680 2 T1   1 0 01
        ZALS *+            ;66A8 2 NOP  1
        ZALS *-            ;6698 2 NOP  1
        ZALS *             ;6688 2 NOP  1
        ZALS addr          ;6600 2 T1   1 0 007F
        .end
