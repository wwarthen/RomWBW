;
; Copy Slice - COPYSL.COM
;
; CP/M Command - That will allow the contents of a disk
; slice to be copied (completely) to another slice.
; This depends on running under CP/M 2.2 on a machine with
; an RomWBW HBIOS, and works with both hd1k (modern)
; and hd512 (legacy) disk formats
;
; Versions History
; ----------------
; 0.1 - Initial Version written by Mark Pruden
; 0.2 - Added support for /v (verify) option.
; 0.3 - refresh CP/M disk buffers after completion
; ----------------
;
    .ORG 100H
    jp start
;
    .include "crc.asm"		; comparison of data blocks, used for verify
    .include "cio.asm"		; bdos IO routines
    .include "bdos.asm"		; bdos general routines
    .include "hbios.asm"	; hbios routines
;
; -------------------------
;
mainblkbuf     .EQU 8000h   ; Main Disk IO Buffer
mainblkbuf2    .EQU 9000h   ; Disk Buff for Read Verify
;
xf_sectorcount .EQU 8                    ; sectors to transfer per R/W / Verify
xf_blockbytes  .EQU 512 * xf_sectorcount ; bytes in main transfer buffer
;
; =========================================
; START OF MAIN PROGRAM
; =========================================
;
start:
    ; welcome message
    ld      hl,msg_welcome
    call    prtstr

    ; parse command line args
    call    process_args	; call the cli arg handler
    jp      nz, exit 		; args invalid exit at this point

    ; Inits Disk IO routines. Bank Ram
    call    initdiskio

media_disc1:
    ; sense the media
    ld      a, (args_src_diskunit) ; cmd line parameter
    ld      ix, sourcemedia
    call    sensemedia
    jp      nz, media_err

    ; calc the slice details
    ld      a, (args_src_slice) ; cmd line parameter
    call    slicecalc           ; lba of chosen slice
    jp      nz, slice_def_err

    ; print details of the media
    call    iprtstr
    .DB      13,10,"Source",0
    call    printdetails

media_disc2:
    ; sense the media
    ld      a, (args_target_diskunit)  ; cmd line parameter
    ld      ix, targetmedia
    call    sensemedia
    jp      nz, media_err

    ; calc the slice details
    ld      a, (args_target_slice) ; cmd line parameter
    call    slicecalc              ; lba of chosen slice
    jp      nz, slice_def_err

    ; print details of the media
    call    iprtstr
    .DB      "Target",0
    call    printdetails

check_hard_disc:
    ; ponters to the MCB's of source target
    ld      ix, sourcemedia
    ld      iy, targetmedia

    ; check media type are for HD only, others not supported
    ld      a, (ix+off_mediaid)
    call    isaharddrive
    jp      z, device_type_err

    ; check media type are for HD only, others not supported
    ld      a, (iy+off_mediaid)
    call    isaharddrive
    jp      z, device_type_err

check_layout:
    ; compare disk types hd1k hd512 are identical for source/target
    ld      a, (ix+off_mediaid)
    cp      (iy+off_mediaid)
    jp      nz, device_diff_err

check_same:
    ; check the source drive / slice are NOT the same
    ld      a, (ix + off_diskunit)
    cp      (iy + off_diskunit)
    jr      nz, compare_same ; disk units are differemt
    ld      a, (ix + off_slice)
    cp      (iy + off_slice)
    jr      nz, compare_same ; slices are different
    jp      args_same_err   ; they are the same
compare_same:

    ; if target Slice=0 and hd512
    ld      a, (iy + off_slice) ; check the target slice
    cp      0               ; is Zero
    jr      nz, startprocess ; ignore if slice number is Zero
    ld      a, (iy + off_mediaid)
    cp      MID_HD          ; IS hd512
    jr      nz, startprocess ; ignore if NOT hd512

    ; warn the user about to overite partition
    ld      hl, msg_overite_partition
    call    prtstr

startprocess:
    ; if full copy - SKIP THIS
    ld      a, ( args_option_f ) ; full disk copy argument
    or      a
    jr      nz, fulldiskcopy ; if option then compute full disk

startdirscan:
    ld      hl, msg_parse_dir ; Processing Directory
    CALL    prtstr

    ; init DE HL with sector of first dir entry
    CALL    finddir         ; used by processdir

    ; read and proess 512 directory entries in 32kb buffer
    CALL    processdir
    JP      NZ, io_error

    ; for hd1k - do it twice
    ld      a, (src_mediaid)
    cp      MID_HD
    JR      Z, startdirscan1   ; hd512 only need to scan 1x 32k block

    ; read and proess SECOND 512 directory entries in 32kb buffer
    CALL    processdir ; process second 512 dir entries
    JP      NZ, io_error

startdirscan1:
    ; check we have a legal directory
    ld      a, (illegaldir)     ; flag indicating we found illegal dir
    cp      0
    JR      Z, startdirscan2    ; legal dir so just continue
    ; illegal
    ld      hl, msg_cant_find_dir
    CALL    prtstr              ; illegal directory, so print msg
    JR      fulldiskcopy        ; and do a full disk copy

