'' VGA_1024.spin
''
'' MODIFIED BY VINCE BRIEL FOR POCKETERM FEATURES
'' MODIIFED BY JEFF LEDGER / AKA OLDBITCOLLECTOR
''

CON
  cols          = 80 '128                               ' number of screen columns
  lcols         = cols / 4                              ' number of long in columns
  rows          = 40 '64                                ' number of screen rows
  chars         = rows*cols                             ' number of screen characters
  esc           = $CB                                   ' keyboard esc char
  rowsnow       = 36                                    ' adjusted for split screen effect
  maxChars      = rowsnow*cols                          ' adjusted value for split screen effect
  lastChar      = maxChars / 4                          ' last screen position in longs adjusted for split
  lastLine      = (rowsnow - 1) * cols                  ' character position of last row
  cols1         = 81                                    ' adjusted value for 80th character
  TURQUOISE     = $29

OBJ
  vga : "vga_Hires_Text"

VAR
  byte  screen[chars]           ' screen character buffer
  byte  tmpl[cols]              ' temporary line buffer
  word  colors[rows]            ' color specs for each screen row (see ColorPtr description above)
  byte  cursor[6]               ' cursor info array (see CursorPtr description above)
  long  sync, loc, xloc, yloc   ' sync used by VGA routine, others are local screen pointers
  long  kbdreq                  ' global val of kbdflag
  long  BR[8]
  long  Brate
  byte  inverse
  byte  invs
  byte  state                   ' Current state of state machine
  word  pos                     ' Current Position on the screen
  word  oldpos                  ' Previous location of cursor before update
  word  regionTop, regionBot    ' Scroll region top/bottom
  long  arg0                    ' First argument of escape sequence
  long  arg1                    ' Second argument of escape sequence
  byte  lastc                   ' Last displayed char
  word  statpos
  long  vgabasepin
  
PUB start(BasePin) | i, char
  vgabasepin := BasePin

''init screen colors to gold on blue
  repeat i from 0 to rows - 1
    colors[i] := $08F0          '$2804 (if you want cyan on blue)

''init cursor attributes
  cursor[2] := %110             ' init cursor to underscore with slow blink
  BR[0]:=300 
  BR[1]:=1200
  BR[2]:=2400
  BR[3]:=4800
  BR[4]:=9600
  BR[5]:=19200
  BR[6]:=38400
  BR[7]:=57600
  BR[8]:=115200
  xloc := cursor[0] := 0
  yloc := cursor[1] := 0
  loc  := xloc + yloc*cols
  
  pos := 0
  regionTop := 0
  regionBot := 35 * cols
  state := 0
  statpos := 37 * cols

PUB vidon
  if (!vga.start(vgabasepin, @screen, @colors, @cursor, @sync))
    return false
  
  'waitcnt(clkfreq * 1 + cnt)    'wait 1 second for cogs to start


PUB vidoff
  vga.stop

PUB inv(c)
  inverse:=c

PUB color(colorVal) | i
  repeat i from 0 to rows - 1
    colors[i] := $0000 | colorVal

PUB cursorset(c) | i
  i:=%000
  if c == 1
    i:= %001
  if c == 2
    i:= %010
  if c == 3
    i:= %011
  if c == 4
    i:= %101
  if c == 5
    i:= %110
  if c == 6
    i:= %111
  if c == 7
    i:= %000  
  cursor[2] := i
  
PUB bin(value, digits)

'' Print a binary number, specify number of digits

  repeat while digits > 32
    outc("0")
    digits--

  value <<= 32 - digits

  repeat digits
    outc((value <-= 1) & 1 + "0")


PUB clrbtm(ColorVal) | i
   repeat i from 36 to rows - 1                         'was 35
    colors[i] := $0000 + ColorVal

