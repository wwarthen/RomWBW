''***************************************
''*  VGA High-Res Text Driver v1.0      *
''*  Author: Chip Gracey                *
''*  Copyright (c) 2006 Parallax, Inc.  *
''*  See end of file for terms of use.  *
''***************************************
''
'' This object generates a 1024x768 VGA signal which contains 128 columns x 64
'' rows of 8x12 characters. Each row can have a unique forground/background
'' color combination and each character can be inversed. There are also two
'' cursors which can be independently controlled (ie. mouse and keyboard). A
'' sync indicator signals each time the screen is refreshed (you may ignore).
''
'' You must provide buffers for the screen, colors, cursors, and sync. Once
'' started, all interfacing is done via memory. To this object, all buffers are
'' read-only, with the exception of the sync indicator which gets written with
'' -1. You may freely write all buffers to affect screen appearance. Have fun!
''

CON

{
' 1024 x 768 @ 57Hz settings: 128 x 64 characters

  hp = 1024     'horizontal pixels
  vp = 768      'vertical pixels
  hf = 16       'horizontal front porch pixels
  hs = 96       'horizontal sync pixels
  hb = 176      'horizontal back porch pixels
  vf = 1        'vertical front porch lines
  vs = 3        'vertical sync lines
  vb = 28       'vertical back porch lines
  hn = 1        'horizontal normal sync state (0|1)
  vn = 1        'vertical normal sync state (0|1)
  pr = 60       'pixel rate in MHz at 80MHz system clock (5MHz granularity)
}
{
' 800 x 600 @ 75Hz settings: 100 x 50 characters

  hp = 800      'horizontal pixels
  vp = 600      'vertical pixels
  hf = 40       'horizontal front porch pixels
  hs = 128      'horizontal sync pixels
  hb = 88       'horizontal back porch pixels
  vf = 1        'vertical front porch lines
  vs = 4        'vertical sync lines
  vb = 23       'vertical back porch lines
  hn = 0        'horizontal normal sync state (0|1)
  vn = 0        'vertical normal sync state (0|1)
  pr = 50       'pixel rate in MHz at 80MHz system clock (5MHz granularity)
}
{
' 640 x 480 @ 69Hz settings: 80 x 40 characters

  hp = 640      'horizontal pixels
  vp = 480      'vertical pixels
  hf = 24       'horizontal front porch pixels
  hs = 40       'horizontal sync pixels
  hb = 128      'horizontal back porch pixels
  vf = 9        'vertical front porch lines
  vs = 3        'vertical sync lines
  vb = 28       'vertical back porch lines
  hn = 1        'horizontal normal sync state (0|1)
  vn = 1        'vertical normal sync state (0|1)
  pr = 30       'pixel rate in MHz at 80MHz system clock (5MHz granularity)
}
'{
' 640 x 480 @ 60Hz settings: 80 x 40 characters

  hp = 640      'horizontal pixels
  vp = 480      'vertical pixels
  hf = 16       'horizontal front porch pixels
  hs = 96       'horizontal sync pixels
  hb = 48      'horizontal back porch pixels
  vf = 10        'vertical front porch lines
  vs = 2        'vertical sync lines
  vb = 33       'vertical back porch lines
  hn = 1        'horizontal normal sync state (0|1)
  vn = 1        'vertical normal sync state (0|1)
  pr = 25       'pixel rate in MHz at 80MHz system clock (5MHz granularity)
'}

' columns and rows

  cols = hp / 8
  rows = vp / 12


VAR long cog[2]

PUB start(BasePin, ScreenPtr, ColorPtr, CursorPtr, SyncPtr) : okay | i, j