startdirscan2:
    ; compute number of blocks to transfer based on directory
    CALL    compute_xfer    ; result is in total16xfer

    ; write info about dir entries found, blocks to copy
    CALL    compute_print

    ; now ask for confirmation
    JR      userconfirm ; skip the full disk copy

fulldiskcopy:
    ; copy everthing from source drive
    ld      ix, sourcemedia
    CALL    compute_full    ; result is in total16xfer

userconfirm:
    ; unless an option is provided for unassisted
    ld      a, (args_option_u) ; was the arg set
    or      a
    JR      NZ, startcopy   ; then skip confirmation

    ; are you sure
    ld      hl, msg_confirm
    CALL    prtstr
    CALL    getchr
    cp      'Y'
    JR      z, startcopy
    cp      'y'
    JR      Z, startcopy
    JP      exit

startcopy:
    CALL    prtcrlf
    ld      hl,msg_copy_main
    CALL    prtstr

    ; init start time of process
    CALL    sysgetseconds
    ld      (statstarttime), hl ; save the Hl register

copydatablocks:
    ; loop ALL the blocks

    ; READ
    CALL    readblock
    JP      NZ, io_error

    ; WRITE
    CALL    writeblock
    JP      C, crc_error
    JP      NZ, io_error

    ; display progress and count blocks
    CALL    progress_bar

    ; Loop Again ?
    ld      bc, (total4kxfr)
    dec     bc
    ld      a, b
    or      c
    JR      Z, finishcopy       ; escape out once copied
    ld      (total4kxfr), bc    ; store the remainder
    JR      copydatablocks      ; go round again

finishcopy:
    CALL    iprtstr
    .DB      13, 10, "Copied ", 0

    ; print if verified also
    ld      a, (args_option_v)
    or      a                   ; check the verify opton is set
    JR      Z, finishcopy1      ; not doing verify
    CALL    iprtstr
    .DB      "and verified ", 0

finishcopy1:
    ; print blocks copied
    ld      hl, (stat_blocks_written)
    CALL    prtdecword
    CALL    iprtstr
    .DB      " kBytes in ", 0

    ; subtrat end time from start time and display
    CALL    sysgetseconds
    ld      DE, (statstarttime) ; save the Hl register
    xor     A ; clear carry bits
    sbc     HL, DE ; subtract start time - IGNORE BORROW
    CALL    prtdecword ; print hl as decimal

    CALL    iprtstr
    .DB      " seconds.", 13, 10, 0

    ; Force BDOS to reset (logout) all drives
    CALL    drvrst

end:
    ld      hl,msg_complete
    CALL    prtstr
    JP      0
    RET
exit:
    CALL    prtcrlf
    JP      0
    RET

; =========================================
;
; END OF MAIN PROGRAM
; FLOW HERE
;
; =========================================
;
msg_welcome:
    .DB  "CopySlice v0.3 (RomWBW) March 2025 - M.Pruden", 13, 10, 0
msg_overite_partition:
    .DB  13,10
    .DB  "Warning: Copying to Slice 0 of hd512 media, "
    .DB  "will override partition table! ", 13,10,0
msg_parse_dir:
    .DB  13,10
    .DB  "Parsing directory. ", 0
msg_cant_find_dir:
    .DB  " -> Directory Not Found!"
    .DB  13,10
    .DB  "Will perform a full copy of the Slice.", 0
msg_confirm:
    .DB  13,10
    .DB  "Continue (Y,N) ? ", 0
msg_copy_main:
    .DB  13,10
    .DB  "Copying data blocks. ", 13,10,0
msg_complete:
    .DB  13, 10
    .DB  "Finished.", 13, 10, 0
;
; =======================================
; ERRORS
; =======================================
;
crc_error
    ld      hl, msg_crc_error   ; error
    JR      err
io_error:
    ld      hl, msg_io_error1
    CALL    prtstr
    CALL    prthex ; pring hex in A reg
    ld      hl, msg_io_error2
    JR      err
args_same_err:
    ld      hl, msg_args_same
    JR      err
device_diff_err:
    ld      hl, msg_device_diff
    JR      err
device_type_err:
    ld      hl, msg_device_type
    JR      err
media_err:
    ld      hl, msg_media_err
    JR      err
slice_def_err:
    ld      hl, msg_slice_def_err
    JR      err
err:
    CALL    prtstr
    JP      0
    RET

msg_io_error1:
    .DB 13, 10
    .DB "Disk I/O Error (Code 0x" ,0
msg_io_error2:
    .DB ") Aborting!!", 13, 10, 0
msg_crc_error:
    .DB 13, 10
    .DB "Verification Failed. Aborting!!", 13, 10, 0
msg_args_same:
    .DB 13, 10
    .DB "Source and Target disk slices must be different", 13, 10, 0
msg_device_diff:
    .DB 13, 10
    .DB "Hard disc(s) must have matching layout (hd1k/hd512).", 13, 10, 0
msg_media_err:
    .DB 13, 10
    .DB "A specified disk device does not exist.", 13, 10, 0
msg_device_type:
    .DB 13, 10
    .DB "Only hard disc devices are supported.", 13, 10, 0
