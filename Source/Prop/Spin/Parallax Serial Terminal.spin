{{
─────────────────────────────────────────────────
File: Parallax Serial Terminal.spin
Version: 1.0
Copyright (c) 2009 Parallax, Inc.
See end of file for terms of use.

Authors: Jeff Martin, Andy Lindsay, Chip Gracey  
─────────────────────────────────────────────────
}}

{
HISTORY:
  This object is made for direct use with the Parallax Serial Terminal; a simple serial communication program
  available with the Propeller Tool installer and also separately via the Parallax website (www.parallax.com).

  This object is heavily based on FullDuplexSerialPlus (by Andy Lindsay), which is itself heavily based on
  FullDuplexSerial (by Chip Gracey).

USAGE:
  • Call Start, or StartRxTx, first.
  • Be sure to set the Parallax Serial Terminal software to the baudrate specified in Start, and the proper COM port.
  • At 80 MHz, this object properly receives/transmits at up to 250 Kbaud, or performs transmit-only at up to 1 Mbaud.
  
}
  
CON
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen      
  CE = 11  ''CE: Clear to End of line     
  CB = 12  ''CB: Clear lines Below 

  HM =  1  ''HM: HoMe cursor       
  PC =  2  ''PC: Position Cursor in x,y          
  PX = 14  ''PX: Position cursor in X         
  PY = 15  ''PY: Position cursor in Y         

  NL = 13  ''NL: New Line        
  LF = 10  ''LF: Line Feed       
  ML =  3  ''ML: Move cursor Left          
  MR =  4  ''MR: Move cursor Right         
  MU =  5  ''MU: Move cursor Up          
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB          
  BS =  8  ''BS: BackSpace          
           
  BP =  7  ''BP: BeeP speaker          

CON

   BUFFER_LENGTH = 64                                   'Recommended as 64 or higher, but can be 2, 4, 8, 16, 32, 64, 128 or 256.
   BUFFER_MASK   = BUFFER_LENGTH - 1
   MAXSTR_LENGTH = 49                                   'Maximum length of received numerical string (not including zero terminator).

VAR

  long  cog                                             'Cog flag/id

  long  rx_head                                         '9 contiguous longs (must keep order)
  long  rx_tail
  long  tx_head
  long  tx_tail
  long  rx_pin
  long  tx_pin
  long  rxtx_mode
  long  bit_ticks
  long  buffer_ptr
                     
  byte  rx_buffer[BUFFER_LENGTH]                        'Receive and transmit buffers
  byte  tx_buffer[BUFFER_LENGTH]

  byte  str_buffer[MAXSTR_LENGTH+1]                     'String buffer for numerical strings

PUB Start(baudrate) : okay
{{Start communication with the Parallax Serial Terminal using the Propeller's programming connection.
Waits 1 second for connection, then clears screen.
  Parameters:
    baudrate - bits per second.  Make sure it matches the Parallax Serial Terminal's
               Baud Rate field.
  Returns    : True (non-zero) if cog started, or False (0) if no cog is available.}}

  okay := StartRxTx(31, 30, 0, baudrate)
  'waitcnt(clkfreq + cnt)                                'Wait 1 second for PST
  Clear                                                 'Clear display

PUB StartRxTx(rxpin, txpin, mode, baudrate) : okay
{{Start serial communication with designated pins, mode, and baud.
  Parameters:
    rxpin    - input pin; receives signals from external device's TX pin.
    txpin    - output pin; sends signals to  external device's RX pin.
    mode     - signaling mode (4-bit pattern).
               bit 0 - inverts rx.
               bit 1 - inverts tx.
               bit 2 - open drain/source tx.
               bit 3 - ignore tx echo on rx.
    baudrate - bits per second.
  Returns    : True (non-zero) if cog started, or False (0) if no cog is available.}}

  stop
  longfill(@rx_head, 0, 4)
  longmove(@rx_pin, @rxpin, 3)
  bit_ticks := clkfreq / baudrate
  buffer_ptr := @rx_buffer
  okay := cog := cognew(@entry, @rx_head) + 1

PUB Stop
{{Stop serial communication; frees a cog.}}

  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 9)

PUB Char(bytechr)
{{Send single-byte character.  Waits for room in transmit buffer if necessary.
  Parameter:
    bytechr - character (ASCII byte value) to send.}}

  repeat until (tx_tail <> ((tx_head + 1) & BUFFER_MASK))
  tx_buffer[tx_head] := bytechr
  tx_head := (tx_head + 1) & BUFFER_MASK

  if rxtx_mode & %1000
    CharIn