'' Start VGA driver - starts two COGs
'' returns false if two COGs not available
''
''     BasePin = VGA starting pin (0, 8, 16, 24, etc.)
''
''   ScreenPtr = Pointer to 8,192 bytes containing ASCII codes for each of the
''               128x64 screen characters. Each byte's top bit controls color
''               inversion while the lower seven bits provide the ASCII code.
''               Screen memory is arranged left-to-right, top-to-bottom.
''
''               screen byte example: %1_1000001 = inverse "A"
''
''    ColorPtr = Pointer to 64 words which define the foreground and background
''               colors for each row. The lower byte of each word contains the
''               foreground RGB data for that row, while the upper byte
''               contains the background RGB data. The RGB data in each byte is
''               arranged as %RRGGBB00 (4 levels each).
''
''               color word example: %%0020_3300 = gold on blue
''
''   CursorPtr = Pointer to 6 bytes which control the cursors:
''
''               bytes 0,1,2: X, Y, and MODE of cursor 0
''               bytes 3,4,5: X, Y, and MODE of cursor 1
''
''               X and Y are in terms of screen characters
''               (left-to-right, top-to-bottom)
''
''               MODE uses three bottom bits:
''
''                      %x00 = cursor off
''                      %x01 = cursor on
''                      %x10 = cursor on, blink slow
''                      %x11 = cursor on, blink fast
''                      %0xx = cursor is solid block
''                      %1xx = cursor is underscore
''
''               cursor example: 127, 63, %010 = blinking block in lower-right
''
''     SyncPtr = Pointer to long which gets written with -1 upon each screen
''               refresh. May be used to time writes/scrolls, so that chopiness
''               can be avoided. You must clear it each time if you want to see
''               it re-trigger.

  'if driver is already running, stop it
  stop

  'implant pin settings
  reg_vcfg := $200000FF + (BasePin & %111000) << 6
  i := $FF << (BasePin & %011000)
  j := BasePin & %100000 == 0
  reg_dira := i & j
  reg_dirb := i & !j

  'implant CNT value to sync COGs to
  sync_cnt := cnt + $10000

  'implant pointers
  longmove(@screen_base, @ScreenPtr, 3)
  font_base := @font

  'implant unique settings and launch first COG
  vf_lines.byte := vf
  vb_lines.byte := vb
  font_third := 1
  cog[1] := cognew(@d0, SyncPtr) + 1

  'allow time for first COG to launch
  waitcnt($2000 + cnt)

  'differentiate settings and launch second COG
  vf_lines.byte := vf+4
  vb_lines.byte := vb-4
  font_third := 0
  cog[0] := cognew(@d0, SyncPtr) + 1

  'if both COGs launched, return true
  if cog[0] and cog[1]
    return true

  'else, stop any launched COG and return false
  else
    stop


PUB stop | i

'' Stop VGA driver - frees two COGs

  repeat i from 0 to 1
    if cog[i]
      cogstop(cog[i]~ - 1)


CON

  #1, scanbuff[128], scancode[128*2-1+3], maincode      'enumerate COG RAM usage

  main_size = $1F0 - maincode                           'size of main program

  hv_inactive = (hn << 1 + vn) * $0101                  'H,V inactive states


DAT

'*****************************************************
'* Assembly language VGA high-resolution text driver *
'*****************************************************

' This program runs concurrently in two different COGs.
'
' Each COG's program has different values implanted for front-porch lines and
' back-porch lines which surround the vertical sync pulse lines. This allows
' timed interleaving of their active display signals during the visible portion
' of the field scan. Also, they are differentiated so that one COG displays
' even four-line groups while the other COG displays odd four-line groups.
'
' These COGs are launched in the PUB 'start' and are programmed to synchronize
' their PLL-driven video circuits so that they can alternately prepare sets of
' four scan lines and then display them. The COG-to-COG switchover is seemless
' due to two things: exact synchronization of the two video circuits and the
' fact that all COGs' driven output states get OR'd together, allowing one COG
' to output lows during its preparatory state while the other COG effectively
' drives the pins to create the visible and sync portions of its scan lines.
' During non-visible scan lines, both COGs output together in unison.
'
' COG RAM usage:  $000      = d0 - used to inc destination fields for indirection
'                 $001-$080 = scanbuff - longs which hold 4 scan lines
'                 $081-$182 = scancode - stacked WAITVID/SHR for fast display
'                 $183-$1EF = maincode - main program loop which drives display

                        org                             'set origin to $000 for start of program

