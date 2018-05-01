'' AnsiTerm.spin
''
'' MODIFIED BY WAYNE WARTHEN FOR ANSI COLOR CHARACTER SUPPORT
'' SPEAKER ENHANCEMENT BY MICHAEL SCHWEIKERT
''
'' based on...
''
'' VGA_1024.spin
''
'' MODIFIED BY VINCE BRIEL FOR POCKETERM FEATURES
'' MODIIFED BY JEFF LEDGER / AKA OLDBITCOLLECTOR
''

CON
  cols          = 80                  	' screen columns
  rows          = 30                  	' screen rows
  chars         = rows * cols         	' screen characters
  termRows      = 25                  	' rows in terminal area
  termChars     = termRows * cols      	' characters in terminal area
  termLastRow	= termChars - cols	' buffer pos of first char in last term row
  statArea	= termChars		' starting position of status area
  statRows	= rows - TermRows	' status area rows
  blank         = $20
  
  spkVol	= 75
  spkMaxFrq	= 1_200
  spkMinFrq	= 200
  spkBase	= 13			' Speaker pin

OBJ
  vga : "vgacolour"
  'vga : "vga8x8d"
  spk : "E555_SPKEngine"

VAR
  word  screen[chars]           	' screen character buffer
  word  tmpl[cols]              	' temporary line buffer
  byte  cursor[6]               	' cursor info array (see CursorPtr description above)
  long  sync, loc, xloc, yloc   	' sync used by VGA routine, others are local screen pointers
  byte  state                   	' Current state of state machine
  word  pos                     	' Current Position on the screen
  word  regionTop, regionBot    	' Scroll region top/bottom
  long  arg0                    	' First argument of escape sequence
  long  arg1                    	' Second argument of escape sequence
  byte  lastc                   	' Last displayed char
  long  vgaBasePin
  word	curAttr				' active attribute value
  word	bold, underscore, blink, reverse, fg, bg

  
DAT
  {
	color	ansi	rgb
	-----	----	---
	black	0	0
	red	1	4
	green	2	2
	yellow	3	6
	blue	4	1
	magenta	5	5
	cyan	6	3
	white	7	7
  }
  cmap	WORD	0,4,2,6,1,5,3,7		' Map ANSI color codes to VGA driver RGB
  
PUB start(BasePin) | i, char
  vgaBasePin := BasePin

  cursor[2] := %110			' init cursor to underscore with slow blink
  xloc := cursor[0] := 0
  yloc := cursor[1] := 0
  loc  := xloc + yloc * cols
  
  pos := 0
  regionTop := 0
  regionBot := termChars
  state := 0
  bold := 0
  underscore := 0
  blink := 0
  reverse := 0
  fg := 0
  bg := 0
  setMode(0)				' reset attributes

PUB vidOn
  if (!vga.start(vgaBasePin, @screen, @cursor, @sync))
    return false
  
PUB vidOff
  vga.stop
  
PUB speakerFrequency(newFrequency)
  result := spk.speakerFrequency(newFrequency, spkBase)

PUB speakerVolume(newVolume)
  result := spk.speakerVolume(newVolume, spkBase)

PUB beep
  spk.speakerFrequency(1000, spkBase)
  waitcnt((clkfreq >> 4) + cnt)
  spk.speakerFrequency(-1, spkBase)

PUB cls
  wordfill(@screen, (curAttr | blank), chars)

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

PUB bin(value, digits)

'' Print a binary number, specify number of digits

  repeat while digits > 32
    outc("0")
    digits--

  value <<= 32 - digits

  repeat digits
    outc((value <-= 1) & 1 + "0")


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
    outc(byte[string_ptr++])
    
PUB statInfo
  result := (statRows << 8) | cols
    
PUB statStr(row, col, attr, strVal) | nxtPos
  nxtPos := statArea + (row * cols) + col
  repeat strsize(strVal)
    screen[nxtPos++] := (attr | byte[strVal++])

PUB statFill(row, col, attr, charVal, count)
  wordfill(@screen + ((statArea + (row * cols) + col) * 2), (attr | charVal), count)
  
PRI clsTerm
  wordfill (@screen, (curAttr | blank), termChars)

PRI outc(c)

  screen[pos++] := (curAttr | c)
  lastc := c

  if pos == regionBot
    scrollUp
    pos -= cols
  elseif pos == termChars
    pos := termLastRow
    