PUB cls1(VerStr) | i

  longfill(@screen[0], $20202020, chars / 4)

  clrbtm(TURQUOISE)
  
  inverse := 1
  statprint(36, 0, VerStr)
  inverse := 0

  repeat i from 37 to (rows - 1)    
    statprint(i,0, string("                                                                                "))

 
{{
  x :=xloc
  y := yloc
  invs := inverse
  ''clrbtm(TURQUOISE)
  longfill(@screen, $20202020, chars/4)
  xloc := 0
  yloc :=0
  loc  := xloc + yloc*cols
  repeat 80
     outc(32)
  xloc := 0
  yloc :=36
  loc  := xloc + yloc*cols
  inverse := 1
  str(string("                                                                                "))
  inverse := 0
  str(string("Baud Rate: "))
  i:= BR[6]
  dec(i)
  str(string("   "))
  xloc := 18
  loc := xloc + yloc*cols
  str(string("Color  "))
  str(string("PC Port: "))
  if pcport == 1
     str(string("OFF "))
  if pcport == 0
     str(string("ON  "))   
  str(string(" Force 7 bit: "))
  if ascii == 0
     str(string("NO  "))
  if ascii == 1
     str(string("YES "))
  str(string(" Cursor   CR W/LF: "))
  if CR == 1
     str(string("YES"))
  if CR == 0
     str(string("NO "))  
  outc(13)
  outc(10)
  
  inverse:=1
  xloc := 6
  loc  := xloc + yloc*cols
  str(string("F1"))
  xloc := 19
  loc  := xloc + yloc*cols
  str(string("F2"))
  xloc := 30
  loc  := xloc + yloc*cols
  str(string("F3"))
  xloc := 46
  loc  := xloc + yloc*cols
  str(string("F4"))
  xloc := 58
  loc  := xloc + yloc*cols
  str(string("F5"))
  xloc := 70
  loc  := xloc + yloc*cols
  str(string("F6")) 
  inverse := invs
  xloc := cursor[0] := x 'right & left       was 0
  yloc := cursor[1] := y 'from top           was 1
  loc  := xloc + yloc*cols
}}

PUB clsupdate(c,screencolor,PCPORT,ascii,CR) | i,x,y,locold
        
  invs := inverse
  locold := loc
  x := xloc
  y := yloc
  ''(TURQUOISE)
  xloc := 0
  yloc :=36
  loc  := xloc + yloc*cols
  inverse := 1
  str(string("                                                                                "))
  inverse := 0
  xloc := 0
  yloc :=37
  loc  := xloc + yloc*cols
  str(string("Baud Rate: "))
  i:= BR[6]
  dec(i)
  str(string("   "))
  xloc := 18
  loc := xloc + yloc*cols
  
  str(string("Color  "))
  str(string("PC Port: "))
  if pcport == 1
     str(string("OFF "))
  if pcport == 0
     str(string("ON  "))   
  str(string(" Force 7 bit: "))
  if ascii == 0
     str(string("NO  "))
  if ascii == 1
     str(string("YES "))
  str(string(" Cursor   CR W/LF: "))
  if CR == 1
     str(string("YES"))
  if CR == 0
     str(string("NO "))  
  xloc := 0
  yloc :=38
  loc  := xloc + yloc*cols
  inverse:=1
  xloc := 6
  loc  := xloc + yloc*cols
  str(string("F1"))
  xloc := 19
  loc  := xloc + yloc*cols
  str(string("F2"))
  xloc := 30
  loc  := xloc + yloc*cols
  str(string("F3"))
  xloc := 46
  loc  := xloc + yloc*cols
  str(string("F4"))
  xloc := 58
  loc  := xloc + yloc*cols
  str(string("F5"))
  xloc := 70
  loc  := xloc + yloc*cols
  str(string("F6")) 
  inverse := invs
  xloc := cursor[0] := x
  yloc := cursor[1] := y
'  loc  := xloc + yloc*cols
  loc := locold

PUB dec(value) | i