d0                      long    1 << 9                  'd0 always resides here at $000, executes as NOP


' Initialization code and data - after execution, space gets reused as scanbuff

                        'Move main program into maincode area

:move                   mov     $1EF,main_begin+main_size-1
                        sub     :move,d0s0              '(do reverse move to avoid overwrite)
                        djnz    main_ctr,#:move

                        'Build scanbuff display routine into scancode

:waitvid                mov     scancode+0,i0           'org     scancode
:shr                    mov     scancode+1,i1           'waitvid color,scanbuff+0
                        add     :waitvid,d1             'shr     scanbuff+0,#8
                        add     :shr,d1                 'waitvid color,scanbuff+1
                        add     i0,#1                   'shr     scanbuff+1,#8
                        add     i1,d0                   '...
                        djnz    scan_ctr,#:waitvid      'waitvid color,scanbuff+cols-1

                        mov     scancode+cols*2-1,i2    'mov     vscl,#hf
                        mov     scancode+cols*2+0,i3    'waitvid hvsync,#0
                        mov     scancode+cols*2+1,i4    'jmp     #scanret

                        'Init I/O registers and sync COGs' video circuits

                        mov     dira,reg_dira           'set pin directions
                        mov     dirb,reg_dirb
                        movi    frqa,#(pr / 5) << 2     'set pixel rate
                        mov     vcfg,reg_vcfg           'set video configuration
                        mov     vscl,#1                 'set video to reload on every pixel
                        waitcnt sync_cnt,colormask      'wait for start value in cnt, add ~1ms
                        movi    ctra,#%00001_110        'COGs in sync! enable PLLs now - NCOs locked!
                        waitcnt sync_cnt,#0             'wait ~1ms for PLLs to stabilize - PLLs locked!
                        mov     vscl,#100               'insure initial WAITVIDs lock cleanly

                        'Jump to main loop

                        jmp     #vsync                  'jump to vsync - WAITVIDs will now be locked!

                        'Data

d0s0                    long    1 << 9 + 1
d1                      long    1 << 10
main_ctr                long    main_size
scan_ctr                long    cols

i0                      waitvid x,scanbuff+0
i1                      shr     scanbuff+0,#8
i2                      mov     vscl,#hf
i3                      waitvid hvsync,#0
i4                      jmp     #scanret

reg_dira                long    0                       'set at runtime
reg_dirb                long    0                       'set at runtime
reg_vcfg                long    0                       'set at runtime
sync_cnt                long    0                       'set at runtime

                        'Directives

                        fit     scancode                'make sure initialization code and data fit
main_begin              org     maincode                'main code follows (gets moved into maincode)


' Main loop, display field - each COG alternately builds and displays four scan lines

vsync                   mov     x,#vs                   'do vertical sync lines
                        call    #blank_vsync

vb_lines                mov     x,#vb                   'do vertical back porch lines (# set at runtime)
                        call    #blank_vsync

                        mov     screen_ptr,screen_base  'reset screen pointer to upper-left character
                        mov     color_ptr,color_base    'reset color pointer to first row
                        mov     row,#0                  'reset row counter for cursor insertion
                        mov     fours,#rows * 3 / 2     'set number of 4-line builds for whole screen

                        'Build four scan lines into scanbuff

fourline                mov     font_ptr,font_third     'get address of appropriate font section
                        shl     font_ptr,#7+2
                        add     font_ptr,font_base

                        movd    :pixa,#scanbuff-1       'reset scanbuff address (pre-decremented)
                        movd    :pixb,#scanbuff-1

                        mov     y,#2                    'must build scanbuff in two sections because
                        mov     vscl,vscl_line2x        '..pixel counter is limited to twelve bits

:halfrow                waitvid underscore,#0           'output lows to let other COG drive VGA pins
                        mov     x,#cols/2               '..for 2 scan lines, ready for half a row

