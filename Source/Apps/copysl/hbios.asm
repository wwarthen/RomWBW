;
; HBIOS FUNCTIONS
;
;
BF_DIO          .EQU    010H
BF_DIOSTATUS    .EQU    BF_DIO + 0  ; DISK STATUS
BF_DIORESET     .EQU    BF_DIO + 1  ; DISK RESET
BF_DIOSEEK      .EQU    BF_DIO + 2  ; DISK SEEK
BF_DIOREAD      .EQU    BF_DIO + 3  ; DISK READ SECTORS
BF_DIOWRITE     .EQU    BF_DIO + 4  ; DISK WRITE SECTORS
BF_DIOVERIFY    .EQU    BF_DIO + 5  ; DISK VERIFY SECTORS
BF_DIOFORMAT    .EQU    BF_DIO + 6  ; DISK FORMAT TRACK
BF_DIODEVICE    .EQU    BF_DIO + 7  ; DISK DEVICE INFO REPORT
BF_DIOMEDIA     .EQU    BF_DIO + 8  ; DISK MEDIA REPORT
BF_DIODEFMED    .EQU    BF_DIO + 9  ; DEFINE DISK MEDIA
BF_DIOCAP       .EQU    BF_DIO + 10 ; DISK CAPACITY REPORT
BF_DIOGEOM      .EQU    BF_DIO + 11 ; DISK GEOMETRY REPORT
;
BF_SYS          .EQU    0F0H
BF_SYSRESET     .EQU    BF_SYS + 0  ; SOFT RESET HBIOS
BF_SYSVER       .EQU    BF_SYS + 1  ; GET HBIOS VERSION
BF_SYSSETBNK    .EQU    BF_SYS + 2  ; SET CURRENT BANK
BF_SYSGETBNK    .EQU    BF_SYS + 3  ; GET CURRENT BANK
BF_SYSSETCPY    .EQU    BF_SYS + 4  ; BANK MEMORY COPY SETUP
BF_SYSBNKCPY    .EQU    BF_SYS + 5  ; BANK MEMORY COPY
BF_SYSALLOC     .EQU    BF_SYS + 6  ; ALLOC HBIOS HEAP MEMORY
BF_SYSFREE      .EQU    BF_SYS + 7  ; FREE HBIOS HEAP MEMORY
BF_SYSGET       .EQU    BF_SYS + 8  ; GET HBIOS INFO
BF_SYSSET       .EQU    BF_SYS + 9  ; SET HBIOS PARAMETERS
BF_SYSPEEK      .EQU    BF_SYS + 10 ; GET A BYTE VALUE FROM ALT BANK
BF_SYSPOKE      .EQU    BF_SYS + 11 ; SET A BYTE VALUE IN ALT BANK
BF_SYSINT       .EQU    BF_SYS + 12 ; MANAGE INTERRUPT VECTORS
;
BF_SYSGET_CIOCNT    .EQU    00h ; GET CHAR UNIT COUNT
BF_SYSGET_CIOFN     .EQU    01h ; GET CIO UNIT FN/DATA ADR
BF_SYSGET_DIOCNT    .EQU    10h ; GET DISK UNIT COUNT
BF_SYSGET_DIOFN     .EQU    11h ; GET DIO UNIT FN/DATA ADR
BF_SYSGET_RTCCNT    .EQU    20h ; GET RTC UNIT COUNT
BF_SYSGET_DSKYCNT   .EQU    30h ; GET DSKY UNIT COUNT
BF_SYSGET_VDACNT    .EQU    40h ; GET VDA UNIT COUNT
BF_SYSGET_VDAFN     .EQU    41h ; GET VDA UNIT FN/DATA ADR
BF_SYSGET_SNDCNT    .EQU    50h ; GET VDA UNIT COUNT
BF_SYSGET_SNDFN     .EQU    51h ; GET SND UNIT FN/DATA ADR
BF_SYSGET_TIMER     .EQU    0D0h ; GET CURRENT TIMER VALUE
BF_SYSGET_SECS      .EQU    0D1h ; GET CURRENT SECONDS VALUE
BF_SYSGET_BOOTINFO  .EQU    0E0h ; GET BOOT INFORMATION
BF_SYSGET_CPUINFO   .EQU    0F0h ; GET CPU INFORMATION
BF_SYSGET_MEMINFO   .EQU    0F1h ; GET MEMORY CAPACTITY INFO
BF_SYSGET_BNKINFO   .EQU    0F2h ; GET BANK ASSIGNMENT INFO
BF_SYSGET_CPUSPD    .EQU    0F3h ; GET CLOCK SPEED & WAIT STATES
BF_SYSGET_PANEL     .EQU    0F4h ; GET FRONT PANEL SWITCHES VAL
BF_SYSGET_APPBNKS   .EQU    0F5h ; GET APP BANK INFORMATION
;
; MEDIA ID VALUES
;
MID_NONE    .EQU    0
MID_MDROM   .EQU    1
MID_MDRAM   .EQU    2
MID_RF      .EQU    3
MID_HD      .EQU    4
MID_FD720   .EQU    5
MID_FD144   .EQU    6
MID_FD360   .EQU    7
MID_FD120   .EQU    8
MID_FD111   .EQU    9
MID_HDNEW   .EQU    10

