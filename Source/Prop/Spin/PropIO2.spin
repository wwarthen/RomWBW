{{

  *********************************
  *  PropIO 2 for RomWBW          *
  *  Interface to RBC PropIO 2    *
  *  Version 0.97                 *
  *  May 9, 2020                  *
  *********************************

  Wayne Warthen
  wwarthen@gmail.com

  Substantially derived from work by:
  
  David Mehaffy (yoda)

  Credits:

  Andrew Lynch (lynchaj)        for creating the N8VEM
  Vince Briel (vbriel)          for the PockeTerm with which a lot of code is shared here
  Jeff Ledger (oldbitcollector) for base terminal code
  Ray Rodrick (cluso99)         for the TriBladeProp that shares some of these ideas
                                for using the CPM to SD
  Marko                         for /WAIT optimization

  ToDo:
  
    1)  Add buffer overrun checks?

  Updates:

    2012-02-20 WBW: Updated VGA_1024 ANSI emulation to handle 'f' the same as 'H'
    2014-01-16 WBW: /WAIT optimzation per Marko
    2014-02-08 WBW: Adaptation for PropIO 2
    2015-11-15 WBW: Added SD card capacity reporting
    2018-03-11 WBW: Implement character attributes
    2020-05-09 WBW: Switch monitor refresh to 60Hz

}}

CON
  VERSION = (((0 << 8) + 97) << 16) + 0

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000
  
  'SLEEP = 60 * 5                ' Screen saver timeout in seconds
  SLEEP = 0			' Zero for no screen saver
  
  VGA_BASE = 16                 ' VGA Video pins 16-23 (??)
  KBD_BASE = 14                 ' PS/2 Keyboard pins 14-15 (DATA, CLK)
  SD_BASE = 24                  ' SD Card pins 24-27 (DO, CLK, DI, CS)
  
  STAT_ATTR1 = %00110000_00000000	' Status area screen attribute (first line)
  STAT_ATTR = %01110000_00000000	' Status area screen attribute

  DSKCMD_NOP = $00
  DSKCMD_STATUS = $01
  DSKCMD_GETTYPE = $02
  DSKCMD_GETCAP = $03
  DSKCMD_GETCSD = $04
  DSKCMD_RESET = $10
  DSKCMD_INIT = $20
  DSKCMD_READBLK = $30
  DSKCMD_PREPARE = $40
  DSKCMD_WRITEBLK = $50

  DSKCMD_VERSION = $F0

  DSKST_ACT = $80               ' bit indicates interface is actively processing command (busy)
  DSKST_ERR = $40               ' bit indicates device in error status                                    
  DSKST_OVR = $20               ' bit indicates a buffer overrun occurred

  TRMST_ACT = $80               ' bit indicates interface is busy
  TRMST_ERR = $40               ' bit indicates an error has occurred
  TRMST_KBDACT = $20            ' bit set when keyboard input active (getting key from keyboard)                                    
  TRMST_DSPACT = $10            ' bit set when display output active (writing byte to display)

  TRMST_ACTMASK = (TRMST_KBDACT | TRMST_DSPACT)         ' bit mask for kbd or dsp active

OBJ
  'dsp : "VGA_1024"                                      ' VGA Terminal Driver
  dsp : "AnsiTerm"                                      ' VGA Terminal Driver
  kbd : "Keyboard"                                      ' PS/2 Keyboard Driver
  sdc : "safe_spi"                                      ' SD Card Driver
  dbg : "Parallax Serial Terminal Null"                 ' Serial Port Driver (debug output)                                              

VAR
  byte  TermStatKbd
  byte  TermStatDsp
  byte  TermKbdBuf
  byte  TermScrBuf
  byte  DiskStat
  byte  DiskCmd
  long  DiskBlk
  long  DiskBuf[128]                                    ' 512 bytes, long-aligned
  
  long  TimerStack[16]
  long  TimerCount
  long  DiskResult
  long  CardType
  
  byte	statRows
  byte	statCols
  
