;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; btromwbw.inc 2/17/2013 dwg - boot up CP/M, RomWBW Style   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unlike the Monahan style of booting, the RomWBW loading   ;
; is performed by reading in the metadata sector and using  ;
; the three words at the end of the sector to determine the ;
; loading address and starting location.                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-------------- BOOT UP CPM FROM HARD DISK ON S100COMPUTERS IDR BOARD ----------------

;BOOT UP THE 8255/IDE Board HARD DISK/Flash Memory Card
;NOTE CODE IS ALL HERE IN CASE A 2716 IS USED

HBOOTWBW:
        POP     HL                      ;CLEAN UP STACK

        CALL    INITILIZE_IDE_BOARD     ;Initilze the 8255 and drive (again just in case)

        LD      D,11100000B             ;Data for IDE SDH reg (512bytes, LBA mode,single drive)
        LD      E,REGshd                ;00001110,(0EH) CS0,A2,A1,
        CALL    IDEwr8D                 ;Write byte to select the MASTER device

        LD      B,0FFH                  ;Delay time to allow a Hard Disk to get up to speed
WaitInitX:
        LD      E,REGstatus             ;Get status after initilization
        CALL    IDErd8D                 ;Check Status (info in [D])
        BIT     7,D
        JR      Z,SECREADX               ;Zero, so all is OK to write to drive
                                        ;Delay to allow drive to get up to speed
        PUSH    BC
        LD      BC,0FFFFH
DXLAY2X: LD      D,2                     ;May need to adjust delay time to allow cold drive to
DXLAY1X: DEC     D                       ;to speed
        JR      NZ,DXLAY1X
        DEC     BC
        LD      A,C
        OR      B
        JR      NZ,DXLAY2X
        POP     BC
        DJNZ    WaitInitX                ;If after 0FFH, 0FEH, 0FDH... 0, then drive initilization problem
IDErrorX:
        LD      HL,DRIVE_NR_ERR         ;Drive not ready
        JP      ABORT_ERR_MSG

SECREADX:                                ;Note CPMLDR will ALWAYS be on TRK 0,SEC 1,Head 0
        CALL    IDEwaitnotbusy          ;Make sure drive is ready
        JR      C,IDErrorX               ;NC if ready
        LD      D,1                     ;Load track 0,sec 1, head 0
        LD      E,REGsector             ;Send info to drive
        CALL    IDEwr8D

        LD      D,0                     ;Send Low TRK#
        LD      E,REGcyLSB
        CALL    IDEwr8D

        LD      D,0                     ;Send High TRK#
        LD      E,REGcyMSB
        CALL    IDEwr8D

        LD      D,SEC_COUNT             ;Count of CPM sectors we wish to read
        LD      E,REGcnt
        CALL    IDEwr8D

        LD      D,CMDread               ;Send read CMD
        LD      E,REGCMD
        CALL    IDEwr8D                 ;Send sec read CMD to drive.
        CALL    IDEwdrq                 ;Wait until it's got the data

        LD      HL,CPM_ADDRESS          ;DMA address where the CPMLDR resides in RAM
        LD      B,0                     ;256X2 bytes
        LD      C,SEC_COUNT             ;Count of sectors X 512
MoreRD16X:
        LD      A,REGdata               ;REG regsiter address
        OUT     (IDECport),A

        OR      IDErdline               ;08H+40H, Pulse RD line
        OUT     (IDECport),A

        IN      A,(IDEAport)            ;read the LOWER byte
        LD      (HL),A
        INC     HL
        IN      A,(IDEBport)            ;read the UPPER byte
        LD      (HL),A
        INC     HL

        LD      A,REGdata               ;Deassert RD line
        OUT     (IDECport),A
        DJNZ    MoreRD16X
        DEC     C
        JR      NZ,MoreRD16X

        LD      E,REGstatus             ;Check the R/W status when done
        CALL    IDErd8D
        BIT     0,D
        JR      NZ,IDEerr1X              ;Z if no errors
        LD      HL,STARTCPM
        LD      A,(HL)
        CP      31H                     ;EXPECT TO HAVE 31H @80H IE. LD SP,80H
        JP      Z,STARTCPM              ;AS THE FIRST INSTRUCTION. IF OK JP to 100H in RAM
        JP      ERR_LD1                 ;Boot Sector Data incorrect

IDEerr1X:
        LD      HL,IDE_RW_ERROR         ;Drive R/W Error
        JP      ABORT_ERR_MSG

;;;;;;;;;;;;;;;;;;;;;;
; eof - btromwbw.inc ;
;;;;;;;;;;;;;;;;;;;;;;