'' Print a decimal number

  if value < 0
    -value
    outc("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      outc(value/i + "0")
      value //= i
      result~~
    elseif result or i == 1
      outc("0")
    i /= 10     

PUB hex(value, digits)

'' Print a hexadecimal number, specify number of digits

  repeat while digits > 8
    outc("0")
    digits--

  value <<= (8 - digits) << 2

  repeat digits
    outc(lookupz((value <-= 4) & $f : "0".."9", "A".."F"))


PUB str(string_ptr)

'' Print a zero terminated string

  repeat strsize(string_ptr)
    process_char(byte[string_ptr++])

PUB statprint(r, c, str1) | x, ptr
 
  ptr := r * cols + c
  repeat x from 0 to STRSIZE(str1) - 1
    putc(ptr++, BYTE[str1 + x])

PUB statnum(r, c, num1)  | i, ptr

  ptr := r * cols + c

  if num1 < 0
    -num1
    putc(ptr++,"-")

  i := 1_000_000_000

  repeat 10
    if num1 => i
      putc(ptr++, (num1/i +"0"))
      num1 //= i
      result~~
    elseif result or i == 1
      putc(ptr++, "0")
    i /= 10

PUB putc(position, c)
  if inverse
    c |= $80
  screen[position] := c
  
PUB cls
  longfill (@screen, $20202020, lastChar)

PUB fullcls
  longfill(@screen, $20202020, 800)

PUB setInverse(val)
  inverse := val

PUB setInv(c)
  if c == 7
    setInverse(1)
  else
    setInverse(0)
  
PUB clEOL(position) | count
  count := cols - (position // cols)
  bytefill(@screen + position, $20, count)

PUB clBOL(position) | count
  count := position // cols
  bytefill(@screen + position - count, $20, count)

PUB delLine(position) | src, count
  position -= position // cols

  src := position + cols

  count := (maxChars - src) / 4

  if count > 0
    longmove(@screen + position, @screen + src, count)

  longfill(@screen + lastLine, $20202020, lcols)

PUB clEOS(position)
  cleol(position)
  position += cols - (position // cols)
  repeat while position < maxChars
    longfill(@screen + position, $20202020, lcols)
    pos += cols

PUB setCursorPos(position)
  cursor[0] := position // cols
  cursor[1] := position / cols

PUB insLine(position) | base, nxt
  base := position - (position // cols)
  position := lastLine
  repeat while position > base
    nxt := position - cols
    longmove(@screen + position, @screen + nxt, lcols)
    position := nxt
  clEOL(base)

PUB insChar(position) | count
  count := (cols - (position // cols)) - 1
  bytemove(@tmpl, @screen + position, count)
  screen[position] := " "
  bytemove(@screen + position + 1, @tmpl, count)

PUB delChar(position) | count
  count := (cols - (position // cols)) - 1
  bytemove(@screen + position, @screen + position + 1, count)
  screen[position + count] := " "

PRI inRegion : answer
  answer := (pos => regionTop) AND (pos < regionBot)

PRI scrollUp
  delLine(regionTop)
  if regionBot < maxChars
    insLine(regionBot)

PRI scrollDown
  if regionBot < maxChars
    delLine(regionBot)
  insLine(regionTop)

PRI ansi(c) | x, defVal

  state := 0

  if (c <> "r") AND (c <> "J") AND (c <> "m") AND (c <> "K")
      if arg0 == -1
          arg0 := 1
      if arg1 == -1
          arg1 := 1

  case c
    "@":
      repeat while arg0-- > 0
        insChar(pos)

    "b":
      repeat while arg0-- > 0
        outc(lastc)

    "d":
      if (arg0 < 1) OR (arg0 > rows)
        arg0 := rows
      pos := ((arg0 - 1) * cols) + (pos // cols)

    "m":
      setInv(arg0)
      if arg1 <> -1
        setInv(arg1)

    "r":
      if arg0 < 1
        arg0 := 1
      elseif arg0 > cols
        arg0 := cols
      if arg1 < 1
        arg1 := 1
      elseif arg1 > cols
        arg1 := cols
      if arg1 < arg0
        arg1 := arg0

      regionTop := (arg0 - 1) * cols
      regionBot := arg1 * cols
      pos := 0

    "A":
      repeat while arg0-- > 0
        pos -= cols
        if pos < 0
          pos += cols
          return

    "B":
      repeat while arg0-- > 0
        pos += cols
        if pos => maxChars
          pos -= cols
          return

    "C":
      repeat while arg0-- > 0
        pos += 1
        if pos => maxChars
          pos -= 1
          return

    "D":
      repeat while arg0-- > 0
        pos -= 1
        if pos < 0
          pos := 0
          return

    "G":
      if (arg0 < 1) OR (arg0 > cols)
        arg0 := cols
     pos := (pos - (pos // cols)) + (arg0 - 1)

    "H", "f":
      if arg0 =< 0
        arg0 := 1
      if arg1 =< 0
        arg1 := 1
      pos := (cols * (arg0 - 1)) + (arg1 - 1)
      if pos < 0
        pos := 0
      if pos => maxChars
        pos := maxChars - 1

    "J":
      if arg0 == 1
        clBOL(pos)
        x := pos - cols
        x -= x // cols
        repeat while x => 0
          clEOL(x)
          x -= cols
        return

      if arg0 == 2
        pos := 0

      clEOL(pos)
      x := pos + cols
      x -= (x // cols)
      repeat while x < maxChars
        clEOL(x)
        x += cols

    "K":
      if arg0 == -1
          clEOL(pos)
      elseif arg0 == 1
          clBOL(pos)
      else
          clEOL(pos - (pos // cols))

    "L":
      if inRegion
        repeat while arg0-- > 0
          if regionBot < maxChars
            delLine(regionBot)
          insLine(pos)

    "M":
      if inRegion
        repeat while arg0-- > 0
          delLine(pos)
          if regionBot < maxChars
            insLine(regionBot)            

    "P":
      repeat while arg0--
        delChar(pos)

PRI outc(c)

  putc(pos++, lastc := c)  
  if pos == regionBot
    scrollUp
    pos -= cols
  elseif pos == maxChars
    pos := lastLine
    
PUB process_char(c)
  
  case state

    0:
      if c > 127
        c := $20

      if c => $20
        outc(c)
        setCursorPos(pos)
        return

      if c == $1B
        state := 1
        return

      if c == $0D
        pos := pos - (pos // cols)
        setCursorPos(pos)
        return

      if c == $0A
        if inRegion
            pos += cols
            if pos => regionBot
               scrollUp
               pos -= cols
        else
          pos += cols
          if pos => maxChars
            pos -= cols
        setCursorPos(pos)
        return

      if c == 9
        pos += (8 - (pos // 8))

        if pos => maxChars
         pos := lastLine
         delLine(0)

        setCursorPos(pos)
       return

     if c == 8
       if pos > 0
         pos -= 1
       setCursorPos(pos)
      return

    1:
      case c
          "[":
              arg0 := arg1 := -1
              state := 2
              return

          "P":
              pos += cols
              if pos => maxChars
                  pos -= cols

          "K":
              if pos > 0
                  pos -= 1

          "H":
              pos -= cols
              if pos < 0
                  pos += cols

          "D":
              if inRegion
                  scrollUp

          "M":
              if inRegion
                  scrollDown

          "G":
              pos := 0

          "(":
              state := 5
              return

      state := 0
      return

   2:
      if (c => "0") AND (c =< "9")
          if arg0 == -1
              arg0 := c - "0"
          else
              arg0 := (arg0 * 10) + (c - "0")
          return

      if c == ";"
          state := 3
          return

      ansi(c)
      setCursorPos(pos)
      return

   3:
      if (c => "0") AND (c =< "9")
          if arg1 == -1
              arg1 := c - "0"
          else
              arg1 := (arg1 * 10) + (c - "0")
          return

      if c == ";"
          state := 4
          return

      ansi(c)
      setCursorPos(pos)
      return

   4:
      if (c => "0") AND (c =< "9")
          return

      if c == ";"
          return
      ansi(c)
      setCursorPos(pos)
      return

   5:
    state := 0
    return

  return