msg_slice_def_err:
    .DB 13, 10
    .DB "Slice numbers must be valid and fit on the disk.", 13, 10, 0

; =============================================
;
; Routines for READ/WRITE/VERIFY a BLOCK of sectors
;
readblock:
    ld      bc, mainblkbuf  ; init disk buffer to HI-memory
    ld      (dma), bc       ; set this in loop since write/verify changes it.

    ; Sector Address
    ld      hl,(src_lbaoffset)        ; set DE:HL
    ld      de,(src_lbaoffset+2)      ; ... to starting lba

    ;; do the read
    ld      b, xf_sectorcount ; how many sectors
    ld      a,(src_diskunit) ; get source unit
    ld      c,a             ; put in C
    CALL    diskread        ; do it
    RET     NZ              ; abort on error

    ; test we read the expected sectors
    ld      a, xf_sectorcount ; the number expected
    cp      e               ; the actual numer read
    RET     NZ

;    ; calc src CRC if necessary
;    CALL    srcblockcrc

    ; increment lba for next block
    ld      hl, (src_lbaoffset) ; read LBA low word
    ld      bc, xf_sectorcount  ; number of sectors transferred
    add     hl, bc              ; add to LBA value low word
    ld      (src_lbaoffset), hl ; store it back
    JR      NC, readblock9      ; check for carry
    ld      de, (src_lbaoffset+2) ; LBA high word
    inc     de                  ; bump high word
    ld      (src_lbaoffset+2), de ; store it back
readblock9:
    xor     a ; ensure A register is cleared
    RET
;
; WRITE
;
writeblock:
    ld      bc, mainblkbuf  ; init disk buffer to HI-memory
    ld      (dma), bc       ; set this in loop since write/verify changes it.

    ; Sector Address
    ld      hl,(dest_lbaoffset)     ; set DE:HL
    ld      de,(dest_lbaoffset+2)   ; ... to starting lba

    ;; do the write
    ld      b, xf_sectorcount ; sector count to write
    ld      a, (dest_diskunit) ; get destination unit
    ld      c, a            ; put in C
    CALL    diskwrite       ; do it
    RET     NZ              ; abort on error

    ; test we wrote the expected sectors
    ld      a, xf_sectorcount   ; the number expected
    cp      e                   ; the actual numer written
    RET     NZ

    CALL    verifyblock         ; read and check the block matches
    JR      Z, writeblock1      ; no error so just continue
;    ld      hl, msg_crc_error   ; error
;    call    prtstr
;    or      0ffh
    RET

writeblock1:
    ; increment lba for next block
    ld      hl,(dest_lbaoffset) ; set DE:HL
    ld      bc, xf_sectorcount  ; sectors per Transfer
    add     hl, bc              ; add to LBA value low word
    ld      (dest_lbaoffset), hl
    JR      nc, writeblock9     ; check for carry
    ld      de, (dest_lbaoffset+2) ; ... to starting lba
    inc     de                  ; if so, bump high word
    ld      (dest_lbaoffset+2), de
writeblock9:
    xor     a
    RET
;
; Verify Write
;
verifyblock:
    ld      a, (args_option_v)
    or      a       ; check the verify opton is set
    RET     Z       ; nothing to do.

    ; init the dma disk buffer (different), so KNOW read occured and CRC
    ld      bc, mainblkbuf2 ; is not just a repeat of the same data
    ld      (dma), bc       ; if the verify read didnt work correctly

    ; Verify Read Sector Address
    ld      hl,(dest_lbaoffset)     ; set DE:HL
    ld      de,(dest_lbaoffset+2)   ; ... to starting lba

    ; READ DISK - do the Verify read
    ld      b, xf_sectorcount ; how many sectors
    ld      a, (dest_diskunit) ; get destination unit
    ld      c, a            ; put in C
    CALL    diskread        ; do it
    RET     NZ              ; abort on error

    ; test we read the expected sectors
    ld      a, xf_sectorcount ; the number expected
    cp      e               ; the actual numer written
    RET     NZ

    ld      hl, mainblkbuf  ; buffer address to cpmpare
    ld      de, mainblkbuf2 ; with the second buffer
    CALL    _cmp20block     ; do the comparison - NZ set on error
    RET                     ; just return this flag
;
; =======================================
;
; Capture Statistics
;
progress_bar:
    ; store a count of the amount of 1 kb data written
    ; to allow it to be displayed when finished
    ld      hl, (stat_blocks_written)
    ld      de, xf_sectorcount / 2 ; e.g 8 sectors is 4 kb
    add     hl, de
    ld      (stat_blocks_written),hl

    ; progress bar DOT - every 16 kb
    ld      a, l    ; get the LSB
    and     16 - 1  ; clear all but lower 4 bits - mod 16
    JR      NZ, progress_bar1 ; if a remainder then skip
    CALL    prtdot  ; progress bar dot after each 16kb
progress_bar1:

    ; progress bar CRLF - every 1024 kb
    ld      a, h    ; get the MSB
    and     4 - 1   ; clear all but lower 2 bits, mod 1024
    or      l       ; ensuring all LSB bits are Zero
    JR      NZ, progress_bar2 ; any of LOWER 10 bits is non zero
    CALL    prtcrlf ; print crlf after 1MB boundary