PUB Chars(bytechr, count)
{{Send multiple copies of a single-byte character. Waits for room in transmit buffer if necessary.
  Parameters:
    bytechr - character (ASCII byte value) to send.
    count   - number of bytechrs to send.}}

  repeat count
    Char(bytechr)

PUB CharIn : bytechr
{{Receive single-byte character.  Waits until character received.
  Returns: $00..$FF}}

  repeat while (bytechr := RxCheck) < 0

PUB Str(stringptr)
{{Send zero terminated string.
  Parameter:
    stringptr - pointer to zero terminated string to send.}}

  repeat strsize(stringptr)
    Char(byte[stringptr++])

PUB StrIn(stringptr)
{{Receive a string (carriage return terminated) and stores it (zero terminated) starting at stringptr.
Waits until full string received.
  Parameter:
    stringptr - pointer to memory in which to store received string characters.
                Memory reserved must be large enough for all string characters plus a zero terminator.}}
    
  StrInMax(stringptr, -1)

PUB StrInMax(stringptr, maxcount)
{{Receive a string of characters (either carriage return terminated or maxcount in length) and stores it (zero terminated)
starting at stringptr.  Waits until either full string received or maxcount characters received.
  Parameters:
    stringptr - pointer to memory in which to store received string characters.
                Memory reserved must be large enough for all string characters plus a zero terminator (maxcount + 1).
    maxcount  - maximum length of string to receive, or -1 for unlimited.}}
    
  repeat while (maxcount--)                                                     'While maxcount not reached
    if (byte[stringptr++] := CharIn) == NL                                      'Get chars until NL
      quit
  byte[stringptr+(byte[stringptr-1] == NL)]~                                    'Zero terminate string; overwrite NL or append 0 char

PUB Dec(value) | i, x
{{Send value as decimal characters.
  Parameter:
    value - byte, word, or long value to send as decimal characters.}}

  x := value == NEGX                                                            'Check for max negative
  if value < 0
    value := ||(value+x)                                                        'If negative, make positive; adjust for max negative
    Char("-")                                                                   'and output sign

  i := 1_000_000_000                                                            'Initialize divisor

  repeat 10                                                                     'Loop for 10 digits
    if value => i                                                               
      Char(value / i + "0" + x*(i == 1))                                        'If non-zero digit, output digit; adjust for max negative
      value //= i                                                               'and digit from value
      result~~                                                                  'flag non-zero found
    elseif result or i == 1
      Char("0")                                                                 'If zero digit (or only digit) output it
    i /= 10                                                                     'Update divisor

PUB DecIn : value
{{Receive carriage return terminated string of characters representing a decimal value.
  Returns: the corresponding decimal value.}}

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 10)

PUB Bin(value, digits)
{{Send value as binary characters up to digits in length.
  Parameters:
    value  - byte, word, or long value to send as binary characters.
    digits - number of binary digits to send.  Will be zero padded if necessary.}}

  value <<= 32 - digits
  repeat digits
    Char((value <-= 1) & 1 + "0")

PUB BinIn : value
{{Receive carriage return terminated string of characters representing a binary value.
 Returns: the corresponding binary value.}}
   
  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 2)
   