:column                 rdbyte  z,screen_ptr            'get character from screen memory
                        ror     z,#7                    'get inverse flag into bit 0, keep chr high
                        shr     z,#32-7-2       wc      'get inverse flag into c, chr into bits 8..2
                        add     z,font_ptr              'add font section address to point to 8*4 pixels
                        add     :pixa,d0                'increment scanbuff destination addresses
                        add     :pixb,d0
                        add     screen_ptr,#1           'increment screen memory address
:pixa                   rdlong  scanbuff,z              'read pixel long (8*4) into scanbuff
:pixb   if_nc           xor     scanbuff,longmask       'invert pixels according to inverse flag
                        djnz    x,#:column              'another character in this half-row?

                        djnz    y,#:halfrow             'loop to do 2nd half-row, time for 2nd WAITVID

                        sub     screen_ptr,#cols        'back up to start of same row in screen memory

                        'Insert cursors into scanbuff

                        mov     z,#2                    'ready for two cursors

:cursor                 rdbyte  x,cursor_base           'x in range?
                        add     cursor_base,#1
                        cmp     x,#cols         wc

                        rdbyte  y,cursor_base           'y match?
                        add     cursor_base,#1
                        cmp     y,row           wz

                        rdbyte  y,cursor_base           'get cursor mode
                        add     cursor_base,#1

        if_nc_or_nz     jmp     #:nocursor              'if cursor not in scanbuff, no cursor

                        add     x,#scanbuff             'cursor in scanbuff, set scanbuff address
                        movd    :xor,x

                        test    y,#%010         wc      'get mode bits into flags
                        test    y,#%001         wz
        if_nc_and_z     jmp     #:nocursor              'if cursor disabled, no cursor

        if_c_and_z      test    slowbit,cnt     wc      'if blink mode, get blink state
        if_c_and_nz     test    fastbit,cnt     wc

                        test    y,#%100         wz      'get box or underscore cursor piece
        if_z            mov     x,longmask
        if_nz           mov     x,underscore
        if_nz           cmp     font_third,#2   wz      'if underscore, must be last font section

:xor    if_nc_and_z     xor     scanbuff,x              'conditionally xor cursor into scanbuff

:nocursor               djnz    z,#:cursor              'second cursor?

                        sub     cursor_base,#3*2        'restore cursor base

                        'Display four scan lines from scanbuff

                        rdword  x,color_ptr             'get color pattern for current row
                        and     x,colormask             'mask away hsync and vsync signal states
                        or      x,hv                    'insert inactive hsync and vsync states

                        mov     y,#4                    'ready for four scan lines

scanline                mov     vscl,vscl_chr           'set pixel rate for characters
                        jmp     #scancode               'jump to scanbuff display routine in scancode
scanret                 mov     vscl,#hs                'do horizontal sync pixels
                        waitvid hvsync,#1               '#1 makes hsync active
                        mov     vscl,#hb                'do horizontal back porch pixels
                        waitvid hvsync,#0               '#0 makes hsync inactive
                        shr     scanbuff+cols-1,#8      'shift last column's pixels right by 8
                        djnz    y,#scanline             'another scan line?

                        'Next group of four scan lines

                        add     font_third,#2           'if font_third + 2 => 3, subtract 3 (new row)
                        cmpsub  font_third,#3   wc      'c=0 for same row, c=1 for new row
        if_c            add     screen_ptr,#cols        'if new row, advance screen pointer
        if_c            add     color_ptr,#2            'if new row, advance color pointer
        if_c            add     row,#1                  'if new row, increment row counter
                        djnz    fours,#fourline         'another 4-line build/display?

                        'Visible section done, do vertical sync front porch lines

                        wrlong  longmask,par            'write -1 to refresh indicator

vf_lines                mov     x,#vf                   'do vertical front porch lines (# set at runtime)
                        call    #blank

                        jmp     #vsync                  'new field, loop to vsync

                        'Subroutine - do blank lines

