
===== INFOCOM GAMES =====

A collection of all official releases of the interactive fiction games
produced by Infocom in the 1980's. The copyright rests with Activision.

Game List follows including the revision number and release date

amfv.z4 - (A Mind Forever Voyaging) - r77-s850814.z4
arthur.z6 - (Arthur) - r74-s890714
ballyhoo.z3 - (Ballyhoo) - r97-s851218
beyond.z5 - (Beyond Zork) - r57-s871221
border.z5 - (Border Zone) - r9-s871008
bureau.z4 - (Bureaucracy) - r116-s870602
cutthr.z3 - (Cutthroats) - r23-s840809
deadline.z3 - (Deadline) - r27-s831005
enchant.z3 - (Enchanter) - r29-s860820
h2g2.z3 - (The Hitchhiker's Guide to the Galaxy) - r59-s851108
hollyw.z3 - (Hollywood Hijinx) - r37-s861215
infidel.z3 - (Infidel) - r22-s830916
journey.z6 - (Journey) - r83-s890706
leather.z3 - (Leather Goddesses of Phobos) - r59-s860730
lurking.z3 - (The Lurking Horror) - r203-s870506
moonmist.z3 - (Moonmist) - r9-s861022
nordbert.z4 - (Nord and Bert Couldn't Make Head or Tail of It) - r19-s870722
planet.z3 - (Planetfall) - r37-s851003
plunder.z3 - (Plundered Hearts) - r26-s870730
seastalk.z3 - (Seastalker) - r16-s850603
sherlock.z5 - (Sherlock) - r26-s880127
shogun.z6 - (Shogun) - r322-s890706
sorcerer.z3 - (Sorcerer) - r15-s851108
spellb.z3 - (Spellbreaker) - r87-s860904
starcros.z3 - (Starcross) - r17-s821021
stationf.z3 - (Stationfall) - r107-s870430
suspect.z3 - (Suspect) - r14-s841005
suspend.z3 - (Suspended) - r8-s840521
trinity.z4 - (Trinity) - r12-s860926
wishb.z3 - (Wishbringer) - r69-s850920
witness.z3 - (Witness) - r22-s840924
zork0.z6 - (Zork 0) - r393-s890714
zork1.z3 - (Zork 1) - r88-s840726
zork2.z3 - (Zork 2) - r48-s840904
zork3.z3 - (Zork 3) - r17-s840727

The versions above are generally from the "Classic Text Adventure
Masterpieces" released by Activision in (1996) which is the source of
most modern releases.

The version of Hitchhiker is the one that Douglas Adams postedon his web
site in the mid-90s. The BBC later posted an illustrated version based
on the same game file.

The above games have been curated from here <https://eblong.com/infocom/>.
Full game documentation can be found here <https://infodoc.plover.net/>

The game files are a virtual machine code commonly known as Z-Machine, they
are portable and will run on any machine that has a Z-Machine interpreter.

All the Z3 games come with the official CP/M interpreter (Version C) last
updated by Inforcom on 5th Feb 1985

All latter games Z4, Z5,.. and above, are more sophisticated and require
a better interpreter. i.e. VEZZA.

VEZZA

Vezza is a modern Infocom/Inform/Z-machine text adventure interpreter for
8 bit z80 based computers.  What makes it modern is that it is written in
hand-crafted z80 assembler for maximum speed, and can load not only the
classics such as Zork 1,2 and 3 but also the latter games.

It can run Z1 up to Z8 inform format interactive fiction game files. To run
a game with Vezza just type Vezza followed by the game you want to run. e.g.

`VEZZA ZORK0.Z6`

**Note:** One of the bigger constraints is available RAM. An OS such as ZPM
since it uses banked RAM does have a good amount of available RAM and was
used to test these games work.

This tool is free but the developer accepts your support by letting you
pay what you think is fair for the tool. If you find this useful consider
donating at:

https://sijnstra.itch.io/vezza

The following files are located in user area 15

Available builds (requires CP/M version 3 or compatible system):
  vezza-b.com  - 80x24 screen, vt52 + Banked CP/M 3
  vezza-FG.com - 80x30 screen, VT100/ANSI CP/M 3 (tested on Z80-MBC2 & FabGL)

Other builds (Large memory CP/M 2.2, no timed input):
  vezza-C2.com - 80x24 RunCPM VT100 - no colour
  vezza-CC.com - 80x24 RunCPM VT100 with 256 ANSI colour codes

Slow builds due to BIOS limitations (extra register presevation, less cache,
smaller memory build):
  vezza-AV.com - CP/M 2.2 with VT100 codes plus 16 bit ANSI colour & high
                 RAM. Works on Agon Light CP/M 2.2
                 Note: Issues with very high I/O such as screen animations
  vezza-AX.com - CP/M 2.2 with VT100 codes plus 16 bit ANSI colour, high
                 RAM & FabGL Italic. Works on Agon Light CP/M 2.2
                 Note: Issues with very high I/O such as screen animations
  vezza-RW.com - CP/M 2.2 with VT100 codes plus 16 bit ANSI colour with low
                 RAM. Tested on RC 2014 SC-126 using TeraTerm

You should (test and) choose one that works on you configuration, and
ideally copy and rename it as vezza.com, so the Alias COM files can find
and execute the game.

The above is a subset of available builds. The full repository is available
at https://gitlab.com/sijnstra1/vezza/