PUB Hex(value, digits)
{{Send value as hexadecimal characters up to digits in length.
  Parameters:
    value  - byte, word, or long value to send as hexadecimal characters.
    digits - number of hexadecimal digits to send.  Will be zero padded if necessary.}}

  value <<= (8 - digits) << 2
  repeat digits
    Char(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB HexIn : value
{{Receive carriage return terminated string of characters representing a hexadecimal value.
  Returns: the corresponding hexadecimal value.}}

  StrInMax(@str_buffer, MAXSTR_LENGTH)
  value := StrToBase(@str_buffer, 16)

PUB Clear
{{Clear screen and place cursor at top-left.}}
  
  Char(CS)

PUB ClearEnd
{{Clear line from cursor to end of line.}}
  
  Char(CE)
  
PUB ClearBelow
{{Clear all lines below cursor.}}
  
  Char(CB)
  
PUB Home
{{Send cursor to home position (top-left).}}
  
  Char(HM)
  
PUB Position(x, y)
{{Position cursor at column x, row y (from top-left).}}
  
  Char(PC)
  Char(x)
  Char(y)
  
PUB PositionX(x)
{{Position cursor at column x of current row.}}
  Char(PX)
  Char(x)
  
PUB PositionY(y)
{{Position cursor at row y of current column.}}
  Char(PY)
  Char(y)

PUB NewLine
{{Send cursor to new line (carriage return plus line feed).}}
  
  Char(NL)
  Char(LF)
  
PUB LineFeed
{{Send cursor down to next line.}}
  
  Char(LF)
  
PUB MoveLeft(x)
{{Move cursor left x characters.}}
  
  repeat x
    Char(ML)
  
PUB MoveRight(x)
{{Move cursor right x characters.}}
  
  repeat x
    Char(MR)
  
PUB MoveUp(y)
{{Move cursor up y lines.}}
  
  repeat y
    Char(MU)
  
PUB MoveDown(y)
{{Move cursor down y lines.}}
  
  repeat y
    Char(MD)
  
PUB Tab
{{Send cursor to next tab position.}}
  
  Char(TB)
  
PUB Backspace
{{Delete one character to left of cursor and move cursor there.}}
  
  Char(BS)
  
PUB Beep
{{Play bell tone on PC speaker.}}
  
  Char(BP)
  
PUB RxCount : count
{{Get count of characters in receive buffer.
  Returns: number of characters waiting in receive buffer.}}

  count := rx_head - rx_tail
  count -= BUFFER_LENGTH*(count < 0)

PUB RxFlush
{{Flush receive buffer.}}

  repeat while rxcheck => 0
    
PRI RxCheck : bytechr
{Check if character received; return immediately.
  Returns: -1 if no byte received, $00..$FF if character received.}

  bytechr~~
  if rx_tail <> rx_head
    bytechr := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & BUFFER_MASK

PRI StrToBase(stringptr, base) : value | chr, index
{Converts a zero terminated string representation of a number to a value in the designated base.
Ignores all non-digit characters (except negative (-) when base is decimal (10)).}

  value := index := 0
  repeat until ((chr := byte[stringptr][index++]) == 0)
    chr := -15 + --chr & %11011111 + 39*(chr > 56)                              'Make "0"-"9","A"-"F","a"-"f" be 0 - 15, others out of range     
    if (chr > -1) and (chr < base)                                              'Accumulate valid values into result; ignore others
      value := value * base + chr                                                  
  if (base == 10) and (byte[stringptr] == "-")                                  'If decimal, address negative sign; ignore otherwise
    value := - value
       
DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get tx_pin
                        rdlong  t2,t1
                        mov     txmask,#1
                        shl     txmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#BUFFER_LENGTH

                        test    rxtxmode,#%100  wz    'init tx pin according to mode
                        test    rxtxmode,#%010  wc
        if_z_ne_c       or      outa,txmask
        if_z            or      dira,txmask

                        mov     txcode,#transmit      'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode         'run chunk of tx code, then return

                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt                          

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   jmpret  rxcode,txcode         'run chunk of tx code, then return

                        mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF

                        rdlong  t2,par                'save received byte and inc head
                        add     t2,rxbuff
                        wrbyte  rxdata,t2
                        sub     t2,rxbuff
                        add     t2,#1
                        and     t2,#BUFFER_MASK
                        wrlong  t2,par

                        jmp     #receive              'byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,par                'check for head <> tail
                        add     t1,#2 << 2
                        rdlong  t2,t1
                        add     t1,#1 << 2
                        rdlong  t3,t1
                        cmp     t2,t3           wz
        if_z            jmp     #transmit

                        add     t3,txbuff             'get byte and inc tail
                        rdbyte  txdata,t3
                        sub     t3,txbuff
                        add     t3,#1
                        and     t3,#BUFFER_MASK
                        wrlong  t3,t1

                        or      txdata,#$100          'ready byte to transmit
                        shl     txdata,#2
                        or      txdata,#1
                        mov     txbits,#11
                        mov     txcnt,cnt

:bit                    test    rxtxmode,#%100  wz    'output bit on tx pin 
                        test    rxtxmode,#%010  wc    'according to mode
        if_z_and_c      xor     txdata,#1
                        shr     txdata,#1       wc
        if_z            muxc    outa,txmask        
        if_nz           muxnc   dira,txmask
                        add     txcnt,bitticks        'ready next cnt

:wait                   jmpret  txcode,rxcode         'run chunk of rx code, then return

                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        djnz    txbits,#:bit          'another bit to transmit?

                        jmp     #transmit             'byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}