PUB main

  dbg.Start(115200)

  MsgStr(string("Starting PropIO..."))
  MsgNewLine

  MsgStr(string("Initializing Video..."))
  Result := dsp.Start(VGA_BASE)
  if (Result < 0)
    MsgStr(string(" Failed!   Error: "))
    MsgDec(Result)
  else
    MsgStr(string(" OK"))
    dsp.cls
  MsgNewLine

  dsp.vidOn

  statRows := (dsp.statInfo >> 8)  & $FF
  statCols := dsp.statInfo & $FF
    
  dsp.statFill(0, 0, STAT_ATTR, $20, statRows * statCols)
  dsp.statFill(0, 0, STAT_ATTR1, $20, statCols)

  dsp.statStr(0, 1, STAT_ATTR1, @strROM)
  dsp.statStr(0, (statCols - strsize(@strHW)) / 2, STAT_ATTR1, @strHW)
  dsp.statStr(0, (statCols - strsize(@strVer) - 1), STAT_ATTR1, @strVer)
  
  'dsp.statStr(2, (statCols - 20) / 2, STAT_ATTR, string("<<< Message Area >>>"))

  MsgStr(string("Initializing PropIO..."))

  TermStatKbdAdr := @TermStatKbd
  TermStatDspAdr := @TermStatDsp
  TermKbdBufAdr := @TermKbdBuf
  TermDspBufAdr := @TermScrBuf
  DiskStatAdr := @DiskStat
  DiskCmdAdr := @DiskCmd
  DiskBufAdr := @DiskBuf

  DiskBufIdx := 0
  TermStatKbd := TRMST_KBDACT
  TermStatDsp := 0
  DiskStat := 0
  DiskResult := 0
  CardType := 0 
    
  ByteFill(@DiskBuf, $00, 512)

  MsgStr(string(" OK"))
  MsgNewLine

  MsgStr(string("Initializing Keyboard..."))
  Result := kbd.Start(KBD_BASE, KBD_BASE + 1)
  if (Result < 0)
    MsgStr(string(" Failed!   Error: "))
    MsgDec(Result)
  else
    MsgStr(string(" OK"))
  MsgNewLine

  if (SLEEP > 0)
    MsgStr(string("Starting Timer..."))
    Result := cognew(Timer, @TimerStack) 
    if (Result < 0)
      MsgStr(string(" Failed!   Error: "))
      MsgDec(Result)
    else
      MsgStr(string(" OK"))
    MsgNewLine

  MsgStr(string("Starting PortIO cog..."))
  Result := cognew(@PortIO, 0) + 1
  if (Result < 0)
    MsgStr(string(" Failed!   Error: "))
    MsgDec(Result)
  else
    MsgStr(string(" OK"))
  MsgNewLine
  
  dsp.beep

  MsgStr(string("PropIO Ready!"))
  MsgNewLine

  repeat
    if (DiskStat & DSKST_ACT)
      ProcessDiskCmd
      DiskCmd := 0
      DiskStat &= !DSKST_ACT
      
    if (TermStatDsp & TRMST_DSPACT)
      dsp.processChar(TermScrBuf)
      Activity
      TermStatDsp &= !TRMST_DSPACT
      
    if (TermStatKbd & TRMST_KBDACT)
      if (kbd.GotKey)
        TermKbdBuf := kbd.GetKey
        Activity
        TermStatKbd &= !TRMST_KBDACT
       
  MsgNewLine
  MsgStr(string("PropIO Shutdown!"))
  MsgNewLine

PRI ProcessDiskCmd

  'dbg.Str(string("ProcessDiskCmd: DiskCmd="))
  'dbg.Hex(DiskCmd,2)
  'dbg.NewLine

  if (DiskCmd == DSKCMD_RESET)
    DiskBlk := -1
    DiskStat := DSKST_ACT
    DiskResult := 0
        
  elseif (DiskCmd == DSKCMD_INIT)
    DiskResult := InitCard 
    if (DiskResult < 0)
      DiskStat := (DiskStat | DSKST_ERR)
      DiskBuf[0] := DiskResult
          
  elseif (DiskCmd == DSKCMD_READBLK)
    DiskBlk := DiskBuf[0]
    DiskResult := ReadSector(DiskBlk, @DiskBuf) 
    if (DiskResult < 0)
      DiskStat := (DiskStat | DSKST_ERR)
      DiskBuf[0] := DiskResult
          
  elseif (DiskCmd == DSKCMD_PREPARE)
    DiskBlk := DiskBuf[0]
    ByteFill(@DiskBuf, $00, 512)
        
  elseif (DiskCmd == DSKCMD_WRITEBLK)
    DiskResult := WriteSector(DiskBlk, @DiskBuf)  
    if (DiskResult < 0)
      DiskStat := (DiskStat | DSKST_ERR)
      DiskBuf[0] := DiskResult

  elseif (DiskCmd == DSKCMD_STATUS)
    DiskBuf[0] := DiskResult

  elseif (DiskCmd == DSKCMD_GETTYPE)
    DiskBuf[0] := CardType    

  elseif (DiskCmd == DSKCMD_GETCAP)
    DiskBuf[0] := \sdc.GetCapacity

  elseif (DiskCmd == DSKCMD_GETCSD)
    DiskResult := \sdc.GetCSD(@DiskBuf)    

  elseif (DiskCmd == DSKCMD_VERSION)
    DiskBuf[0] := VERSION    

  'dbg.Str(string("ProcessDiskCmd: DiskStat="))
  'dbg.Hex(DiskStat,2)
  'dbg.NewLine
  