progress_bar2:
    RET
;
; -------------------------------
;
stat_blocks_written: .DW 0 ; amount in KB of data copied
statstarttime:       .DW 0 ; start time of the copy
;
;=============================================
; Block Stoarge Info for Source and Target
;=============================================
;
; MCB - MEDIA CONTROL BLOCK - Is Initialised
; for Source and Target Drives
;
; Offsets for the (MCB) - MEDIA Control Block
;
off_diskunit    .EQU 0   ; disk unit identifier
off_mediaid     .EQU 1   ; media id which correclty identifies hd512 hd1k
off_lbaoffset   .EQU 2   ; 4 byte lba sector offset of start of partition
                        ; 0 for hd512, or partiion lba for hd1k
off_lbasize     .EQU 6   ; 4 byte media size in sectors, or partition size
                        ; capacity of the drive for holding slices.
off_slice       .EQU 10  ; the slice number
off_sliceoffset .EQU 11  ; 4 byte lba sector offset of start of slice
off_unused1     .EQU 15  ; 1 byte - unused
off_sps         .EQU 16  ; 2 bytes - sectors per slice
;
mcb_table_size  .EQU 18  ; SIZE OF TABLE
;
;-----------------------------
;
; MCB for Source Media
sourcemedia .EQU    $
            .FILL  mcb_table_size,0   ; define source mcb
;
; MCB for Taget Media
targetmedia .EQU    $
            .FILL  mcb_table_size,0   ; define target mcb
;
; Defines MCB addresses for source and target
;
src_diskunit    .EQU sourcemedia
src_mediaid     .EQU sourcemedia + off_mediaid
src_lbaoffset   .EQU sourcemedia + off_sliceoffset
dest_diskunit   .EQU targetmedia
dest_mediaid    .EQU targetmedia + off_mediaid
dest_lbaoffset  .EQU targetmedia + off_sliceoffset
;
; ===============================
;
; BELOW ORIGNALLY FROM CLARGS.Z80
;
; ===============================
;
; todo possible to use a DRIVE LETTER for the
; selection of a Disk Unit using CBIOS lookup table
;
; working storage for storing captured args
;
args_src_slice         .DB 0
args_src_diskunit      .DB 0
args_target_slice      .DB 0
args_target_diskunit   .DB 0
args_option_f          .DB 0
args_option_u          .DB 0
args_option_v          .DB 0

; -----------------------

process_args:

    ; look for start of parms
    ld      hl,081h      ; point to start of parm area (past len byte)
    call    skipws    ; skip to next non-blank char
    jp      z,showall   ; no parms, show all active assignments

    ; target disk unit
    call    diskunit
    jr      nz, error_args
    ; write to variables
    ld      (args_target_slice), de

    ; skip the = delimiter
    call    skipws
    cp      '='     ; proper delimiter?
    jr      nz,error_args
    inc     hl ; skip over the = sign

    call    skipws    ; skip to next non-blank char
    jr      z, error_args

    ; source disk unit
    call    diskunit
    jr      nz,error_args
    ; write to variable
    ld      (args_src_slice), de

    ; Options
    call    skipws
    cp      '/'     ; proper options
    jr      nz, process_args_fin
    call    cl_options

process_args_fin:
    xor a   ; clear Z flag
    RET

error_args:
    ; dispaly error
    ld      hl,msg_invalid
    call    prtstr

showall:
    ; display the args
    ld      hl,msg_help
    call    prtstr
    ld      a, 99h
    or      a
    ret

; from romldr.asm runcmd1
; parameters HL - buffer
; RETURN DE - Unit Slice
; A register is consumed
; NZ flag is set if an error

diskunit:
    ;
    call    skipws      ; skip whitespace
    call    isnum       ; do we have a number?
    jp      nz,err_invcmd ; invalid format if empty
    call    getnum      ; parse a number
    jp      c,err_invcmd ; handle overflow error
    ld      d,a         ; save unit

    ; default slice - in E
    xor     a       ; zero accum
    ld      e,a     ; save default slice

    call    skipws      ; skip possible whitespace
    ld      a,(hl)      ; get separator char
    or      a           ; test for terminator
    jp      z,diskunit3 ; if so, boot the disk unit
    cp      '.'         ; otherwise, is '.'?
    jr      z,diskunit2 ; yes, handle slice spec
    cp      ':'         ; or ':'?
    jr      z,diskunit2 ; alt sep for slice spec
    jp      diskunit3   ; if not, then we finish her

diskunit2:
    inc hl              ; bump past separator
    call    skipws      ; skip possible whitespace
    call    isnum       ; do we have a number?
    jp      nz,err_invcmd ; if not, format error
    call    getnum      ; get number
    jp      c,err_invcmd ; handle overflow error
    ld      e,a         ; load slice into E
    jp      diskunit3   ; return the disk unit/slice

diskunit3:
    ; exit from above is here
    xor  a ; set zero flag
    ret