; -----------------
;
; Read timer in sconds.
;
sysgetseconds:
    ld  b,BF_SYSGET
    ld  c,BF_SYSGET_SECS
    rst 08          ; do it
    ret

; -----------------
;
; Return non zero if A (media ID)
; is a type of hard drive
; If not A=0 and Z flag is set
;
isaharddrive:
    cp  MID_HD
    jr  z, ishdd1
    cp  MID_HDNEW
    jr  z, ishdd1
    xor a ; clear A and set Z flag
    ret
ishdd1:
    or a ; set Z flag and return
    ret

; -------------------------------------
;
; used to pass the buffer address argument
;
bankid      .DB 0       ; bank id used for read writes
dma         .DW 8000h   ; address argument for read write
;
;
; basic setup for disk io
; call to get the current bank IO
;
initdiskio:
    ; Get current RAM bank
    ld      b,BF_SYSGETBNK  ; HBIOS GetBank function
    RST     08          ; do it via RST vector, C=bank id
    JP      NZ, err_hbios
    ld      a,c         ; put bank id in A
    ld      (bankid),a  ; put bank id in Argument
    RET
;
;
; Read disk sector(s)
; DE:HL is LBA, B is sector count, C is disk unit
; (dma) is the buffer address
; (bankid) is the memory bank
; Returns E sectors read, and A status
;
diskread:
    ; Seek to requested sector in DE:HL
    push    bc          ; save unit & count
    set 7,d         ; set LBA access flag
    ld  b,BF_DIOSEEK        ; HBIOS func: seek
    rst 08          ; do it
    pop bc          ; recover unit & count
    jp  nz,err_diskio       ; handle error

    ; Read sector(s) into buffer
    ld  e,b         ; transfer count
    ld  b,BF_DIOREAD        ; HBIOS func: disk read
    ld  hl,(dma)        ; read into info sec buffer
    ld  a,(bankid)      ; user bank
    ld  d,a
    rst 08          ; do it
    jp  nz,err_diskio       ; handle error
    xor a           ; signal success
    ret             ; and done
;
; Write disk sector(s)
; DE:HL is LBA, B is sector count, C is disk unit
; (dma) is the buffer address
; (bankid) is the memory bank
; Returns E sectors written, and A status
;
diskwrite:
    ; Seek to requested sector in DE:HL
    push bc             ; save unit & count
    set 7,d             ; set LBA access flag
    ld  b,BF_DIOSEEK    ; HBIOS func: seek
    rst 08              ; do it
    pop bc              ; recover unit & count
    jp  nz,err_diskio   ; handle error

    ; Write sector(s) from buffer
    ld  e,b             ; transfer count
    ld  b,BF_DIOWRITE   ; HBIOS func: disk write
    ld  hl,(dma)        ; write from sec buffer
    ld  a,(bankid)      ; user bank
    ld  d,a
    rst 08              ; do it
    jp  nz,err_diskio   ; handle error
    xor a               ; signal success
    ret                 ; and done
;
err_diskio:
;    push    hl
;    ld      hl,str_err_prefix
;    call    prtstr
;    pop     hl
;    or      0ffh        ; signal error
    ret     ; done

;str_err_prefix  db 13,10,13,10,"*** ",0