PRI setMode(n)
  if (n == 0)
    bold := 0
    underscore := 0
    blink := 0
    reverse := 0
    fg := 7
    bg := 0
  elseif (n == 1)
    bold := 1
  elseif (n == 4)
    underscore := 1
  elseif (n == 5)
    blink := 1
  elseif (n == 7)
    reverse := 1
  
  elseif (n == 21)
    bold := 0
  elseif (n == 22)
    bold := 0
  elseif (n == 24)
    underscore := 0
  elseif (n == 25)
    blink := 0
  elseif (n == 27)
    reverse := 0
    
  elseif ((n => 30) & (n =< 37))
    fg := cmap[(n - 30)]
  elseif ((n => 40) & (n =< 47))
    bg := cmap[(n - 40)]
    
  if (reverse == 0)
    curAttr := ((fg << 8) | (bg << 12))
  else
    curAttr := ((fg << 12) | (bg << 8))

  curAttr |= (bold << 11) | (underscore << 7) | (blink << 15)
  
PRI clEOL(position) | count
  count := cols - (position // cols)
  wordfill(@screen + (position * 2), (curAttr | blank), count)

PRI clBOL(position) | count
  count := position // cols
  wordfill(@screen + ((position - count) * 2), (curAttr | blank), count)

PRI delLine(position) | src, count
  position -= position // cols

  src := position + cols

  count := termChars - src

  if count > 0
    wordmove(@screen + (position * 2), @screen + (src * 2), count)

  wordfill(@screen + (termLastRow * 2), (curAttr | blank), cols)

PRI clEOS(position)
  cleol(position)
  position += cols - (position // cols)
  repeat while position < termChars
    wordfill(@screen + (position * 2), (curAttr | blank), cols)
    pos += cols

PRI setCursorPos(position)
  cursor[0] := position // cols
  cursor[1] := position / cols

PRI insLine(position) | base, nxt
  base := position - (position // cols)
  position := termLastRow
  repeat while position > base
    nxt := position - cols
    wordmove(@screen + (position * 2), @screen + (nxt * 2), cols)
    position := nxt
  clEOL(base)

PRI insChar(position) | count
  count := (cols - (position // cols)) - 1
  wordmove(@tmpl, @screen + (position * 2), count)
  screen[position] := (curAttr | blank)
  wordmove(@screen + ((position + 1) * 2), @tmpl, count)

PRI delChar(position) | count
  count := (cols - (position // cols)) - 1
  wordmove(@screen + (position * 2), @screen + ((position + 1) * 2), count)
  screen[position + count] := (curAttr | blank)

PRI inRegion : answer
  answer := (pos => regionTop) AND (pos < regionBot)

PRI scrollUp
  delLine(regionTop)
  if regionBot < termChars
    insLine(regionBot)

PRI scrollDown
  if regionBot < termChars
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
      if (arg0 == -1)
        setMode(0)
      else
        setMode(arg0)
        if arg1 <> -1
          setMode(arg1)

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
        if pos => termChars
          pos -= cols
          return

    "C":
      repeat while arg0-- > 0
        pos += 1
        if pos => termChars
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
      if pos => termChars
        pos := termChars - 1

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
      repeat while x < termChars
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
          if regionBot < termChars
            delLine(regionBot)
          insLine(pos)

    "M":
      if inRegion
        repeat while arg0-- > 0
          delLine(pos)
          if regionBot < termChars
            insLine(regionBot)            

    "P":
      repeat while arg0--
        delChar(pos)

PUB processChar(c)
  
  case state

    0:					' Default state (no escape sequence in process)
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
          if pos => termChars
            pos -= cols
        setCursorPos(pos)
        return

      if c == 9
        pos += (8 - (pos // 8))

        if pos => termChars
         pos := termLastRow
         delLine(0)

        setCursorPos(pos)
       return

     if c == 8
       if pos > 0
         pos -= 1
       setCursorPos(pos)
      return

     if c == 7				' bel
       beep
       return

    1:					' Process char following escape
      case c
          "[":
              arg0 := arg1 := -1
              state := 2
              return

          "P":
              pos += cols
              if pos => termChars
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

   2:					' Parse first argument (arg0) of escape sequence
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

   3:					' Parse second argument (arg1) of escape sequence
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

   4:					' Parse remaining arguments (ignored)
      if (c => "0") AND (c =< "9")
          return

      if c == ";"
          return

      ansi(c)
      setCursorPos(pos)
      return

   5:					' Set character set (not implemented)
    state := 0
    return

  return