cl_options:
    inc     hl  ; next option
    CALL    skipws
    ret     z ; EOL so nothing to do
    call    upcase
    cp      'F'
    jr      z, cl_fullcopy
    cp      'U'
    jr      z, cl_unattended
    cp      'V'
    jr      z, cl_verify
    jr      cl_options

cl_fullcopy:
    ld      a, 0ffh
    ld      (args_option_f),a
    jr      cl_options

cl_unattended:
    ld      a, 0ffh
    ld      (args_option_u),a
    jr      cl_options

cl_verify:
    ld      a, 0ffh
    ld      (args_option_v),a
    jr      cl_options

err_invcmd:
    call prthex
    or      0ffh
    ret     ; return the nz flag

; ---------------------------
;
; Messages For processing Arguments
;
msg_help:
    .DB 13, 10
    .DB "Copy a full RomWBW hard disk slice to another slice.",13, 10
    .DB 13, 10
    .DB "Syntax:",13,10
    .DB "  copysl <destunit>[.<slice>]=<srcunit>[.<slice>] [/options]",13,10
    .DB "Options:",13,10
    .DB "  /f - Full copy of slice, ignoring directory allocations.",13,10
    .DB "  /u - Unattented, doesnt ask for user confirmation.",13,10
    .DB "  /v - Verify, by doing a read and compare after write.",13,10
    .DB "Notes:",13,10
    .DB "  - drive identification is by RomWBW disk unit number.",13,10
    .DB "  - if slice is omitted a default of 0 is used.",13,10
    .DB "  - for full information please see copysl.doc",13,10
    .DB 13, 10, 0
msg_invalid
    .DB 13, 10
    .DB "Invalid Arguments", 13,10,0
;
; ===============================
;
; ORIGNALLY FROM MEDIA.Z80
;
; ===============================
;
; Extended Media Functions to determine Actual Slice attributes
; Processes FAT Table and determines attributes about a Disk.
;
sps_hd1k    .EQU 16384
sps_hd512   .EQU 16640
;
; ----------------------------------------------
; Init a MCB and sense the underlying media
;
; Input A - Disk Unit Number
; Input IX - Pointer to MCB Output Block
;
sensemedia:

    ; store the mcb pointer
    ld      (mcb_pointer), ix

    ; init the MCB block with 0 bytes
    push    ix
    pop     hl          ; pointer to MCB
    ld      d,h         ; transfer to hl -> de
    ld      e,l
    inc     de          ; pointer to MCB + 1
    ld      (hl), 0     ; store the 0 in the first byte of MCB
    ld      bc, mcb_table_size - 1
    LDIR                ; fill the rest of the MCB table with 0's

    ; init the disk unit into mcb
    ld      (ix+off_diskunit), a

    ; Sense media
    ld      c, a        ; put disk unit in C for func call
    ld      b, BF_DIOMEDIA  ; HBIOS func: media
    ld      e, 1        ; enable media check/discovery
    RST     08          ; do it
    JP      NZ, err_sense  ; handle error
    ld      (ix + off_mediaid), e ; save media id typically 4 for HD512

    ; Check for hard disk
    ld      a, e
    cp      MID_HD          ; legacy hard disk
    JP      NZ, sense_end   ; if not hd

    ; load default sps for hd512 into MCB
    ld      bc, sps_hd512
    ld      (ix + off_sps + 0), c
    ld      (ix + off_sps + 1), b

    ; ONLY HDD have a MBR, and a partition table

    ; Attempt to Read MBR
    ld      de, 0           ; MBR is at
    ld      hl, 0           ; ... first sector
    ld      bc, bl_mbrsec   ; read into MBR buffer
    ld      (dma), bc       ; save this pointer to dma
    ld      b, 1            ; one sector
    ld      a, (ix + off_diskunit)  ; get diskunit
    ld      c, a            ; put in C
    CALL    diskread        ; do it
    JP      nz,err_disk     ; abort on error

    ; Check signature - for MBR part table
    ld      hl, (bl_mbrsec + 01FEh) ; get signature
    ld      a, l            ; first byte
    cp      055h            ; should be $55
    JR      NZ, sense_hd512 ; if not, no part table
    ld      a, h            ; second byte
    cp      0AAh            ; should be $AA
    JR      NZ, sense_hd512 ; if not, no part table

find_partition:

    ld      a, 0
    ld      (foundalready), a ; reset this variable, prior to use

    ; HL address of Byte 4 (partition type) in first partion entry
    ld      hl, bl_mbrsec + 01BEH + 4 ; partiton table start + type offset
    ; Try to find our entry in part table - DJNZ loop counter
    ld      b, 4  ; four entries in part table

find_partition2:

    ; load the partition Type, and point to the starting LBA
    ld      a, (hl)          ; get part type
    ld      de, 4            ; LBA is 4 bytes after part type
    add     hl, de           ; point to the starting LBA of partition

    ; did we find a RomWBW partition table entry
    cp      02Eh             ; WBW cp/m partition?
    JR      Z, sense_hd1k    ; cool, process it

    ; Found a different (not RomWBW )partition type.
    cp      0
    JR      NZ, sense_other