PRI InitCard

  CardType := 0
  Result := \sdc.Start(SD_BASE)
  if (Result > 0)
    CardType := Result
  'dbg.Str(string("sdc.Start:"))
  'dbg.Dec(Result)
  'dbg.NewLine

PRI ReadSector(Sector, Buffer)

  Result := \sdc.ReadBlock(Sector, Buffer)
  'dbg.Str(string("sdc.ReadBlock("))
  'dbg.Hex(Sector, 8)
  'dbg.Str(string("): "))
  'dbg.Dec(Result)
  'dbg.NewLine

PRI WriteSector(Sector, Buffer)    

  Result := \sdc.WriteBlock(Sector, Buffer)
  'dbg.Str(string("sdc.WriteBlock("))
  'dbg.Hex(Sector, 8)
  'dbg.Str(string("): "))
  'dbg.Dec(Result)
  'dbg.NewLine

PRI MsgNewLine
  dbg.NewLine
  dsp.processChar(13)
  dsp.processChar(10)

PRI MsgStr(StrPtr)
  dbg.Str(StrPtr)
  dsp.Str(StrPtr)

PRI MsgDec(Val)                  
  dbg.Dec(Val)
  dsp.Dec(Val)

PRI MsgHex(Val, Digits)
  dbg.Hex(Val, Digits)
  dsp.Hex(Val, Digits)  

PRI Timer
  TimerCount := SLEEP
  repeat
    waitcnt(clkfreq * 1 + cnt)
    if (TimerCount > 0)
      if (TimerCount == 1)
        dsp.vidOff
      TimerCount--

PRI Activity
  if (SLEEP > 0)
    if (TimerCount == 0)
      dsp.vidOn
    TimerCount := SLEEP

{
PRI DumpBuffer(Buffer) | i, j

  repeat i from 0 to 31    
    dbg.Hex(i * 16, 4)
    dbg.Str(string(": "))
    repeat j from 0 to 15
      dbg.Hex((byte[Buffer][((i * 16) + j)]), 2)
      dbg.Str(string(" "))
    dbg.NewLine
}

DAT

strVer	byte	"F/W v0.97",0
strHW	byte	"PropIO v2",0
strROM	byte	"RomWBW",0

{{                        Ports


                    +------ CLR
                    |+----- /RD
                    ||+---- A1
                    |||+--- A0
                    ||||+-- /CS
                    |||||
                    |||||
   P15..P0  -->  xxxxxxxx_xxxxxxxx
                          +------+
                          D7....D0


   /RD  A1  A0  /CS
     0   0   0   0       Terminal Status                ' port $40 (IN)                                       
     1   0   0   0       Terminal Command               ' port $40 (OUT)
     0   0   1   0       Terminal Read Data (from kbd)  ' port $41 (IN)
     1   0   1   0       Terminal Write Data (to disp)  ' port $41 (OUT)                       
     0   1   0   0       Disk Status                    ' port $42 (IN)
     1   1   0   0       Disk Command                   ' port $42 (OUT)                                          
     0   1   1   0       Disk Read Data (from disk)     ' port $43 (IN)                     
     1   1   1   0       Disk Write Data (to disk)      ' port $43 (OUT)

}}

                        org 0

PortIO
                        mov     dira, BitCLR            ' Make sure we can write to CLR
                        or      outa, BitCLR            ' Toggle CLR, make it high
                        andn    outa, BitCLR            '   then low

                        waitpeq MaskCS, MaskCS          ' wait for CS to be deasserted (high)
                        waitpeq Zero, MaskCS            ' wait for CS to be asserted (low)

                        mov     TempAdr, ina            ' get input bits
                        shr     TempAdr, #9             ' /RD, A1, A0 -> bits 2,1,0
                        and     TempAdr, #$07           ' isolate the 3 bits

                        add     TempAdr,#JmpTable
                        movs    JmpCmd,TempAdr
                        nop