blank_vsync             xor     hvsync,#$101            'flip vertical sync bits

blank                   mov     vscl,hx                 'do blank pixels
                        waitvid hvsync,#0
                        mov     vscl,#hf                'do horizontal front porch pixels
                        waitvid hvsync,#0
                        mov     vscl,#hs                'do horizontal sync pixels
                        waitvid hvsync,#1
                        mov     vscl,#hb                'do horizontal back porch pixels
                        waitvid hvsync,#0
                        djnz    x,#blank                'another line?
blank_ret
blank_vsync_ret         ret

                        'Data

screen_base             long    0                       'set at runtime (3 contiguous longs)
color_base              long    0                       'set at runtime
cursor_base             long    0                       'set at runtime

font_base               long    0                       'set at runtime
font_third              long    0                       'set at runtime

hx                      long    hp                      'visible pixels per scan line
vscl_line2x             long    (hp + hf + hs + hb) * 2 'total number of pixels per 2 scan lines
vscl_chr                long    1 << 12 + 8             '1 clock per pixel and 8 pixels per set
colormask               long    $FCFC                   'mask to isolate R,G,B bits from H,V
longmask                long    $FFFFFFFF               'all bits set
slowbit                 long    1 << 25                 'cnt mask for slow cursor blink
fastbit                 long    1 << 24                 'cnt mask for fast cursor blink
underscore              long    $FFFF0000               'underscore cursor pattern
hv                      long    hv_inactive             '-H,-V states
hvsync                  long    hv_inactive ^ $200      '+/-H,-V states

                        'Uninitialized data

screen_ptr              res     1
color_ptr               res     1
font_ptr                res     1

x                       res     1
y                       res     1
z                       res     1

row                     res     1
fours                   res     1


' 8 x 12 font - characters 0..127
'
' Each long holds four scan lines of a single character. The longs are arranged into
' groups of 128 which represent all characters (0..127). There are three groups which
' each contain a vertical third of all characters. They are ordered top, middle, and
' bottom.

font  long

long  $0C080000,$30100000,$7E3C1800,$18181800,$81423C00,$99423C00,$8181FF00,$E7C3FF00  'top
long  $1E0E0602,$1C000000,$00000000,$00000000,$18181818,$18181818,$00000000,$18181818
long  $00000000,$18181818,$18181818,$18181818,$18181818,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$0F0F0F0F,$00000000,$00000000,$00000000
long  $00000000,$3C3C1800,$77666600,$7F363600,$667C1818,$46000000,$1B1B0E00,$1C181800
long  $0C183000,$180C0600,$66000000,$18000000,$00000000,$00000000,$00000000,$60400000
long  $73633E00,$1E181000,$66663C00,$60663C00,$3C383000,$06067E00,$060C3800,$63637F00
long  $66663C00,$66663C00,$1C000000,$00000000,$18306000,$00000000,$180C0600,$60663C00
long  $63673E00,$66663C00,$66663F00,$63663C00,$66361F00,$06467F00,$06467F00,$63663C00
long  $63636300,$18183C00,$30307800,$36666700,$06060F00,$7F776300,$67636300,$63361C00
long  $66663F00,$63361C00,$66663F00,$66663C00,$185A7E00,$66666600,$66666600,$63636300
long  $66666600,$66666600,$31637F00,$0C0C3C00,$03010000,$30303C00,$361C0800,$00000000
long  $0C000000,$00000000,$06060700,$00000000,$30303800,$00000000,$0C6C3800,$00000000
long  $06060700,$00181800,$00606000,$06060700,$18181E00,$00000000,$00000000,$00000000
long  $00000000,$00000000,$00000000,$00000000,$0C080000,$00000000,$00000000,$00000000
long  $00000000,$00000000,$00000000,$18187000,$18181800,$18180E00,$73DBCE00,$18180000