find_partition3:

    ; not an active entry, skip to next partion entry
    ld      de,12           ; partition entry = 16 bytes, we alread moved +4
    add     hl,de           ; next entry in table / point to part type
    DJNZ    find_partition2       ; loop thru table to next entry

    ; have read all 4 partition entries - did not find RomWBW partition
    JR      sense_hd512       ; too bad, no RomWBW partition

sense_other:

    ; We found a non RomWBW partition, so potentially if we dont latter
    ; we dont discover a Rom WBW partition we want the staring LBA to be
    ; used as upper bound for the hd512 media size.

    ; capture the starting LBA offset.
    ; de already contains start of lba
    ld      a, (foundalready)
    or      a
    JR    NZ, find_partition3 ; already found partition ignore this one.
    ; ignoring latter partitions assumes they are sequential with LBA loc.

    push hl
    push de
    push bc

    ; copy the Starting LBa of partition into MCB media Size
    ; thus the reported size of hd512 = starting position of first partion
    ; this prevents us from overriding partition data from Slice writes
    ex      de, hl ; preserving HL - which contains LBA Start of Partition
    ld      hl, (mcb_pointer)
    ld      bc, off_lbasize
    add     hl, bc
    ex      de, hl  ; setup DE AS pointer to MCB + 6
    ld      bc, 4  ; copy 4 bytes
    LDIR    ; from HL (partition start LBA) to DE (MCB + off_lba size)

    ; set flag to say has been done
    ld      a, 1 ; update found already
    ld      (foundalready), a

    pop     bc
    pop     de
    pop     hl

    JR      find_partition3 ; loop for next partition

sense_hd1k:

    ; NOTE The code below is directly updating MCB, not using offset's

    ; Update the MCB - set a pointer to MCB
    ld      de, (mcb_pointer)  ; pointer to MCB table

    ; set the media ID to be MID_HDNEW (hd1k))
    inc     de          ; skip to media id in MCB
    ld      a, MID_HDNEW
    ld      (de),a      ; update mcb with mediaid=hd1k

    ; update the lbaoffset, and lbasize (in MCB) )from partion table
    inc     de          ; MCB+2 is lba offset, MCB+6 = size in sectors
    ld      bc,8        ; 8 bytes is both lba offset and size
    LDIR                ; copy 8 bytes from partition table to

    ; load sps (hd1k) into MCB
    ld      bc, sps_hd1k
    ld      (ix + off_sps + 0),c
    ld      (ix + off_sps + 1),b

    ; have detected hd1k correctly
    jr sense_end

sense_hd512:

    ; if we already found a non RomWBW partion
    ; then we have already captured the lba_size
    ; from the offset of the first partition
    ld  a, (foundalready)
    cp  0
    jr  nz, sense_end

    ; find the Physical capcity of the media call -> DIOCAP
    ld      a, (ix + off_diskunit)
    ld      c, a         ; put disk unit in C for func call
    ld      b, BF_DIOCAP ; HBIOS func: to get disk lba capacity
    RST     08          ; do it
    JP      NZ, err_sense ; handle error

    ; update the media size into the MCB
    ld      (ix + off_lbasize +0), l
    ld      (ix + off_lbasize +1), h
    ld      (ix + off_lbasize +2), e
    ld      (ix + off_lbasize +3), d

sense_end:
    xor     a ; return Zero
    RET

; =======================================
; Calculate the Slice Offset in our media
; Only works for HDD
;
; Input IX - MCB Pointer
; A - Slice Number
;
slicecalc:

    ; store slice number in MB
    ld      (ix + off_slice), a ; store Slice Number in MCB

    ;  sps from  MCB
    ld      c, (ix + off_sps + 0)
    ld      b, (ix + off_sps + 1)

    ; starting sector number
    ld      hl, 0
    ld      de, 0

slicecalc1:
    or      a           ; Slice Number - set flags to check loop ctr
    JR      Z, slicecalc3 ; done if counter exhausted
    add     hl, bc       ; add one slice (SPS) to low word
    JR      NC, slicecalc2 ; check for carry
    inc     de          ; if so, bump high word
slicecalc2:
    dec     a           ; dec loop (Slice) counter
    JR      slicecalc1  ; and loop

slicecalc3:

    ; save the sector offset (SPS * Slice Number)
    push    hl
    push    de

    ; add sps once again, to get Required (upper sector) needed
    add     hl, bc
    JR      NC, slicecalc4
    inc     de
slicecalc4:
    ; DE : HL has the total Sector requirement

    ; subtract the total Media / Partition Sixe from the Capcity
    ; we are not interested in the result, just the C Flag
    ;
    or      a ; clear cary flag
    ;
    ld      c, (ix + off_lbasize +0) ; capacity LSW
    ld      b, (ix + off_lbasize +1) ; capacity LSW
    sbc     hl, bc ; Requirement - Capacity LSW
    ;
    ex      de, hl ; Requirement MSW
    ld      c, (ix + off_lbasize +2) ; capacity MSW
    ld      b, (ix + off_lbasize +3) ; capacity MSW
    sbc     hl, bc ; Requirement - Capacity MSW

    ; pop Sector Offset
    pop     de
    pop     hl

    ; Require - Capacity - generates Cary if Capity > Require
    JR      C, slicecalc5 ; C -> Require - Capacity : Require <= Capacity
    or      0FFh ; otherwise signal not enough capacity
    RET