JmpCmd                  jmp     #0-0
 
JmpTable                jmp     #TermStatus
                        jmp     #TermRead
                        jmp     #DiskStatus
                        jmp     #DiskRead
                        jmp     #TermCommand
                        jmp     #TermWrite
                        jmp     #DiskCommand
                        jmp     #DiskWrite
                   
TermCommand             ' receive terminal command byte from host
                        'andn dira, BitsData            ' set D0-D7 to input
                        'mov TempVal, ina               ' input byte from port
                        'wrbyte TempVal, TermStatusAdr  ' save status byte to global memory
                        jmp LoopRet

TermStatus              ' send terminal status byte to host
                        rdbyte TempVal, TermStatKbdAdr  ' get kbd status
                        mov outa, #0
                        or outa, TempVal                ' combine it
                        rdbyte TempVal, TermStatDspAdr  ' get display status
                        or outa, TempVal                ' combine it
                        xor outa, #TRMST_ACTMASK        ' convert 'active' bits to 'ready' bits for host
                        or dira, BitsData               ' set D0-D7 to output
                        jmp LoopRet

TermRead                ' return byte in key buf to host
                        rdbyte TempVal,TermKbdBufAdr    ' get the byte from the buffer
                        mov outa,TempVal                ' output byte to port
                        rdbyte TempVal, TermStatKbdAdr
                        or TempVal, #TRMST_KBDACT
                        wrbyte TempVal, TermStatKbdAdr
                        or dira, BitsData               ' set D0-D7 to output
                        jmp LoopRet

TermWrite               ' accept byte from host into screen buf
                        mov TempVal, ina                ' input byte from port
                        wrbyte TempVal,TermDspBufAdr    ' put the byte into the buffer
                        rdbyte TempVal, TermStatDspAdr  ' get current display status
                        or TempVal, #TRMST_DSPACT       ' set the active bit
                        wrbyte TempVal, TermStatDspAdr  ' store the updated status
                        jmp LoopRet
                        
DiskCommand             ' receive disk command byte from host
                        mov DiskBufIdx, #0              ' reset buf index on any incoming command
                        mov TempVal, ina                ' input command byte from port
                        and TempVal, #$FF wz            ' isolate relevant bits
        if_z            jmp LoopRet                     ' handle NOP here (fast)
                        wrbyte TempVal, DiskCmdAdr      ' store command byte to global memory
                        rdbyte TempVal, DiskStatAdr     ' get current disk status
                        or TempVal, #DSKST_ACT          ' set the active bit
                        wrbyte TempVal, DiskStatAdr     ' store updated disk status
                        jmp LoopRet

DiskStatus              ' send disk status byte to host
                        rdbyte TempVal, DiskStatAdr     ' get status byte from global memory
                        mov outa, TempVal               ' output byte to port
                        or  dira, BitsData              ' set D0-D7 to output
                        jmp LoopRet

DiskRead               ' send bytes from sector buffer to host
                        mov TempAdr,DiskBufAdr          ' get pointer to sector buffer
                        add TempAdr,DiskBufIdx          ' increment pointer by current index value
                        rdbyte TempVal,TempAdr          ' get the byte from the buffer
                        mov outa,TempVal                ' output byte to port
                        add DiskBufIdx,#1               ' increment index for the next read
                        or dira, BitsData               ' set D0-D7 to output
                        jmp LoopRet

DiskWrite               ' fill bytes of sector buffer from host
                        mov TempAdr,DiskBufAdr          ' get pointer to sector buffer
                        add TempAdr,DiskBufIdx          ' increment pointer by current index value
                        mov TempVal, ina                ' input byte from port
                        wrbyte TempVal,TempAdr          ' put the byte into the buffer
                        add DiskBufIdx,#1               ' increment the index for the next write
                        jmp LoopRet

TermStatKbdAdr          long    0
TermStatDspAdr          long    0
TermKbdBufAdr           long    0
TermDspBufAdr           long    0
DiskStatAdr             long    0
DiskCmdAdr              long    0
DiskBufAdr              long    0
DiskBufIdx              long    0

LoopRet                 long    PortIO

BitsData                long    $00FF
Zero                    long    $0000
MaskCS                  long    $0100
BitCS                   long    $0100
BitCLR                  long    $1000
DirMask                 long    $1000
WaitMask                long    $1100

TempVal                 res     1
TempAdr                 res     1

                        fit