long  $080C7E7E,$10307E7E,$18181818,$7E181818,$81818181,$99BDBDBD,$81818181,$E7BD99BD  'middle
long  $1E3E7E3E,$1C3E3E3E,$30F0C000,$0C0F0300,$00C0F030,$00030F0C,$00FFFF00,$18181818
long  $18FFFF00,$00FFFF18,$18F8F818,$181F1F18,$18FFFF18,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$FFFF0F0F,$F0F00F0F,$0F0F0F0F,$00000F0F,$FFFF0000,$F0F00000,$0F0F0000
long  $00000000,$0018183C,$00000033,$7F363636,$66603C06,$0C183066,$337B5B0E,$0000000C
long  $0C060606,$18303030,$663CFF3C,$18187E18,$00000000,$00007E00,$00000000,$060C1830
long  $676F6B7B,$18181818,$0C183060,$60603860,$307F3336,$60603E06,$66663E06,$0C183060
long  $66763C6E,$60607C66,$1C00001C,$00001C1C,$180C060C,$007E007E,$18306030,$00181830
long  $033B7B7B,$66667E66,$66663E66,$63030303,$66666666,$06263E26,$06263E26,$63730303
long  $63637F63,$18181818,$33333030,$36361E36,$66460606,$63636B7F,$737B7F6F,$63636363
long  $06063E66,$7B636363,$66363E66,$66301C06,$18181818,$66666666,$66666666,$366B6B63
long  $663C183C,$18183C66,$43060C18,$0C0C0C0C,$30180C06,$30303030,$00000063,$00000000
long  $0030381C,$333E301E,$6666663E,$0606663C,$3333333E,$067E663C,$0C0C3E0C,$3333336E
long  $66666E36,$1818181C,$60606070,$361E3666,$18181818,$6B6B6B3F,$6666663E,$6666663C
long  $6666663B,$3333336E,$066E7637,$300C663C,$0C0C0C7E,$33333333,$66666666,$6B6B6363
long  $1C1C3663,$66666666,$0C30627E,$180C060C,$18181818,$18306030,$00000000,$0018187E

long  $00000000,$00000000,$00001818,$0000183C,$00003C42,$00003C42,$0000FF81,$0000FFC3  'bottom
long  $0002060E,$00000000,$18181818,$18181818,$00000000,$00000000,$00000000,$18181818
long  $18181818,$00000000,$18181818,$18181818,$18181818,$00FFFF00,$CC993366,$66666666
long  $AA55AA55,$FFFFFFFF,$F0F0F0F0,$0F0F0F0F,$00000000,$FFFFFFFF,$F0F0F0F0,$0F0F0F0F
long  $00000000,$00001818,$00000000,$00003636,$0018183E,$00006266,$00006E3B,$00000000
long  $00003018,$0000060C,$00000000,$00000000,$0C181C1C,$00000000,$00001C1C,$00000103
long  $00003E63,$00007E18,$00007E66,$00003C66,$00007830,$00003C66,$00003C66,$00000C0C
long  $00003C66,$00001C30,$0000001C,$0C181C1C,$00006030,$00000000,$0000060C,$00001818
long  $00003E07,$00006666,$00003F66,$00003C66,$00001F36,$00007F46,$00000F06,$00007C66
long  $00006363,$00003C18,$00001E33,$00006766,$00007F66,$00006363,$00006363,$00001C36
long  $00000F06,$00603C36,$00006766,$00003C66,$00003C18,$00003C66,$0000183C,$00003636
long  $00006666,$00003C18,$00007F63,$00003C0C,$00004060,$00003C30,$00000000,$FFFF0000
long  $00000000,$00006E33,$00003B66,$00003C66,$00006E33,$00003C66,$00001E0C,$1E33303E
long  $00006766,$00007E18,$3C666660,$00006766,$00007E18,$00006B6B,$00006666,$00003C66
long  $0F063E66,$78303E33,$00000F06,$00003C66,$0000386C,$00006E33,$0000183C,$00003636
long  $00006336,$1C30607C,$00007E46,$00007018,$00001818,$00000E18,$00000000,$0000007E



{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}