slicecalc5:

    ; add lba offset to DEHL to get slice offset, commented code above
    ld      c, (ix + off_lbaoffset+0)
    ld      b, (ix + off_lbaoffset+1)
    add     hl, bc
    ex      de, hl
    ld      c, (ix + off_lbaoffset+2)
    ld      b, (ix + off_lbaoffset+3)
    adc     hl,bc
    ex      de, hl

    ; store slice offset into mcb
    ld      (ix + off_sliceoffset + 0), l    ; store it in MCB
    ld      (ix + off_sliceoffset + 1), h    ; store it in MCB
    ld      (ix + off_sliceoffset + 2), e    ; store it in MCB
    ld      (ix + off_sliceoffset + 3), d    ; store it in MCB

    ; return without issue
    xor     a
    RET

; =====================
;
; Find the starting sector for Source Slice directory
; return it in DE - HL
; NOTE : This routine only works withe th source drive
;
finddir:

    ; Sector Address of start of Media
    ld      hl,(src_lbaoffset)        ; set DE:HL
    ld      de,(src_lbaoffset+2)      ; ... to starting lba

    ; need to adjust sector to start of directory

    ; hd512 - skip 128kb (system) - 256 sectors
    ld      bc, 256
    ; is it hd1k
    ld      a, (src_mediaid)
    cp      MID_HDNEW
    jr      nz, finddir1 ; not hd1K
    ; hd1k - skip 16kb (system) - 32 sectors
    ld      bc, 32
finddir1:
    ; add sector offset
    add     hl,bc  ; add to LBA value low word
    RET     nc     ; if NC then just return
    inc     de     ; if carry, bump high word
    RET

; =====================
;
; Called to display details in format
; Disk Unit 2, Slice 11, Type = hdXXX
;
printdetails:
    CALL    iprtstr
            .DB  " Disk Unit ", 0
    ld      a, (ix+off_diskunit)
    CALL    prtdec  ; print disk unit
    CALL    iprtstr
            .DB ", Slice ", 0
    ld      a, (ix+off_slice)
    CALL    prtdec  ; print slice number
    CALL    iprtstr
            .DB ", Type = ", 0
    ld      a, (ix+off_mediaid)
    cp      MID_HDNEW
    JR      Z, prtdetailsnew
prtdetailslegacy:
    CALL    iprtstr
            .DB "hd512", 13, 10, 0
    RET
prtdetailsnew
    CALL    iprtstr
            .DB "hd1k", 13, 10, 0
    RET
;
; --------------------------
;
err_disk:
    ld      a,2      ; IO ERROR
    or      a
    RET

err_hbios
    ld      a,3     ; HBIOS Error
    or      a
    RET

err_sense
    ld      a,4
    or      a
    RET
;
;============================================
;
; Working Variables
;
mcb_pointer     .DW  0   ; pointer passed by caller, to MCB
foundalready    .DB  0   ; found a non WBW partition and captured LBA
;
;-----------------------------
;
; Disk buffers (uninitialized)
;
; Master Boot Record sector is read into area below.
; Note that this buffer is actually shared with bl_infosec
; buffer below.
;
            .DB "MBR_START" ; debug
bl_mbrsec   .EQU    $
            .FILL 200h,0   ; define 512 mbr sector buffer
            .DB "MBR_END" ; debug
;
; NOTE: the MBR_ messages are used to aid debug in memory
;
; =======================================
;
; ORIGNALLY FROM CPMFS.Z80
;
; =======================================
;
; Handle CPM File System
;
; PROCESS DIRECTORY
;
; Read 16kb and proces directory entries
; DE and HL are the bock address to Read -
; DE HL are incremented for next 16kb read
;
dir_sectors:    .EQU 32 ; sectors to read (16kb) & process in directory
fs_allocsize:   .EQU 4  ; smallest size (in kB) for a directory block
;
processdir:

    push    af
    push    bc
    push    de
    push    hl

    ; init disk buffer to HI-memory
    ld      bc, mainblkbuf
    ld      (dma), bc

    ; READ - do the disk read of the directory
    ld      b, dir_sectors
    ld      a, (src_diskunit) ; get disk unit
    ld      c, a            ; put in C
    call    diskread        ; do it
    ret     nz              ; abort on error

    ; test we read sectors
    ld      a, dir_sectors  ; the number expected
    cp      e               ; the actual numer read
    ret     nz
;
; Scan directory items to find max alloc
;
scandirectory:

    ; variables USED
    ;  BC loop counter
    ;  DE used for 16 bit aritmatic
    ;  HL pointer to the disk directory buffer

    ld      bc, 16 * dir_sectors ; dir entries to process. 16 per sector
    ld      hl, mainblkbuf  ; address of disk buffer just read

nextdirentry:

    ld      a,(hl)      ; the first byte "Status" of dir entry
    cp      10h         ; entries we process are 0-15 (user Id)
    JR      NC, notadirentry ; > 15 we dont need to process

