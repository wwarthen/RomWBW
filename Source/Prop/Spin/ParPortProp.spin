{{

  ************************************
  *  ParPortProp for RomWBW          *
  *  Interface to RBC ParPortProp    *
  *  Version 0.97                    *
  *  May 9, 2020                     *
  ************************************

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

  ToDo:
  
    1)  Add buffer overrun checks?

  Updates:

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

  PPI_CMD = $0100               ' pin 8, PC0, active ???
  PPI_STB = $0200               ' pin 9, PC4, active low
  PPI_IBF = $0400               ' pin 10, PC5, active high
  PPI_ACK = $0800               ' pin 11, PC6, active low
  PPI_OBF = $1000               ' pin 12, PC7, active low

  PPI_DIRRD = PPI_STB + PPI_ACK 
  PPI_DIRWR = PPI_STB + PPI_ACK + $FF

  FUNC_PUTBYTE =  $10           ' Buf[0] -> PPI (one byte)
  FUNC_GETBYTE =  $11           ' PPI -> Buf[0] (one byte)
  FUNC_PUTBUF =   $20           ' Buf -> PPI (arbitrary buffer) 
  FUNC_GETBUF =   $21           ' PPI -> Buf (arbitrary buffer)

  CMD_NOP =       $00           ' Do nothing
  CMD_ECHOBYTE =  $01           ' Receive a byte, invert it, send it back
  CMD_ECHOBUF =   $02           ' Receive 512 byte buffer, send it back

  CMD_DSKRES =    $10           ' Restart SD card support
  CMD_DSKSTAT =   $11           ' Send last SD card status (4 bytes)
  CMD_DSKPUT =    $12           ' PPI -> sector buffer -> PPP
  CMD_DSKGET =    $13           ' PPP -> sector buffer -> PPI
  CMD_DSKRD =     $14           ' Read sctor from SD card into PPP buffer, return 1 byte status
  CMD_DSKWR =     $15           ' Write sector to SD card from PPP buffer, return 1 byte status
  CMD_DSKTYPE =   $16           ' Send SD Card type
  CMD_DSKCAP =    $17           ' Send current disk capacity
  CMD_DSKCSD =    $18           ' Send SD Card CSD register contents (16 bytes)

  CMD_VIDOUT =    $20           ' Write a byte to the terminal emulator

  CMD_KBDSTAT =   $30           ' Return a byte with number of characters in buffer
  CMD_KBDRD =     $31           ' Return a character, wait if necessary

  CMD_SPKTONE =   $40           ' Emit speaker tone at specified frequency and duration

  CMD_SIOINIT =   $50           ' Reset serial port and establish a new baud rate (4 byte baud rate)
  CMD_SIORX =     $51           ' Receive a byte in from serial port
  CMD_SIOTX =     $52           ' Transmit a byte out of the serial port 
  CMD_SIORXST =   $53           ' Serial port receive status (returns # bytes of rx buffer used)                                   
  CMD_SIOTXST =   $54           ' Serial port transmit status (returns # bytes of tx buffer space available) 
  CMD_SIORXFL =   $55           ' Serial port receive buffer flush                                   
  CMD_SIOTXFL =   $56           ' Serial port transmit buffer flush (not implemented) 

  CMD_RESET =     $F0           ' Soft reset Propeller
  CMD_VERSION =   $F1           ' Send firmware version

OBJ
  'dsp : "VGA_1024"                                      ' VGA Terminal Driver
  dsp : "AnsiTerm"                                      ' VGA Terminal Driver
  kbd : "Keyboard"                                      ' PS/2 Keyboard Driver
  sdc : "safe_spi"                                      ' SD Card Driver
  'dbg : "Parallax Serial Terminal"                      ' Serial Port Driver (debug output)
  dbg : "Parallax Serial Terminal Null"                 ' Do nothing for debug output
  sio : "FullDuplexSerial"                              ' Serial I/O                                              
  'sio : "FullDuplexSerialNull"                          ' Dummy driver to use when debugging                                              

VAR
  long  Cmd
  long  Func
  byte  ByteVal
  long  BufPtr  
  long  BufSize

  long  DskBuf[128]             ' 512 byte, declared as long's to ensure long-aligned
  long  DskStat
  long  DskBlock

  'long  FuncTmp

  'long  Cnt10ms

  long TimerStack[16]
  long TimerCount
  long CardType
   
  byte	statRows
  byte	statCols
  
PUB main | tmp
  dbg.Start(115200)

  MsgStr(string("Starting ParPortProp..."))
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

  dsp.VidOn

  statRows := (dsp.statInfo >> 8)  & $FF
  statCols := dsp.statInfo & $FF
    
  dsp.statFill(0, 0, STAT_ATTR, $20, statRows * statCols)
  dsp.statFill(0, 0, STAT_ATTR1, $20, statCols)

  dsp.statStr(0, 1, STAT_ATTR1, @strROM)
  dsp.statStr(0, (statCols - strsize(@strHW)) / 2, STAT_ATTR1, @strHW)
  dsp.statStr(0, (statCols - strsize(@strVer) - 1), STAT_ATTR1, @strVer)
  
  'dsp.statStr(2, (statCols - 20) / 2, STAT_ATTR, string("<<< Message Area >>>"))

  MsgStr(string("Initializing ParPortProp..."))

  Cmd := 0
  Func := 0
  ByteVal := 0
  BufPtr := @DskBuf
  DskStat := 0
  DskBlock := 0
  CardType := 0
  
  CmdAdr := @Cmd
  FuncAdr := @Func
  ByteValAdr := @ByteVal
  BufPtrAdr := @BufPtr
  BufSizeAdr := @BufSize

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

  MsgStr(string("Initializing SD Card..."))
  Result := \sdc.Start(SD_BASE) 
  if (Result < 0)
    MsgStr(string(" Failed!   Error: "))
    MsgDec(Result)
  else
    MsgStr(string(" OK"))
  MsgNewLine

  MsgStr(string("Initializing Serial Port..."))
  Result := sio.Start(31, 30, 0, 9600) 
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
  Result := cognew(@Entry, 0) + 1
  if (Result < 0)
    MsgStr(string(" Failed!   Error: "))
    MsgDec(Result)
  else
    MsgStr(string(" OK"))
  MsgNewLine

  dsp.beep

  MsgStr(string("ParPortProp Ready!"))
  MsgNewLine

  'repeat
  '  dbg.NewLine
  '  dbg.Hex(ina, 8)
  '  waitcnt((clkfreq / 2) + cnt)

  repeat
    tmp := Cmd
    'dbg.Str(String("Cmd="))
    'dbg.Hex(Cmd, 8)
    'dbg.NewLine
    if (tmp <> 0)
      dbg.Str(string("Command: "))
      dbg.Hex(tmp, 8)
      dbg.NewLine

      case tmp
        CMD_NOP:
        CMD_ECHOBYTE:   EchoByte
        CMD_ECHOBUF:    EchoBuf
        CMD_DSKRES:     DiskReset
        CMD_DSKSTAT:    DiskStatus
        CMD_DSKPUT:     DiskPutBuf
        CMD_DSKGET:     DiskGetBuf
        CMD_DSKRD:      DiskRead
        CMD_DSKWR:      DiskWrite
        CMD_DSKTYPE:    DiskType
        CMD_DSKCAP:     DiskCapacity
        CMD_DSKCSD:     DiskCSD
        CMD_VIDOUT:     VideoOut
        CMD_KBDSTAT:    KeyboardStatus
        CMD_KBDRD:      KeyboardRead
        CMD_SPKTONE:    SpeakerTone
        CMD_SIOINIT:    SerialInit
        CMD_SIORX:      SerialRx
        CMD_SIOTX:      SerialTx
        CMD_SIORXST:    SerialRxStat
        CMD_SIOTXST:    SerialTxStat
        CMD_SIORXFL:    SerialRxFlush
        CMD_SIOTXFL:    SerialTxFlush
        CMD_RESET:      Reboot
        CMD_VERSION:    GetVersion

      Cmd := 0
      dbg.Str(string("*End of Command*"))
      dbg.NewLine
      
  MsgNewLine
  MsgStr(string("ParPortProp Shutdown!"))
  MsgNewLine

PRI EchoByte

  ExecFunction(FUNC_GETBYTE)
  !ByteVal
  ExecFunction(FUNC_PUTBYTE)

  return

PRI EchoBuf

  BufPtr := @DskBuf
  BufSize := 512

  bytefill(BufPtr, $FF, BufSize) 
  'DumpBuffer(@DskBuf)

  ExecFunction(FUNC_GETBUF)
  'DumpBuffer(@DskBuf)

  ExecFunction(FUNC_PUTBUF)

  return

PRI DiskReset

  CardType := 0
  dbg.Str(string("sdc.Start:"))
  DskStat := \sdc.Start(SD_BASE)
  Result := DskStat
  dbg.Dec(DskStat)
  dbg.NewLine

  ByteVal := (DskStat < 0)
  ExecFunction(FUNC_PUTBYTE)
  
  if (DskStat > 0)
    CardType := DskStat

  return

PRI DiskStatus | Stat

  dbg.Str(string("Disk Status:"))
  dbg.Dec(DskStat)
  dbg.NewLine

  BufPtr := @DskStat
  BufSize := 4
  ExecFunction(FUNC_PUTBUF)  

  return

PRI DiskPutBuf

  BufPtr := @DskBuf
  BufSize := 512

  bytefill(BufPtr, $00, BufSize) 

  ExecFunction(FUNC_GETBUF)

  'DumpBuffer(@DskBuf)

  return

PRI DiskGetBuf

  BufPtr := @DskBuf
  BufSize := 512

  ExecFunction(FUNC_PUTBUF)

  return

PRI DiskRead

  BufPtr := @DskBlock
  BufSize := 4

  ExecFunction(FUNC_GETBUF)

  dbg.Str(string("sdc.ReadBlock("))
  dbg.Hex(DskBlock, 8)
  dbg.Str(string("): "))
  DskStat := \sdc.ReadBlock(DskBlock, @DskBuf)
  Result := DskStat
  dbg.Dec(DskStat)
  dbg.NewLine

  ByteVal := (DskStat <> 0)
  ExecFunction(FUNC_PUTBYTE)

  'DumpBuffer(@DskBuf)  

  return

PRI DiskWrite

  'DumpBuffer(@DskBuf)  

  BufPtr := @DskBlock
  BufSize := 4

  ExecFunction(FUNC_GETBUF)

  dbg.Str(string("sdc.WriteBlock("))
  dbg.Hex(DskBlock, 8)
  dbg.Str(string("): "))
  DskStat := \sdc.WriteBlock(DskBlock, @DskBuf)
  Result := DskStat
  dbg.Dec(DskStat)
  dbg.NewLine

  ByteVal := (DskStat <> 0)
  ExecFunction(FUNC_PUTBYTE)  

  return

PRI DiskType

  ByteVal := CardType
  ExecFunction(FUNC_PUTBYTE)  

PRI DiskCapacity | tmp

  tmp := \sdc.GetCapacity
  BufPtr := @tmp
  BufSize := 4
  ExecFunction(FUNC_PUTBUF)

PRI DiskCSD

  \sdc.GetCSD(@DskBuf)    
  BufPtr := @DskBuf
  BufSize := 16
  ExecFunction(FUNC_PUTBUF)

PRI VideoOut

  ExecFunction(FUNC_GETBYTE)

  dbg.Str(string("VideoOut: "))
  dbg.Hex(ByteVal, 2)

  dsp.processChar(ByteVal)

  dbg.Str(string(" <done>"))
  dbg.NewLine

  Activity

  return

PRI KeyboardStatus

  dbg.Str(string("KeyboardStatus: "))

  ByteVal := kbd.GotKey

  if (ByteVal)
    Activity

  dbg.Hex(ByteVal, 2)
  dbg.Str(string(" <done>"))
  dbg.NewLine

  ExecFunction(FUNC_PUTBYTE)

  return

PRI KeyboardRead

  repeat until kbd.GotKey

  ByteVal := kbd.GetKey

  ExecFunction(FUNC_PUTBYTE)

  Activity

  return

PRI SpeakerTone | Freq, Duration, tmp

  ExecFunction(FUNC_GETBYTE)    ' tone
  Freq := (ByteVal * 10)

  ExecFunction(FUNC_GETBYTE)    ' duration
  Duration := ((CLKFREQ >> 8) * ByteVal)

  dbg.Str(String("Speaker Tone: "))
  dbg.Dec(Freq)
  dbg.Str(String("Hz, "))
  tmp := (CLKFREQ / 1000)
  dbg.Dec(Duration / tmp) 
  dbg.Str(String("ms"))
  dbg.NewLine

  dsp.speakerFrequency(Freq)
  waitcnt(Duration + cnt)
  dsp.speakerFrequency(-1)

  return

PRI SerialInit | Baudrate

  BufPtr := @Baudrate
  BufSize := 4

  ExecFunction(FUNC_GETBUF)

  sio.Start(31, 30, 0, Baudrate) 

  return

PRI SerialRx

  ByteVal := sio.rx
  ExecFunction(FUNC_PUTBYTE)

  return

PRI SerialTx

  ExecFunction(FUNC_GETBYTE)
  sio.tx(ByteVal)

  return

PRI SerialRxStat

  ByteVal := sio.rxcount
  ExecFunction(FUNC_PUTBYTE)

PRI SerialTxStat

  ByteVal := sio.txcount                                        
  ExecFunction(FUNC_PUTBYTE)

PRI SerialRxFlush

  sio.rxflush

  return

PRI SerialTxFlush

  ' not implemented by serial driver...

  return

PRI GetVersion | tmp

  tmp := VERSION
  BufPtr := @tmp
  BufSize := 4
  ExecFunction(FUNC_PUTBUF)  

PRI ExecFunction (Function)
                             
  dbg.Str(string("Function: "))
  dbg.Hex(Function, 8)

  if (Cmd < 0)
    dbg.Str(string(" <bypassed>"))
    dbg.NewLine
    return

  Func := Function

  repeat until (Func =< 0)

  ' FIX: use 'abort' below instead of setting Cmd := -1

  if (Func < 0)
    dbg.Str(string(" <aborted>"))
    Cmd := -1
  else    
    dbg.Str(string(" <done>"))
     
  dbg.NewLine

  return

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

PRI DumpBuffer(Buffer) | i, j

  repeat i from 0 to 31    
    dbg.Hex(i * 16, 4)
    dbg.Str(string(": "))
    repeat j from 0 to 15
      dbg.Hex((byte[Buffer][((i * 16) + j)]), 2)
      dbg.Str(string(" "))
    dbg.NewLine

PRI Reverse(Val) | i

  repeat i from 0 to 3
    Result.byte[i] := Val.byte[3 - i]

PRI Timer
  TimerCount := SLEEP
  repeat
    waitcnt(clkfreq * 1 + cnt)
    if (TimerCount > 0)
      if (TimerCount == 1)
        dsp.VidOff
      TimerCount--

PRI Activity
  if (SLEEP > 0)
    if (TimerCount == 0)
      dsp.VidOn
    TimerCount := SLEEP

DAT

strVer	byte	"F/W v0.97",0
strHW	byte	"ParPortProp",0
strROM	byte	"RomWBW",0


                        org 0

Entry                   mov outa, xppi_idle             ' set ack and strobe to inactive state
                        mov dira, xppi_dirrd            ' pin direction to default (read)

                        ' Notify host we are ready with $AA
                        'waitpeq Zero, xppi_ibf          ' wait for IBF to be inactive (low)
                        or outa, #$AA
                        mov dira, xppi_dirwr            ' configure data bits for output
                        andn outa, xppi_stb             ' assert strobe (low)
                        nop                             ' time for PPI to see strobe
                        or outa, xppi_stb               ' deassert strobe (high)
                        mov dira, xppi_dirrd            ' configure data bits for input

                        '' Second part of notification is $55
                        'waitpeq Zero, xppi_ibf          ' wait for IBF to be inactive (low)
                        'mov outa, xppi_idle             ' clear out old data bits
                        'or outa, #$55                    ' set new data bits
                        'mov dira, xppi_dirwr            ' configure data bits for output
                        'andn outa, xppi_stb             ' assert strobe (low)
                        'nop                             ' time for PPI to see strobe
                        'or outa, xppi_stb               ' deassert strobe (high)
                        'mov dira, xppi_dirrd            ' configure data bits for input

DoCmd                   ' Discard incoming bytes until we see cmd signal

                        mov xtmp, ina                   ' get pins
                        test xtmp, xppi_cmd wz          ' is command ready?
                        if_nz jmp #DoCmd1               ' yes, handle it now
                        test xtmp, xppi_obf wz          ' is bogus data pending?
                        if_nz jmp #DoCmd                ' nope, loop                        
                        andn outa, xppi_ack             ' assert ack (low)
                        waitpeq xppi_obf, xppi_obf      ' wait for OBF to be inactive (high)
                        or outa, xppi_ack               ' deassert ack (high)
                        jmp #DoCmd                      ' bad byte swallowed, loop

                        'waitpeq xppi_cmd, xppi_cmd      ' wait for command signal

DoCmd1                  ' Receive incoming commands
                        waitpeq Zero, xppi_obf          ' wait for it to show up (OBF low)
                        andn outa, xppi_ack             ' assert ack (low)
                        waitpeq xppi_obf, xppi_obf      ' wait for OBF to be inactive (high)
                        mov xtmp, ina                   ' now we can get the data bits                   
                        or outa, xppi_ack               ' deassert ack (high)

                        waitpeq Zero, xppi_cmd          ' wait for command signal to clear

                        and xtmp, #$FF                  ' isolate data bits
                        wrlong xtmp, CmdAdr             ' Record it

DoFunc                  ' Function processing loop

                        rdlong xtmp, FuncAdr
                        cmp xtmp, #FUNC_PUTBYTE wz
                        if_e jmp #PutByte
                        cmp xtmp, #FUNC_GETBYTE wz
                        if_e jmp #GetByte
                        cmp xtmp, #FUNC_PUTBUF wz
                        if_e jmp #PutBuf
                        cmp xtmp, #FUNC_GETBUF wz
                        if_e jmp #GetBuf

                        ' Check for a new command to be pending???

                        ' Check Cmd, loop until it is zero (idle)
                        
                        rdlong xtmp, CmdAdr
                        cmp xtmp, Zero wz
                        if_e jmp #DoCmd
                        jmp #DoFunc

PutByte                 ' Parm -> PPI

                        andn outa, #$FF                 ' clear old data bits
                        rdbyte xtmp, ByteValAdr         ' get byte value into xtmp
                        and xtmp, #$FF                  ' careful to ensure only data bits set
                        or outa, xtmp                   ' set new data bits

                        waitpne xppi_ibf, xppi_ibfcmd   ' wait for IBF empty or CMD flag
                        mov xtmp, ina                   ' read the pins
                        test xtmp, xppi_cmd wz          ' CMD pending?
                        if_nz jmp #AbortCmd             ' Yes, clear out                        

                        mov dira, xppi_dirwr            ' configure data bits for output
                        andn outa, xppi_stb             ' assert strobe (low)
                        nop                             ' time for PPI to see strobe
                        or outa, xppi_stb               ' deassert strobe (high)
                        mov dira, xppi_dirrd            ' configure data bits for input

                        wrlong Zero, FuncAdr            ' clear out original function request
                        jmp #DoFunc                     ' and return                        

GetByte                 ' PPI -> Parm

                        waitpne xppi_obf, xppi_obfcmd   ' wait for OBF empty or CMD flag
                        mov xtmp, ina                   ' read the pins
                        test xtmp, xppi_cmd wz          ' CMD pending?
                        if_nz jmp #AbortCmd             ' Yes, clear out

                        andn outa, xppi_ack             ' assert ack (low)
                        waitpeq xppi_obf, xppi_obf      ' wait for OBF to be inactive (high)
                        mov xtmp, ina                   ' now we can get the data bits
                        or outa, xppi_ack               ' deassert ack (high)

                        wrbyte xtmp, ByteValAdr         ' Save it in main memory
                        
                        wrlong Zero, FuncAdr            ' clear out original function request
                        jmp #DoFunc                     ' and return                        

PutBuf                  ' Buf -> PPI

                        rdlong TempAdr, BufPtrAdr       ' get buffer pointer       
                        rdlong TempCnt,BufSizeAdr       ' get the buffer size for operation
                         
PutBuf1                 andn outa, #$FF                 ' clear old data bits
                        rdbyte xtmp, TempAdr             ' get value into xtmp
                        and xtmp, #$FF                  ' careful to ensure only data bits set
                        or outa, xtmp                   ' set new data bits

                        waitpne xppi_ibf, xppi_ibfcmd   ' wait for IBF empty or CMD flag
                        mov xtmp, ina                   ' read the pins
                        test xtmp, xppi_cmd wz          ' CMD pending?
                        if_nz jmp #AbortCmd             ' Yes, clear out                        

                        ' FIX: move setting of dir outside of loop
                        
                        mov dira, xppi_dirwr            ' configure data bits for output
                        andn outa, xppi_stb             ' assert strobe (low)
                        nop                             ' delay for PPI to see strobe
                        or outa, xppi_stb               ' deassert strobe (high)
                        mov dira, xppi_dirrd            ' configure data bits for input

                        sub TempCnt, #1
                        add TempAdr, #1
                        cmp TempCnt, Zero wz
                        if_ne jmp #PutBuf1

                        wrlong Zero, FuncAdr            ' clear out original function request
                        jmp #DoFunc                     ' and return                        

GetBuf                  ' PPI -> Buf

                        rdlong TempAdr, BufPtrAdr       ' get buffer pointer       
                        rdlong TempCnt,BufSizeAdr       ' get the buffer size for operation
                        
GetBuf1                 waitpne xppi_obf, xppi_obfcmd   ' wait for OBF empty or CMD flag
                        mov xtmp, ina                   ' read the pins
                        test xtmp, xppi_cmd wz          ' CMD pending?
                        if_nz jmp #AbortCmd             ' Yes, clear out                        

                        andn outa, xppi_ack             ' assert ack (low)
                        waitpeq xppi_obf, xppi_obf      ' wait for OBF to be inactive (high)
                        mov xtmp, ina                   ' now we can get the data bits                   
                        or outa, xppi_ack               ' deassert ack (high)

                        wrbyte xtmp, TempAdr

                        sub TempCnt, #1
                        add TempAdr, #1
                        cmp TempCnt, Zero wz
                        if_ne jmp #GetBuf1

                        wrlong Zero, FuncAdr            ' clear out original function request
                        jmp #DoFunc                     ' and return

AbortCmd                mov dira, xppi_dirrd            ' configure data bits for input
                        wrlong NegOne, FuncAdr          ' abort any active function
                        jmp #DoFunc                     ' handle pending command
                        
CmdAdr                  long    0
FuncAdr                 long    0
ByteValAdr              long    0
BufPtrAdr               long    0
BufSizeAdr              long    0

Zero                    long    0
NegOne                  long    -1

xppi_cmd                long    PPI_CMD                 ' pin 8, active high
xppi_stb                long    PPI_STB                 ' pin 9, active low
xppi_ibf                long    PPI_IBF                 ' pin 10, active high
xppi_ack                long    PPI_ACK                 ' pin 11, active low
xppi_obf                long    PPI_OBF                 ' pin 12, active low

xppi_idle               long    PPI_STB + PPI_ACK
xppi_ibfcmd             long    PPI_IBF + PPI_CMD
xppi_obfcmd             long    PPI_OBF + PPI_CMD

xppi_dirrd              long    PPI_STB + PPI_ACK
xppi_dirwr              long    PPI_STB + PPI_ACK + $FF

xtmp                    long    $FFFF

TempVal                 res     1
TempAdr                 res     1
TempCnt                 res     1

                        fit