isadirectory:

    ; increment the count of dir entries found
    ld      de, (dircounter)
    inc     de
    ld      (dircounter), de

    ; directory entry - jump to alloc blocks
    ld      de, 10h ; first 16 bytes are the status / file name
    add     hl, de  ; skip to allocations

    push    bc      ; save the outer loop
    ld      c, 8    ; loop counter - num allocations in 16 bytes

nextallocation:
    ; read the allocation into DE, inc the hl pointer
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl

    ; compare with max and update
    push    hl
    ld      hl, (maxalloc)
    sbc     hl, de
    JR      NC, dontupdatemax
    ld      (maxalloc), de      ; update max allocation
dontupdatemax:
    pop hl

    dec     c
    JR      NZ, nextallocation  ; loop if more to process

    pop     bc                  ; restore the outer loop counter
    JR      finddirentry        ; and contine the outer loop

notadirentry:
    ; A reg Status byte - is not user id 0-15 - check for invalid and flag
    cp      0E5h                ; an Unused Dir Entry
    JR      Z, notadirentry2    ; legal so skip to next
    cp      34                  ; 0-33 are considered legal Status in CP/M FS
    JR      C, notadirentry2    ; if legal then skip to next

illegaldirentry:
    ; detected illegal directory ( Status not 0-33, E5h ) set a flag
    ld      (illegaldir), a     ; set NZ, A is the bad status > 34

notadirentry2:
    ; update pointer - skip to next dir entry
    ld      de, 20h
    add     hl, de

finddirentry:
    ; decide if need to loop and process next dir entry
    dec     bc      ; count down for each dir entry, - outer loop
    ld      a, b
    or      c
    JR      NZ, nextdirentry ; if more dir entries contine (loop) to next

processdirfin:

    ; finished - pop HL DE - which contain the LBA Sector pointers
    pop     hl
    pop     de

    ; increment DE HL lba for next block, for Disk Read
    ld      bc, dir_sectors ; sectors
    add     hl, bc          ; add to LBA value low word
    JR      NC, processdirfin2 ;
    inc     de              ; Carry, So bump high word
processdirfin2:

    ; and pop the rest of the registers
    pop     bc
    pop     af

    xor     a ; signal success
    RET
;
; ----------------------------------
;
; Compute Result;
; Work out the number of Sectors
; Compute full disk copy, if user chose to transfer all.
;
compute_full:
    ; compute full disk size to copy in 4k allocations
    ld      hl, 8192 / fs_allocsize ; hd1k  - 8192 kb total allocations
    ld      a, (ix + off_mediaid)
    cp      MID_HDNEW               ; is it hd1k
    JR      Z, compute_store        ; for hd1k - store it now
    ld      hl, 8320 / fs_allocsize ; hd512 - 8320 kb total allocations
    JR      compute_store

;
; Compute the number of blocks to transfer based on dir scan.
;
compute_xfer:

    ; get the max allocation, measured in 4kb blocks, from the dir scan
    ld      hl, (maxalloc)

    ; Add the 16kb (hd1k) / 128kb (hd512) System area's'
    ld      bc,  16 / fs_allocsize  ; hd1k - 16kb system track
    ld      a, (src_mediaid)
    cp      MID_HDNEW
    JR      Z, compute_xfer1        ; if hd1k - add it now
    ld      bc, 128 / fs_allocsize  ; hd512 - 128kb system track
compute_xfer1:
    add     hl, bc      ; add system track block allocations to total

compute_store:

;    ; Divide allocations by 4, to convert to 16k blocks
;    ld      a, l    ; the LSByte
;    and     0FCh
;    ld      l, a    ; clear the 2 least sig bits
;    rr      h
;    rr      l
;    rr      h       ; rotate right HL 2 bits
;    rr      l       ; which is like  divide 4
;
;    ; inc by 1, last partial 16 kb bloc is copied, to be sure.
;    ; poss should look for carry bit being set, and conditonaly inc.
;    inc     hl
;    ; TODO THIS IS A BUG FOR FULL DISK COPY

    ; Store It
    ld      (total4kxfr), hl ; store it

 ;   ; todo we need to ensure we DONT OVERSHHOT
 ;   ; ie: work out what the max is, easy to define

    RET

; ----------------------------------
;
; Prints information about the transfer
;
compute_print:
    ; write info about dir entries found, blocks to copy
    CALL    iprtstr
    .DB      13, 10, "Found ",0
    ld      hl, (dircounter)
    CALL    prtdecword
    CALL    iprtstr
    .DB      " directory entries, with ",0
    ld      hl, (maxalloc)
    CALL    prtdecword
    CALL    iprtstr
    .DB      " (4k) extents.",0
    RET
;
; ----------------------------------
;
; variable storage for dir processing
;
                .DB "Debug123" ; TEMP Not Needed
dircounter      .DW 0 ; counter of the total number of directory entries
maxalloc        .DW 8 ; highest block allocation in the directory. Default =
                     ; 8 * 4k = 32k = 1024 dir entries, safe minimum
total4kxfr      .DW 0 ; number of 4k data transfors to perform
illegaldir      .DB 0 ; set to non-zero if illgal dir has been discovered
                .DB "Debug456" ; TEMP Not Needed
;
	.END

