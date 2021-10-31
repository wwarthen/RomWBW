
; -----------------------------------------------------------------------------
; Copyright 2018 Dimitri Theulings
;
; This file is part of Tasty Basic.
;
; Tasty Basic is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Tasty Basic is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Tasty Basic.  If not, see <https://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------
; Tasty Basic is derived from earlier works by Li-Chen Wang, Peter Rauskolb,
; and Doug Gabbard. Refer to the source code repository for details
; <https://github.com/dimitrit/tastybasic/>.
; -----------------------------------------------------------------------------

#define dwa(addr) 		.db (addr >> 8) + 080h\ .db addr & 0ffh

ctrlc				.equ 03h
bs				.equ 08h
lf				.equ 0ah
cr				.equ 0dh
ctrlo				.equ 0fh
ctrlu				.equ 15h

#ifdef CPM
#define PLATFORM "CP/M"
TBC_LOC				.equ 0100h
#endif

#ifdef ROMWBW
#define PLATFORM "ROMWBW"
TBC_LOC				.equ 0a00h
#endif

#ifndef PLATFORM
TBC_LOC				.equ 0
#endif

				.org TBC_LOC
start:
				ld sp,stack				; ** Cold Start **
				ld a,0ffh
				jp init
testc:
				ex (sp),hl				; ** TestC **
				call skipspace				; ignore spaces
				cp (hl)					; test character
				inc hl					; compare the byte that follows the
				jr z,tc1				; call instruction with the text pointer
				push bc
				ld c,(hl)				; if not equal, ad the seond byte
				ld b, 0h				; that follows the call to the old pc
				add hl,bc
				pop bc
				dec de
tc1:
				inc de					; if equal, skip those bytes
				inc hl					; and continue
				ex (sp),hl
				ret

skipspace:
				ld a,(de)				; ** SkipSpace **
				cp ' '					; ignore spaces
				ret nz					; in text (where de points)
				inc de					; and return the first non-blank
				jp skipspace				; character in A

expr:
				call expr2				; ** Expr **
				push hl					; evaluate expression
				jp expr1

comp:
				ld a,h					; ** Compare **
				cp d					; compare hl with de
				ret nz					; return c and z flags
				ld a,l					; old a is lost
				cp e
				ret

finish:
				pop af					; ** Finish **
				call fin				; check end of command
				jp qwhat

;*************************************************************
;
; ** REM ** IF ** INPUT ** & LET (& DEFLT) ** DATA ** READ **
;
; 'REM' CAN BE FOLLOWED BY ANYTHING AND IS IGNORED BY TBI.
; TBI TREATS IT LIKE AN 'IF' WITH A FALSE CONDITION.
;
; 'IF' IS FOLLOWED BY AN EXPR. AS A CONDITION AND ONE OR MORE
; COMMANDS (INCLUDING OTHER 'IF'S) SEPERATED BY SEMI-COLONS.
; NOTE THAT THE WORD 'THEN' IS NOT USED.  TBI EVALUATES THE
; EXPR. IF IT IS NON-ZERO, EXECUTION CONTINUES.  IF THE
; EXPR. IS ZERO, THE COMMANDS THAT FOLLOWS ARE IGNORED AND
; EXECUTION CONTINUES AT THE NEXT LINE.
;
; 'INPUT' COMMAND IS LIKE THE 'PRINT' COMMAND, AND IS FOLLOWED
; BY A LIST OF ITEMS.  IF THE ITEM IS A STRING IN SINGLE OR
; DOUBLE QUOTES, OR IS A BACK-ARROW, IT HAS THE SAME EFFECT AS
; IN 'PRINT'.  IF AN ITEM IS A VARIABLE, THIS VARIABLE NAME IS
; PRINTED OUT FOLLOWED BY A COLON.  THEN TBI WAITS FOR AN
; EXPR. TO BE TYPED IN.  THE VARIABLE IS THEN SET TO THE
; VALUE OF THIS EXPR.  IF THE VARIABLE IS PROCEDED BY A STRING
; (AGAIN IN SINGLE OR DOUBLE QUOTES), THE STRING WILL BE
; PRINTED FOLLOWED BY A COLON.  TBI THEN WAITS FOR INPUT EXPR.
; AND SET THE VARIABLE TO THE VALUE OF THE EXPR.
;
; IF THE INPUT EXPR. IS INVALID, TBI WILL PRINT "WHAT?",
; "HOW?" OR "SORRY" AND REPRINT THE PROMPT AND REDO THE INPUT.
; THE EXECUTION WILL NOT TERMINATE UNLESS YOU TYPE CONTROL-C.
; THIS IS HANDLED IN 'INPERR'.
;
; 'LET' IS FOLLOWED BY A LIST OF ITEMS SEPERATED BY COMMAS.
; EACH ITEM CONSISTS OF A VARIABLE, AN EQUAL SIGN, AND AN EXPR.
; TBI EVALUATES THE EXPR. AND SET THE VARIABLE TO THAT VALUE.
; TBI WILL ALSO HANDLE 'LET' COMMAND WITHOUT THE WORD 'LET'.
; THIS IS DONE BY 'DEFLT'.
;
; 'DATA' ALLOWS CONSTANT VALUES TO BE STORED IN CODE. TREATED
; AS A REMARK ('REM') WHEN PROGRAM IS EXECUTED.
;
; 'READ' ASSIGNS THE NEXT AVAILABLE DATA VALUE TO A VARIABLE.
;*************************************************************
rem:
data:
				ld hl,0					; ** Rem ** Data **
				jr if1					; this is like 'IF 0'
iff:
				call expr				; ** If **
if1:
				ld a,h					; is the expr = 0?
				or l
				jp nz,runsml				; no, continue
				call findskip				; yes, skip rest of line
				jp nc,runtsl				; and run the next line
				jp rstart				; if no, restart
inputerror:
				ld hl,(stkinp)				; ** InputError **
				ld sp,hl				; restore old sp and old current
				pop hl
				ld (current),hl
				pop de					; and old text pointer
				pop de					; redo current
input:
				push de					; ** Input **
				call qtstg				; is next item a string?
				jp ip2					; no
				call testvar				; yes and followed by a variable?
				jp c,ip4				; no
				jp ip3					; yes, input variable
ip2:
				push de					; save for printstr
				call testvar				; must be variable
				jp c,qwhat				; no, what?
				ld a,(de)				; prepare for printstr
				ld c,a
				sub a
				ld (de),a
				pop de
				call printstr				; print string as prompt
				ld a,c					; restore text
				dec de
				ld (de),a
ip3:
				push de					; save text pointer
				ex de,hl
				ld hl,(current)				; also save current
				push hl
				ld hl,input
				ld (current),hl
				ld hl,0
				add hl,sp
				ld (stkinp),hl
				push de
				ld a,':'
				call getline
				ld de,buffer
				call expr
				nop
				nop
				nop
				pop de
				ex de,hl
				ld (hl),e
				inc hl
				ld (hl),d
				pop hl
				ld (current),hl
				pop de
ip4:
				pop af					; purge stack
				call testc				; is next character ','?
				.db ','
				.db ip5-$-1
				jr input				; yes, more items
ip5:
				call finish
deflt:
				ld a,(de)				; ** DEFLT **
				cp cr					; empty line is fine
				jr z,lt1				; else it's 'LET'
let:
				call setval				; ** Let **
				call testc				; set value to var
				.db ','
				.db lt1-$-1
				jr let					; item by item
lt1:
				call finish
restore:			call rstreadptr
				call finish
rstreadptr:
				ld hl,0
				ld (readptr),hl
				ret
read:
				push de					; ** Read **
				ld hl,(readptr)				; has read pointer been initialised?
				ld a,h
				or a
				jr nz,rd2				; yes, find next data value
				call findline				; no, find first line
				jr nc,rd1				; found first line
				pop de					; nothing found, so how?
				jp qhow
rd1:
				call finddata
				jr rd4
rd2:
				ex de,hl
				call skipspace				; skip over spaces
				call testc				; have we hit a comma?
				.db ','
				.db rd3-$-1				
				jr rd5
rd3:
				call nextdata
rd4:
				jr z,rd5				; found a data statement
				pop de
				jp qhow					; nothing found, so how to read?
				
rd5:				
				ld (readptr),de				; update read pointer
				pop de
				call testvar				
				jp c,qwhat				; no variable
				push hl					; save address of variable
				push de					; and text pointer
				ld de,(readptr)				; point to next data value
				call parsenum				; parse the constant
				jr nc, rd6
				pop de					; spmething bad happened when
				jp qhow					; parsing the number
rd6:
				ld (readptr),de				; update read pointer
				pop de					; and restore text pointer
				ld b,h					; move value to bc
				ld c,l
				pop hl					; get address of variable
				ld (hl),c				; assign value
				inc hl
				ld (hl),b
				
				call testc				; do we have more variables?
				.db ','
				.db rd7-$-1
				jr read					; yes, read next
rd7:
				call finish				; all done
finddata:
				inc de					; skip over line no.
				inc de
				call skipspace
				ld hl,datastmt
				ld b,4
fd1:
				ld a,(de)				
				cp (hl)
				jp nz,nextdata				; not what we're looking for
				dec b					; are we done comparing
				jr z,fd2				; yes
				inc de
				inc hl
				jr fd1
fd2:
				inc de                                  ; first char past statement
				ret					; nc,z:found; nc,nz:no

nextdata:
				ld hl,0
				call findskip				; find the next line
				jr nc,finddata				; and try there
				or 1					; no more lines
				ret					; nc,nz: not found!

;*************************************************************
;
; *** PEEK *** POKE *** IN *** & OUT ***
;
; 'PEEK(<EXPR>)' RETURNS THE VALUE OF THE BYTE AT THE GIVEN
; ADDRESS.
; 'POKE <expr1>,<expr2>' SETS BYTE AT ADDRESS <expr1> TO
; VALUE <expr2>
; 'IN(<EXPR)' READS THE GIVEN PORT.
; 'OUT <expr1>,<expr2>' WRITES VALUE <expr2> TO PORT <expr1>.
;
;*************************************************************
peek:
				call parn				; ** Peek(expr) **
				ld a,h					; expression must be positive
				or a
				jp m,qhow
				ld a,(hl)				; peek address
				ld h,0
				ld l,a
				ret
inp:
				call parn				; ** In(expr) **
				ld a,0					; is port > 255?
				cp h
				jp nz,qhow				; yes, so not a valid port
				ld c,l
				in l,(c)				; read port
				ld h,0
				ret
poke:
				call expr				; ** Poke **
				ld a,h					; address must be positive
				or a
				jp m,qhow
				push hl
				call testc				; is next char a comma?
				.db ','
				.db ot1-$-1				; what, no?
				call expr				; get value to store
				ld a,0					; is it > 255?
				cp h
				jp z,pk1				; no, all good
				pop hl
				jp qhow
pk1:
				ld a,l					; save value
				pop hl
				ld (hl),a
				call finish
outp:
				call expr				; ** Out **
				ld a,0					; is port > 255?
				cp h
				jp nz,qhow				; yes, so not a valid port
				push hl
				call testc				; is next char a comma?
				.db ','
				.db ot1-$-1				; what, no?
				call expr				; get value to write
				ld a,0					; is it > 255?
				cp h
				jp z,ot2				; no, all good
				pop hl
				jp qhow
ot2:
				ld a,l					; output value
				pop hl
				ld c,l
				out (c),a
				call finish
ot1:
				pop hl
				jp qwhat
usrexec:
				call parn				; ** Usr(expr) **
				push de
				ex de,hl
				ld hl,ue1
				push hl
				ld ix,(usrptr)
				jp (ix)
ue1:
				ex de,hl
				pop de
				ret
;*************************************************************
;
; *** EXPR ***
;
; 'EXPR' EVALUATES ARITHMETICAL OR LOGICAL EXPRESSIONS.
; <EXPR>::<EXPR2>
;			<EXPR2><REL.OP.><EXPR2>
; WHERE <REL.OP.> IS ONE OF THE OPERATORS IN TAB8 AND THE
; RESULT OF THESE OPERATIONS IS 1 IF TRUE AND 0 IF FALSE.
; <EXPR2>::=(+ OR -)<EXPR3>(+ OR -<EXPR3>)(....)
; WHERE () ARE OPTIONAL AND (....) ARE OPTIONAL REPEATS.
; <EXPR3>::=<EXPR4>(* OR /><EXPR4>)(....)
; <EXPR4>::=<VARIABLE>
;			<FUNCTION>
;			(<EXPR>)
; <EXPR> IS RECURSIVE SO THAT VARIABLE '@' CAN HAVE AN <EXPR>
; AS INDEX, FUNCTIONS CAN HAVE AN <EXPR> AS ARGUMENTS, AND
; <EXPR4> CAN BE AN <EXPR> IN PARANTHESE.
;*************************************************************

expr1:
				ld hl,tab8-1				; look up rel.op
				jp exec					; go do it
xp11:
				call xp18				; rel.op.'>='
				ret c					; no, return hl=0
				ld l,a					; yes, return hl=1
				ret
xp12:
				call xp18				; rel.op.'#'
				ret z					; no, return hl=0
				ld l,a					; yes, return hl=1
				ret
xp13:
				call xp18				; rel.op.'>'
				ret z					; no
				ret c					; also, no
				ld l,a					; yes, return hl=1
				ret
xp14:
				call xp18				; rel.op.'<='
				ld l,a					; set hl=1
				ret z					; yes, return hl=1
				ret c
				ld l,h					; else set hl=0
				ret
xp15:
				call xp18				; rel.op.'='
				ret nz					; no, return hl=0
				ld l,a					; else hl=1
				ret
xp16:
				call xp18				; rel.op.'<'
				ret nc					; no, return hl=0
				ld l,a					; else hl=1
				ret
xp17:
				pop hl					; not rel.op
				ret					; return hl=<expr2>
xp18:
				ld a,c					; routine for all rel.ops
				pop hl
				pop bc
				push hl
				push bc					; reverse top of stack
				ld c,a
				call expr2				; get second <expr2>
				ex de,hl				; value now in de
				ex (sp),hl				; first <expr2> in hl
				call ckhlde				; compare them
				pop de					; restore text pointer
				ld hl,0					; set hl=0, a=1
				ld a,1
				ret
expr2:
				call testc				; is it minus sign?
				.db '-'
				.db xp21-$-1
				ld hl,0					; yes, fake 0 -
				jr xp26					; treat like subtract
xp21:
				call testc				; is it plus sign?
				.db '+'
				.db xp22-$-1
xp22:
				call expr3				; first <expr3>
xp23:
				call testc				; addition?
				.db '+'
				.db xp25-$-1
				push hl					; yes, save value
				call expr3				; get second <expr3>
xp24:
				ex de,hl				; 2nd in de
				ex (sp),hl				; 1st in hl
				ld a,h					; compare sign
				xor d
				ld a,d
				add hl,de
				pop de					; restore text pointer
				jp m,xp23				; first and second sign differ
				xor h					; first and second sign are equal
				jp p,xp23				; so is the result
				jp qhow					; else we have overflow
xp25:
				call testc				; subtract?
				.db '-'
				.db xp42-$-1
xp26:
				push hl					; yes, save first <expr3>
				call expr3				; get second <expr3>
				call changesign				; negate
				jr xp24					; and add them
expr3:
				call expr4				; get first expr4
xp31:
				call testc				; multiply?
				.db '*'
				.db xp34-$-1
				push hl					; yes, save first and get second
				call expr4				; <expr4>
				ld b,0					; clear b for sign
				call checksign
				ex (sp),hl				; first in hl
				call checksign				; check sign of first
				ex de,hl
				ex (sp),hl
				ld a,h					; is hl > 255?
				or a
				jr z,xp32				; no
				ld a,d					; yes, what about de
				or d
				ex de,hl
				jp nz,ahow
xp32:
				ld a,l
				ld hl,0
				or a
				jr z,xp35
xp33:
				add hl,de
				jp c,ahow
				dec a
				jr nz,xp33
				jr xp35
xp34:
				call testc				; divide
				.db '/'
				.db xp42-$-1
				push hl					; yes, save first <expr4>
				call expr4				; and get the second one
				ld b,0h					; clear b for sign
				call checksign				; check sign of the second
				ex (sp),hl				; get the first in hl
				call checksign				; check sign of first
				ex de,hl
				ex (sp),hl
				ex de,hl
				ld a,d					; divide by 0?
				or e
				jp z,ahow				; err...how?
				push bc					; else save sign
				call divide
				ld h,b
				ld l,c
				pop bc					; retrieve sign
xp35:
				pop de					; and text pointer
				ld a,h					; hl must be positive
				or a
				jp m,qhow				; else it's overflow
				ld a,b
				or a
				call m,changesign			; change sign if needed
				jp xp31					; look for more terms
expr4:
				ld hl,tab4-1				; find function in tab4
				jp exec					; and execute it
xp40:
				call testvar
				jr c,xp41				; nor a variable
				ld a,(hl)
				inc hl
				ld h,(hl)				; value in hl
				ld l,a
				ret
xp41:
				call testnum				; or is it a number
				ld a,b					; number of digits
				or a
				ret nz					; ok

parn:
				call testc
				.db '('
				.db xp43-$-1
				call expr				; "(expr)"
				call testc
				.db ')'
				.db xp43-$-1
xp42:
				ret
xp43:
				jp qwhat				; what?
rnd:
				call parn				; ** Rnd(expr) **
				ld a,h					; expression must be positive
				or a
				jp m,qhow
				or l					; and non-zero
				jp z,qhow
				push de					; save de and hl
				push hl
				ld hl,(rndptr)				; get memory as random number
				ld de,LST_ROM
				call comp
				jr c,ra1				; wrap around if last
				ld hl,start
ra1:
				ld e,(hl)
				inc hl
				ld d,(hl)
				ld (rndptr),hl
				pop hl
				ex de,hl
				push bc
				call divide				; rnd(n)=mod(m,n)+1
				pop bc
				pop de
				inc hl
				ret
abs:
				call parn				; ** Abs (expr) **
				dec de
				call checksign
				inc de
				ret
size:
				ld hl,(textunfilled)			; ** Size **
				push de					; get the number of free bytes between
				ex de,hl				; and varbegin
				ld hl,varbegin
				call subde
				pop de
				ret
clrvars:
				ld hl,(textunfilled)			; ** ClearVars**
				push de					; get the number of bytes available
				ex de,hl				; for variable storge
				ld hl,varend
				call subde
				ld b,h					; and save in bc
				ld c,l
				ld hl,(textunfilled)			; clear the first byte
				ld d,h
				ld e,l
				inc de
				ld (hl),0h
				ldir					; and repeat for all the others
				pop de
				ret

;*************************************************************
;
; *** DIVIDE *** SUBDE *** CHKSGN *** CHGSGN *** & CKHLDE ***
;
; 'DIVIDE' DIVIDES HL BY DE, RESULT IN BC, REMAINDER IN HL
;
; 'SUBDE' SUBSTRACTS DE FROM HL
;
; 'CHKSGN' CHECKS SIGN OF HL.  IF +, NO CHANGE.  IF -, CHANGE
; SIGN AND FLIP SIGN OF B.
;
; 'CHGSGN' CHECKS SIGN N OF HL AND B UNCONDITIONALLY.
;
; 'CKHLDE' CHECKS SIGN OF HL AND DE.  IF DIFFERENT, HL AND DE
; ARE INTERCHANGED.  IF SAME SIGN, NOT INTERCHANGED.  EITHER
; CASE, HL DE ARE THEN COMPARED TO SET THE FLAGS.
;*************************************************************
divide:
				push hl					; ** Divide **
				ld l,h					; divide h by de
				ld h,0h
				call dv1
				ld b,c					; save result in b
				ld a,l					; (remainder + l) / de
				pop hl
				ld h,a
dv1:
				ld c,0ffh				; result in c
dv2:
				inc c					; dumb routine
				call subde				; divide using subtract and count
				jr nc,dv2
				add hl,de
				ret
subde:
				ld a,l					; ** subde **
				sub e					; subtract de from hl
				ld l,a
				ld a,h
				sbc a,d
				ld h,a
				ret

checksign:
				ld a,h					; ** CheckSign **
				or a					; check sign of hl
				ret p
changesign:
				ld a,h					; ** ChangeSign **
				or l					; check if hl is zero
				jp nz,cs1				; no, try to change sign
				ret					; yes, return
cs1:
				ld a,h					; change sign of hl
				push af
				cpl
				ld h,a
				ld a,l
				cpl
				ld l,a
				inc hl
				pop af
				xor h
				jp p,qhow
				ld a,b					; and also flip b
				xor 80h
				ld b,a
				ret
ckhlde:
				ld a,h					; same sign?
				xor d					; yes, compare
				jp p,ck1				; no, exchange and compare
				ex de,hl
ck1:
				call comp
				ret

;*************************************************************
;
; *** SETVAL *** FIN *** ENDCHK *** & ERROR (& FRIENDS) ***
;
; "SETVAL" EXPECTS A VARIABLE, FOLLOWED BY AN EQUAL SIGN AND
; THEN AN EXPR.  IT EVALUATES THE EXPR. AND SET THE VARIABLE
; TO THAT VALUE.
;
; "FIN" CHECKS THE END OF A COMMAND.  IF IT ENDED WITH ":",
; EXECUTION CONTINUES.  IF IT ENDED WITH A CR, IT FINDS THE
; NEXT LINE AND CONTINUE FROM THERE.
;
; "ENDCHK" CHECKS IF A COMMAND IS ENDED WITH CR.  THIS IS
; REQUIRED IN CERTAIN COMMANDS.  (GOTO, RETURN, AND STOP ETC.)
;
; "ERROR" PRINTS THE STRING POINTED BY DE (AND ENDS WITH CR).
; IT THEN PRINTS THE LINE POINTED BY 'CURRNT' WITH A "?"
; INSERTED AT WHERE THE OLD TEXT POINTER (SHOULD BE ON TOP
; OF THE STACK) POINTS TO.  EXECUTION OF TB IS STOPPED
; AND TBI IS RESTARTED.  HOWEVER, IF 'CURRNT' -> ZERO
; (INDICATING A DIRECT COMMAND), THE DIRECT COMMAND IS NOT
; PRINTED.  AND IF 'CURRNT' -> NEGATIVE # (INDICATING 'INPUT'
; COMMAND), THE INPUT LINE IS NOT PRINTED AND EXECUTION IS
; NOT TERMINATED BUT CONTINUED AT 'INPERR'.
;
; RELATED TO 'ERROR' ARE THE FOLLOWING:
; 'QWHAT' SAVES TEXT POINTER IN STACK AND GET MESSAGE "WHAT?"
; 'AWHAT' JUST GET MESSAGE "WHAT?" AND JUMP TO 'ERROR'.
; 'QSORRY' AND 'ASORRY' DO SAME KIND OF THING.
; 'AHOW' AND 'AHOW' IN THE ZERO PAGE SECTION ALSO DO THIS.
;*************************************************************
setval:
				call testvar				; ** SetVal **
				jp c,qwhat				; no variable
				push hl					; save address of var
				call testc				; do we have =?
				.db '='
				.db sv1-$-1
				call expr				; evaluate expression
				ld b,h					; value is in bc now
				ld c,l
				pop hl					; get address
				ld (hl),c				; save value
				inc hl
				ld (hl),b
				ret
sv1:
				jp qwhat
fin:
				call testc				; test for ':'
				.db ':'
				.db fi1 - $ - 1
				pop af					; yes, purge return address
				jp runsml				; continue on same line
fi1:
				call testc				; not ':', is it cr
				.db cr
				.db fi2 - $ - 1
				pop af					; yes, purge return address
				jp runnxl				; run next line
fi2:
				ret					; else return to caller
endchk:
				call skipspace				; ** EndChk **
				cp cr					; ends with cr?
				ret z					; ok, otherwise say 'what?'
qwhat:
				push de					; ** QWhat **
awhat:
				ld de,what				; ** AWhat **
handleerror:
				sub a					; ** Error **
				call printstr				; print error message
				pop de
				ld a,(de)				; save the character
				push af					; at where old de points
				sub a					; and put a 0 (zero) there
				ld (de),a
				ld hl,(current)				; get the current line number
				push hl
				ld a,(hl)				; check the value
				inc hl
				or (hl)
				pop de
				jp z,rstart				; if zero, just rerstart
				ld a,(hl)				; if negative
				or a
				jp m,inputerror				; then redo input
				call printline				; else print the line
				dec de					; up to where the 0 is
				pop af					; restore the character
				ld (de),a
				ld a,'?'				; print a ?
				call outc
				sub a					; and the rest of the line
				call printstr
				jp rstart
qsorry:
				push de			   		; ** Sorry **
asorry:
				ld de,sorry
				jr handleerror

;*************************************************************
;
; *** GETLN *** FNDLN (& FRIENDS) ***
;
; 'GETLN' READS A INPUT LINE INTO 'BUFFER'.  IT FIRST PROMPT
; THE CHARACTER IN A (GIVEN BY THE CALLER), THEN IT FILLS
; THE BUFFER AND ECHOS.  IT IGNORES LF'S AND NULLS, BUT STILL
; ECHOS THEM BACK.  RUB-OUT IS USED TO CAUSE IT TO DELETE
; THE LAST CHARACTER (IF THERE IS ONE), AND ALT-MOD IS USED TO
; CAUSE IT TO DELETE THE WHOLE LINE AND START IT ALL OVER.
; CR SIGNALS THE END OF A LINE, AND CAUSE 'GETLN' TO RETURN.
;
; 'FNDLN' FINDS A LINE WITH A GIVEN LINE # (IN HL) IN THE
; TEXT SAVE AREA.  DE IS USED AS THE TEXT POINTER.  IF THE
; LINE IS FOUND, DE WILL POINT TO THE BEGINNING OF THAT LINE
; (I.E., THE LOW BYTE OF THE LINE #), AND FLAGS ARE NC & Z.
; IF THAT LINE IS NOT THERE AND A LINE WITH A HIGHER LINE #
; IS FOUND, DE POINTS TO THERE AND FLAGS ARE NC & NZ.  IF
; WE REACHED THE END OF TEXT SAVE AREA AND CANNOT FIND THE
; LINE, FLAGS ARE C & NZ.
; 'FNDLN' WILL INITIALIZE DE TO THE BEGINNING OF THE TEXT SAVE
; AREA TO START THE SEARCH.  SOME OTHER ENTRIES OF THIS
; ROUTINE WILL NOT INITIALIZE DE AND DO THE SEARCH.
; 'FNDLNP' WILL START WITH DE AND SEARCH FOR THE LINE #.
; 'FNDNXT' WILL BUMP DE BY 2, FIND A CR AND THEN START SEARCH.
; 'FNDSKP' USE DE TO FIND A CR, AND THEN START SEARCH.
;*************************************************************
getline:
				call outc				; ** GetLine **
				ld de,buffer				; prompt and initalise pointer
gl1:
				call chkio				; check keyboard
				jr z,gl1				; no input, so wait
				cp bs					; erase last character?
				jr z,gl3				; yes
				call outc				; echo character
				cp lf					; ignore lf
				jr z,gl1
				or a					; ignore null
				jr z,gl1
				cp ctrlu				; erase the whole line?
				jr z,gl4				; yes
				ld (de),a				; save the input
				inc de					; and increment pointer
				cp cr					; was it cr?
				ret z					; yes, end of line
				ld a,e					; any free space left?
				cp bufend & 0ffh
				jr nz,gl1				; yes, get next char
gl3:
				ld a,e					; delete last character
				cp buffer & 0ffh			; if there are any?
				jr z,gl4				; no, redo whole line
				dec de					; yes, back pointer
				ld a,08h				; and echo a backspace
				call outc
				jr gl1					; and get next character
gl4:
				call crlf				; redo entire line
				ld a,'>'
				jr getline
findline:
				ld a,h					; ** FindLine **
				or a					; check the sign of hl
				jp m,qhow				; it cannot be negative
				ld de,textbegin				; initialise the text pointer
findlineptr:
fl1:
				push hl					; save line number
				ld hl,(textunfilled)			; check if we passed end
				dec hl
				call comp
				pop hl					; retrieve line number
				ret c					; c,nz passed end
				ld a,(de)				; we didn't; get first byte
				sub l					; is this the line?
				ld b,a					; compare low order
				inc de
				ld a,(de)				; get second byte
				sbc a,h					; compare high order
				jr c,fl2				; no, not there yet
				dec de  				; else we either found it
				or b					; or it's not there
				ret					; nc,z:found; nc,nz:no
findnext:
				inc de					; find next line
fl2:
				inc de					; just passed first and second byte
findskip:
				ld a,(de)				; ** FindSkip **
				cp cr					; try to find cr
				jr nz,fl2				; keep looking
				inc de					; found cr, skip over
				jr fl1					; check if end of text

;*************************************************************
;
; *** PRTSTG *** QTSTG *** PRTNUM *** & PRTLN ***
;
; 'PRTSTG' PRINTS A STRING POINTED BY DE.  IT STOPS PRINTING
; AND RETURNS TO CALLER WHEN EITHER A CR IS PRINTED OR WHEN
; THE NEXT BYTE IS THE SAME AS WHAT WAS IN A (GIVEN BY THE
; CALLER).  OLD A IS STORED IN B, OLD B IS LOST.
;
; 'QTSTG' LOOKS FOR A BACK-ARROW, SINGLE QUOTE, OR DOUBLE
; QUOTE.  IF NONE OF THESE, RETURN TO CALLER.  IF BACK-ARROW,
; OUTPUT A CR WITHOUT A LF.  IF SINGLE OR DOUBLE QUOTE, PRINT
; THE STRING IN THE QUOTE AND DEMANDS A MATCHING UNQUOTE.
; AFTER THE PRINTING THE NEXT 3 BYTES OF THE CALLER IS SKIPPED
; OVER (USUALLY A JUMP INSTRUCTION.
;
; 'PRTNUM' PRINTS THE NUMBER IN HL.  LEADING BLANKS ARE ADDED
; IF NEEDED TO PAD THE NUMBER OF SPACES TO THE NUMBER IN C.
; HOWEVER, IF THE NUMBER OF DIGITS IS LARGER THAN THE # IN
; C, ALL DIGITS ARE PRINTED ANYWAY.  NEGATIVE SIGN IS ALSO
; PRINTED AND COUNTED IN, POSITIVE SIGN IS NOT.
;
; 'PRTLN' PRINTS A SAVED TEXT LINE WITH LINE # AND ALL.
;*************************************************************
printstr:
				ld b,a
ps1:
				ld a,(de)				; get a character
				inc de			   		; bump pointer
				cp b					; same as old A?
				ret z					; yes, return
				call outc				; no, show character
				cp cr					; was it a cr?
				jr nz,ps1				; no, next character
				ret					; yes, returns
qtstg:
				call testc				; ** Qtstg **
				.db 22h					; is it a double quote
				.db qt3-$-1
				ld a,22h
qt1:
				call printstr				; print until another
				cp cr
				pop hl
				jp z,runnxl
qt2:
				inc hl					; skip 3 bytes on return
				inc hl
				inc hl
				jp (hl)					; return
qt3:
				call testc				; is it a single quote
				.db 27h
				.db qt4-$-1
				ld a,27h
				jr qt1
qt4:
				call testc				; is it back-arrow
				.db '_'
				.db qt5-$-1
				ld a,8dh				; yes, cr without lf
				call outc
				call outc
				pop hl					; return address
				jr qt2
qt5:
				ret					; none of the above

printnum:
				ld b,0h					; ** PrintNum **
				call checksign				; check sign
				jp p,pn1				; no sign
				ld b,'-'
				dec c
pn1:
				push de					; save
				ld de, 000ah				; decimal
				push de					; save as flag
				dec c					; c=spaces
				push bc					; save sign & space
pn2:
				call divide				; divide hl by 10
				ld a,b					; result 0?
				or c
				jr z,pn3				; yes, we got all
				ex (sp),hl				; no, save remainder
				dec l					; and count space
				push hl					; hl is old bc
				ld h,b					; moved result to bc
				ld l,c
				jr pn2					; and divide by 10
pn3:
				pop bc					; we got all digits
pn4:
				dec c
				ld a,c					; look at space count
				or a
				jp m,pn5				; no leading spaces
				ld a,' '				; print a leading space
				call outc
				jr pn4					; any more?
pn5:
				ld a,b  				; print sign
				or a
				call nz,outc
				ld e,l					; last remainder in e
pn6:
				ld a,e					; check digit in e
				cp lf					; lf is flag for no more
				pop de
				ret z					; if yes, return
				add a,30h				; else convert to ascii
				call outc				; and print the digit
				jr pn6					; next digit
printhex:
				ld  c,h					; ** PrintHex **
				call ph1				; first hex byte
printhex8:
				ld  c,l					; then second
ph1:
				ld  a,c					; get left nibble into position
				rra
				rra
				rra
				rra
				call ph2				; and turn into hex digit
				ld  a,c					; then convert right nibble
ph2:
				and 0fh					; mask right nibble
				add a,90h				; and convert to ascii character
				daa
				adc a,40h
				daa
				call outc				; print character
				ret
printline:
				ld a,(de)				; ** PrintLine **
				ld l,a					; low order line number
				inc de
				ld a,(de)				; high order
				ld h,a
				inc de
				ld c,04h				; print 4 digit line number
				call printnum
				ld a,' '				; followed by a space
				call outc
				sub a					; and the the rest
				call printstr
				ret

;*************************************************************
;
; *** MVUP *** MVDOWN *** POPA *** & PUSHA ***
;
; 'MVUP' MOVES A BLOCK UP FROM WHERE DE-> TO WHERE BC-> UNTIL
; DE = HL
;
; 'MVDOWN' MOVES A BLOCK DOWN FROM WHERE DE-> TO WHERE HL->
; UNTIL DE = BC
;
; 'POPA' RESTORES THE 'FOR' LOOP VARIABLE SAVE AREA FROM THE
; STACK
;
; 'PUSHA' STACKS THE 'FOR' LOOP VARIABLE SAVE AREA INTO THE
; STACK
;*************************************************************
mvup:
				call comp				; ** mvup **
				ret z					; de = hl, return
				ld a,(de)				; get one byte
				ld (bc),a				; then copy it
				inc de					; increase both pointers
				inc bc
				jr mvup					; until done
mvdown:
				ld a,b					; ** mvdown **
				sub d					; check if de = bc
				jp nz,md1				; no, go move
				ld a,c					; maybe, other byte
				sub e
				ret z					; yes, return
md1:
				dec de					; else move a byte
				dec hl					; but first decrease both pointers
				ld a,(de)				; and then do it
				ld (hl),a
				jr mvdown				; loop back
popa:
				pop bc					; bc = return address
				pop hl					; restore loopvar
				ld (loopvar),hl
				ld a,h
				or l
				jr z,pp1				; all done, so return
				pop hl
				ld (loopinc),hl
				pop hl
				ld (looplmt),hl
				pop hl
				ld (loopln),hl
				pop hl
				ld (loopptr),hl
pp1:
				push bc					; bc = return address
				ret
pusha:
				ld hl,stacklimit			; ** PushA **
				call changesign
				pop bc					; bc = return address
				add hl,sp				; is stack near the top?
				jp nc,qsorry				; yes, sorry
				ld hl,(loopvar)				; else save loop variables
				ld a,h
				or l
				jr z,pu1				; only when loopvar not 0
				ld hl,(loopptr)
				push hl
				ld hl,(loopln)
				push hl
				ld hl,(looplmt)
				push hl
				ld hl,(loopinc)
				push hl
				ld hl,(loopvar)
pu1:
				push hl
				push bc					; bc = return address
				ret

testvar:
				call skipspace				; ** testvar **
				sub '@'					; test variables
				ret c					; not a variable
				jr nz,tv1				; not @ array
				inc de					; is is the @ array
				call parn				; @ should be followed by (expr)
				add hl,hl				; as its index
				jr c,qhow				; is index too big?
				push de					; will it override text?
				ex de,hl
				call size				; find the size of free
				call comp
				jp c,asorry				; yes, sorry
				ld hl,varbegin				; no, get address of @(expr) and
				call subde				; put it in hl
				pop de
				ret
tv1:
				cp 1bh					; not @, is it A to Z
				ccf
				ret c
				inc de					; if A through Z
				ld hl,varbegin				; calculate address of that variable
				rlca					; and return it in hl
				add a,l					; with the c flag cleared
				ld l,a
				ld a,0
				adc a,h
				ld h,a
				ret

testnum:
				call parsenum				; ** TestNum **
				ret nc					; if not a number, return nc and 0 in b and hl
				jr qhow					; carry set, so overflowed
parsenum:
				ld hl,0					; try to parse text as a number
				ld b,h					; if not a number, return 0 in b and hl
				call skipspace
tn1:
				cp '0'
				jr nc,tn2
				ccf					; reset carry
				ret
tn2:
				cp ':'					; if a digit, convert to binary in
				ret nc					; b and hl
				ld a,0f0h				; set b to number of digits
				and h					; if h>255, there is no room for
				jr z,tn3				; next digit, so set carry
				scf
				ret
tn3:
				inc b					; b counts number of digits
				push bc
				ld b,h					; hl=10*hl+(new digit)
				ld c,l
				add hl,hl				; where 10* is done by shift and add
				add hl,hl
				add hl,bc
				add hl,hl
				ld a,(de)				; and (digit) is by stripping the
				inc de					; ascii code
				and 0fh
				add a,l
				ld l,a
				ld a,0
				adc a,h
				ld h,a
				pop bc
				ld a,(de)
				jp p,tn1
				scf
				ret
qhow:
				push de					; ** Error How? **
ahow:
				ld de,how
				jp handleerror

welcome				
#ifdef PLATFORM
				.db PLATFORM," "
#endif
				.db "TASTY BASIC"
#ifdef VERSION
				.db " (",VERSION,")"
#endif
				.db cr
free				.db " BYTES FREE",cr
how				.db "HOW?",cr
ok				.db "OK",cr
what				.db "WHAT?",cr
sorry				.db "SORRY",cr

;*************************************************************
;
; *** MAIN ***
;
; THIS IS THE MAIN LOOP THAT COLLECTS THE TINY BASIC PROGRAM
; AND STORES IT IN THE MEMORY.
;
; AT START, IT PRINTS OUT "(CR)OK(CR)", AND INITIALIZES THE
; STACK AND SOME OTHER INTERNAL VARIABLES.  THEN IT PROMPTS
; ">" AND READS A LINE.  IF THE LINE STARTS WITH A NON-ZERO
; NUMBER, THIS NUMBER IS THE LINE NUMBER.  THE LINE NUMBER
; (IN 16 BIT BINARY) AND THE REST OF THE LINE (INCLUDING CR)
; IS STORED IN THE MEMORY.  IF A LINE WITH THE SAME LINE
; NUMBER IS ALREADY THERE, IT IS REPLACED BY THE NEW ONE.  IF
; THE REST OF THE LINE CONSISTS OF A CR ONLY, IT IS NOT STORED
; AND ANY EXISTING LINE WITH THE SAME LINE NUMBER IS DELETED.
;
; AFTER A LINE IS INSERTED, REPLACED, OR DELETED, THE PROGRAM
; LOOPS BACK AND ASKS FOR ANOTHER LINE.  THIS LOOP WILL BE
; TERMINATED WHEN IT READS A LINE WITH ZERO OR NO LINE
; NUMBER; AND CONTROL IS TRANSFERED TO "DIRECT".
;
; TINY BASIC PROGRAM SAVE AREA STARTS AT THE MEMORY LOCATION
; LABELED "TXTBGN" AND ENDS AT "TXTEND".  WE ALWAYS FILL THIS
; AREA STARTING AT "TXTBGN", THE UNFILLED PORTION IS POINTED
; BY THE CONTENT OF A MEMORY LOCATION LABELED "TXTUNF".
;
; THE MEMORY LOCATION "CURRNT" POINTS TO THE LINE NUMBER
; THAT IS CURRENTLY BEING INTERPRETED.  WHILE WE ARE IN
; THIS LOOP OR WHILE WE ARE INTERPRETING A DIRECT COMMAND
; (SEE NEXT SECTION). "CURRNT" SHOULD POINT TO A 0.
;*************************************************************
rstart:
				ld sp,stack
st1:
				call crlf
				sub a					; a=0
				ld de,ok				; print ok
				call printstr
				ld hl,st2 + 1				; literal zero
				ld (current),hl				; reset current line pointer
st2:
				ld hl,0
				ld (loopvar),hl
				ld (stkgos),hl
st3:
				ld a,'>'				; initialise prompt
				call getline
				push de					; de points to end of line
				ld de,buffer				; point de to beginning of line
				call testnum				; check if it is a number
				call skipspace
				ld a,h					; hl = value of the number, or
				or l					; 0 if no number was found
				pop bc					; bc points to end of line
				jp z,direct
				dec de  				; back up de and save the value of
				ld a,h					; the value of the line number there
				ld (de),a
				dec de
				ld a,l
				ld (de),a
				push bc					; bc,de point to begin,end
				push de
				ld a,c
				sub e

				push af					; a = number of bytes in line
				call findline				; find this line in save area
				push de					; de points to save area
				jr nz,st4				; nz: line not found
				push de					; z: found, delete it
				call findnext				; find next line
									; de -> next line
				pop bc					; bc -> line to be deleted
				ld hl,(textunfilled)			; hl -> unfilled text area
				call mvup				; move up to delete
				ld h,b					; txtunf -> unfilled area
				ld l,c
				ld (textunfilled),hl
st4:
				pop bc					; get ready to insert
				ld hl,(textunfilled)			; but first check if the length
				pop af					; of new line is 3 (line# and cr)
				push hl
				cp 3h					; if so, do not insert
				jr z,rstart				; must clear the stack
				add a,l					; calculate new txtunf
				ld l,a
				ld a,0
				adc a,h
				ld h,a					; hl -> new unfilled area
				ld de,textend				; check to see if there is space
				call comp
				jp nc,qsorry				; no, sorry
				ld (textunfilled),hl			; ok, update textunfilled
				pop de					; de -> old unfilled area
				call mvdown
				pop de					; de,hl -> begin,end
				pop hl
				call mvup				; copy new line to save area
				jr st3

;*************************************************************
;
; WHAT FOLLOWS IS THE CODE TO EXECUTE DIRECT AND STATEMENT
; COMMANDS.  CONTROL IS TRANSFERED TO THESE POINTS VIA THE
; COMMAND TABLE LOOKUP CODE OF 'DIRECT' AND 'EXEC' IN LAST
; SECTION.  AFTER THE COMMAND IS EXECUTED, CONTROL IS
; TRANSFERED TO OTHERS SECTIONS AS FOLLOWS:
;
; FOR 'LIST', 'NEW', AND 'STOP': GO BACK TO 'RSTART'
; FOR 'RUN': GO EXECUTE THE FIRST STORED LINE IF ANY, ELSE
; GO BACK TO 'RSTART'.
; FOR 'GOTO' AND 'GOSUB': GO EXECUTE THE TARGET LINE.
; FOR 'RETURN' AND 'NEXT': GO BACK TO SAVED RETURN LINE.
; FOR ALL OTHERS: IF 'CURRENT' -> 0, GO TO 'RSTART', ELSE
; GO EXECUTE NEXT COMMAND.  (THIS IS DONE IN 'FINISH'.)
;*************************************************************
;
; *** NEW *** CLEAR *** STOP *** RUN (& FRIENDS) *** GOTO ***
;
; 'NEW(CR)' SETS 'TXTUNF' TO POINT TO 'TXTBGN'
;
; 'CLEAR(CR)' CLEARS ALL VARIABLES
;
; 'END(CR)' GOES BACK TO 'RSTART'
;
; 'RUN(CR)' FINDS THE FIRST STORED LINE, STORE ITS ADDRESS (IN
; 'CURRENT'), AND START EXECUTE IT.  NOTE THAT ONLY THOSE
; COMMANDS IN TAB2 ARE LEGAL FOR STORED PROGRAM.
;
; THERE ARE 3 MORE ENTRIES IN 'RUN':
; 'RUNNXL' FINDS NEXT LINE, STORES ITS ADDR. AND EXECUTES IT.
; 'RUNTSL' STORES THE ADDRESS OF THIS LINE AND EXECUTES IT.
; 'RUNSML' CONTINUES THE EXECUTION ON SAME LINE.
;
; 'GOTO EXPR(CR)' EVALUATES THE EXPRESSION, FIND THE TARGET
; LINE, AND JUMP TO 'RUNTSL' TO DO IT.
;*************************************************************
new:
				call endchk				; ** New **
				ld hl,textbegin
				ld (textunfilled),hl
clear:
				call clrvars				; ** Clear **
				jp rstart
endd:
				call endchk				; ** End **
				jp rstart
run:
				call endchk				; ** Run **
				call rstreadptr
				ld de,textbegin
runnxl:
				ld hl,0h				; ** Run Next Line **
				call findlineptr
				jp c,rstart
runtsl:
				ex de,hl				; ** Run Tsl
				ld (current),hl				; set current -> line #
				ex de,hl
				inc de
				inc de
runsml:
				call chkio				; ** Run Same Line **
				ld hl, tab2-1				; find the command in table 2
				jp exec					; and execute it
goto:
				call expr
				push de					; save for error routine
				call endchk				; must find a cr
				call findline				; find the target line
				jp nz, ahow				; no such line #
				pop af					; clear the pushed de
				jr runtsl				; go do it

;*************************************************************
;
; *** LIST *** & PRINT ***
;
; LIST HAS TWO FORMS:
; 'LIST(CR)' LISTS ALL SAVED LINES
; 'LIST #(CR)' START LIST AT THIS LINE #
; YOU CAN STOP THE LISTING BY CONTROL C KEY
;
; PRINT COMMAND IS 'PRINT ....;' OR 'PRINT ....(CR)'
; WHERE '....' IS A LIST OF EXPRESIONS, FORMATS, BACK-
; ARROWS, AND STRINGS.  THESE ITEMS ARE SEPERATED BY COMMAS.
;
; A FORMAT IS A POUND SIGN FOLLOWED BY A NUMBER.  IT CONTROLS
; THE NUMBER OF SPACES THE VALUE OF A EXPRESION IS GOING TO
; BE PRINTED.  IT STAYS EFFECTIVE FOR THE REST OF THE PRINT
; COMMAND UNLESS CHANGED BY ANOTHER FORMAT.  IF NO FORMAT IS
; SPECIFIED, 6 POSITIONS WILL BE USED.
;
; A STRING IS QUOTED IN A PAIR OF SINGLE QUOTES OR A PAIR OF
; DOUBLE QUOTES.
;
; A BACK-ARROW MEANS GENERATE A (CR) WITHOUT (LF)
;
; A (CRLF) IS GENERATED AFTER THE ENTIRE LIST HAS BEEN
; PRINTED OR IF THE LIST IS A NULL LIST.  HOWEVER IF THE LIST
; ENDED WITH A COMMA, NO (CRLF) IS GENERATED.
;*************************************************************
list:
				call testnum				; check if there is a number
				call endchk				; if no number we get a 0
				call findline				; find this or next line
ls1:
				jp c,rstart
				call printline				; print the line
				call chkio				; stop on ctrl-c
				call findlineptr			; find the next line
				jr ls1					; and loop back

print:
				ld c,6					; c = number of spaces
				call testc				; is it a semicolon?
				.db ';'
				.db pr2-$-1
				call crlf
				jr runsml
pr2:
				call testc				; is it a cr?
				.db cr
				.db pr0-$-1
				call crlf
				jr runnxl
pr0:
				call testc				; is it format?
				.db '#'
				.db pr1-$-1
				call expr
				ld c,l
				jr pr3
pr1:
				call testc				; is it a dollar?
				.db '$'
				.db pr4-$-1
				call expr
				ld c,l
				call testc				; do we have a comma?
				.db ','
				.db pr6-$-1
				push bc
				call expr
				pop bc
				ld a,8					; 8 bits?
				cp c
				jp nz,pr9				; no, try 16
				call printhex8				; yes, print a single hex byte
				jp pr3
pr9:
				ld a,10h				; 16 bits?
				cp c
				jp nz,qhow				; no, show error message
				call printhex				; yes, print two hex bytes
				jp pr3
pr4:
				call qtstg				; is it a string?
				jp pr8
pr3:
				call testc				; is it a comma?
				.db ','
				.db pr6-$-1
				call fin
				jr pr0
pr6:
				call crlf				; list ends
				call finish
pr8:
				call expr				; evaluate the expression
				push bc
				call printnum
				pop bc
				jr pr3

;*************************************************************
;
; *** GOSUB *** & RETURN ***
;
; 'GOSUB EXPR;' OR 'GOSUB EXPR (CR)' IS LIKE THE 'GOTO'
; COMMAND, EXCEPT THAT THE CURRENT TEXT POINTER, STACK POINTER
; ETC. ARE SAVE SO THAT EXECUTION CAN BE CONTINUED AFTER THE
; SUBROUTINE 'RETURN'.  IN ORDER THAT 'GOSUB' CAN BE NESTED
; (AND EVEN RECURSIVE), THE SAVE AREA MUST BE STACKED.
; THE STACK POINTER IS SAVED IN 'STKGOS', THE OLD 'STKGOS' IS
; SAVED IN THE STACK.  IF WE ARE IN THE MAIN ROUTINE, 'STKGOS'
; IS ZERO (THIS WAS DONE BY THE "MAIN" SECTION OF THE CODE),
; BUT WE STILL SAVE IT AS A FLAG FOR NO FURTHER 'RETURN'S.
;
; 'RETURN(CR)' UNDOS EVERYTHING THAT 'GOSUB' DID, AND THUS
; RETURN THE EXECUTION TO THE COMMAND AFTER THE MOST RECENT
; 'GOSUB'.  IF 'STKGOS' IS ZERO, IT INDICATES THAT WE
; NEVER HAD A 'GOSUB' AND IS THUS AN ERROR.
;*************************************************************
gosub:
				call pusha				; ** Gosub **
				call expr				; save the current "FOR" params
				push de					; and text pointer
				call findline				; find the target line
				jp nz,ahow				; how? because it doesn't exist
				ld hl,(current)				; found it, save old 'current'
				push hl
				ld hl,(stkgos)				; and 'stkgos'
				push hl
				ld hl,0					; and load new ones
				ld (loopvar),hl
				add hl,sp
				ld (stkgos),hl
				jp runtsl				; and run the line
return:
				call endchk				; there must be a cr
				ld hl,(stkgos)				; check old stack pointer
				ld a,h					;
				or l
				jp z,what				; what? not found
				ld sp,hl				; otherwise restore it
				pop hl
				ld (stkgos),hl
				pop hl
				ld (current),hl				; and old 'current'
				pop de					; and old text pointer
				call popa				; and old 'FOR' params
				call finish				; and we're back

;*************************************************************
;
; *** FOR *** & NEXT ***
;
; 'FOR' HAS TWO FORMS:
; 'FOR VAR=EXP1 TO EXP2 STEP EXP3' AND 'FOR VAR=EXP1 TO EXP2'
; THE SECOND FORM MEANS THE SAME THING AS THE FIRST FORM WITH
; EXP3=1.  (I.E., WITH A STEP OF +1.)
; TBI WILL FIND THE VARIABLE VAR, AND SET ITS VALUE TO THE
; CURRENT VALUE OF EXP1.  IT ALSO EVALUATES EXP2 AND EXP3
; AND SAVE ALL THESE TOGETHER WITH THE TEXT POINTER ETC. IN
; THE 'FOR' SAVE AREA, WHICH CONSISTS OF 'LOPVAR', 'LOPINC',
; 'LOPLMT', 'LOPLN', AND 'LOPPT'.  IF THERE IS ALREADY SOME-
; THING IN THE SAVE AREA (THIS IS INDICATED BY A NON-ZERO
; 'LOPVAR'), THEN THE OLD SAVE AREA IS SAVED IN THE STACK
; BEFORE THE NEW ONE OVERWRITES IT.
; TBI WILL THEN DIG IN THE STACK AND FIND OUT IF THIS SAME
; VARIABLE WAS USED IN ANOTHER CURRENTLY ACTIVE 'FOR' LOOP.
; IF THAT IS THE CASE, THEN THE OLD 'FOR' LOOP IS DEACTIVATED.
; (PURGED FROM THE STACK..)
;
; 'NEXT VAR' SERVES AS THE LOGICAL (NOT NECESSARILLY PHYSICAL)
; END OF THE 'FOR' LOOP.  THE CONTROL VARIABLE VAR. IS CHECKED
; WITH THE 'LOPVAR'.  IF THEY ARE NOT THE SAME, TBI DIGS IN
; THE STACK TO FIND THE RIGHT ONE AND PURGES ALL THOSE THAT
; DID NOT MATCH.  EITHER WAY, TBI THEN ADDS THE 'STEP' TO
; THAT VARIABLE AND CHECK THE RESULT WITH THE LIMIT.  IF IT
; IS WITHIN THE LIMIT, CONTROL LOOPS BACK TO THE COMMAND
; FOLLOWING THE 'FOR'.  IF OUTSIDE THE LIMIT, THE SAVE AREA
; IS PURGED AND EXECUTION CONTINUES.
;*************************************************************

for:
				call pusha				; save old save area
				call setval				; set the control variable
				dec hl					; its address is hl
				ld (loopvar),hl				; save that
				ld hl,tab5-1				; use 'exec' to find 'TO'
				jp exec
fr1:
				call expr				; evaluate the limit
				ld (looplmt),hl				; and save it
				ld hl,tab6-1				; use 'exec' to find 'STEP'
				jp exec
fr2:
				call expr				; found 'STEP'
				jr fr4
fr3:
				ld hl,0001h				; no 'STEP' so set to 1
fr4:
				ld (loopinc),hl				; and save that too
fr5:
				ld hl,(current)				; save current line number
				ld (loopln),hl
				ex de,hl				; and text pointer
				ld (loopptr),hl
				ld bc,0ah				; dig into stack to find loopvar
				ld hl,(loopvar)
				ex de,hl
				ld h,b
				ld l,b
				add hl,sp
				.db 3eh
fr7:
				add hl,bc
				ld a,(hl)
				inc hl
				or (hl)
				jr z,fr8
				ld a,(hl)
				dec hl
				cp d
				jr nz,fr7
				ld a,(hl)
				cp e
				jr nz,fr7
				ex de,hl
				ld hl,0
				add hl,sp
				ld b,h
				ld c,l
				ld hl,0ah
				add hl,de
				call mvdown
				ld sp,hl
fr8:
				ld hl,(loopptr)				; all done
				ex de,hl
				call finish
next:
				call testvar				; get address of variable
				jp c,qwhat				; what, no variable
				ld (varnext),hl				; yes, save it
nx0:
				push de					; save the text pointer
				ex de,hl
				ld hl,(loopvar)				; get the variable in 'FOR'
				ld a,h
				or l					; if 0, there never was one
				jp z,awhat
				call comp				; else check them
				jr z,nx3				; yes, they agree
				pop de  				; no, complete current loop
				call popa
				ld hl,(varnext)				; and pop one level
				jr nx0					; go check again
nx3:
				ld e,(hl)
				inc hl
				ld d,(hl)				; de = value of variable
				ld hl,(loopinc)
				push hl
				ld a,h
				xor d
				ld a,d
				add hl,de
				jp m,nx4
				xor h
				jp m,nx5
nx4:
				ex de,hl
				ld hl,(loopvar)
				ld (hl),e
				inc hl
				ld (hl),d
				ld hl,(looplmt)
				pop af
				or a
				jp p,nx1				; step > 0
				ex de,hl				; step < 0
nx1:
				call ckhlde				; compare with limit
				pop de					; restore the text pointer
				jr c,nx2				; over the limit
				ld hl,(loopln)				; within the limit
				ld (current),hl
				ld hl,(loopptr)
				ex de,hl
				call finish
nx5:
				pop hl
				pop de
nx2:
				call popa				; purge this loop
				call finish				;

init:
				ld hl,start				; initialise random pointer
				ld (rndptr),hl
				ld hl,usrfunc				; initialise usr func pointer
				ld (usrptr),hl
				ld a,0c9h				; initialise usr func (RET)
				ld (usrfunc),a
				ld hl,textbegin				; initialise text area pointers
				ld (textunfilled),hl
				ld (ocsw),a				; enable output control switch
				call clrvars				; clear variables
				call crlf
				ld de,welcome				; output welcome message
				call printstr
				call crlf
				call size				; output free size message
				call printnum
				ld de,free
				call printstr
				jp rstart


;*************************************************************

#ifdef ROMWBW
#include			"romwbwio.asm"
#endif

#ifdef CPM
#include			"cpmio.asm"
#endif

#ifndef PLATFORM
#include			"zemuio.asm"
#endif

;*************************************************************
chkio:
				call haschar				; check if character available
				ret z					; no, return
#ifndef CPM
				call getchar				; get the character
#endif
				push bc					; is it a lf?
				ld b,a
				sub lf
				jr z,io1				; yes, ignore a return
				ld a,b					; no, restore a and bc
				pop bc
				cp ctrlo				; is it ctrl-o?
				jr nz,io2				; no, done
				ld a,(ocsw)				; toggle output control switch
				cpl
				ld (ocsw),a
				jr chkio				; get next character
io1:
				ld a,0h					; clear
				or a					; set the z-flag
				pop bc					; restore bc
				ret					; return with z set
io2:
				cp 60h					; is it lower case?
				jp c,io3				; no
				and 0dfh				; yes, make upper case
io3:
				cp ctrlc				; is it ctrl-c?
				ret nz					; no
				jp rstart				; yes, restart tasty basic
crlf:
				ld a,cr
outc:
				push af
				ld a,(ocsw)				; check output control switch
				or a
				jr nz,oc1   				; output is enabled
				pop af					; output is disabled
				ret					; so return
oc1:
				pop af
				call putchar
				cp cr					; was it a cr?
				ret nz					; no, return
				ld a,lf					; send a lf
				call outc
				ld a,cr					; restore register
				ret					; and return

;*************************************************************
;
; *** TABLES *** DIRECT *** & EXEC ***
;
; THIS SECTION OF THE CODE TESTS A STRING AGAINST A TABLE.
; WHEN A MATCH IS FOUND, CONTROL IS TRANSFERED TO THE SECTION
; OF CODE ACCORDING TO THE TABLE.
;
; AT 'EXEC', DE SHOULD POINT TO THE STRING AND HL SHOULD POINT
; TO THE TABLE-1.  AT 'DIRECT', DE SHOULD POINT TO THE STRING.
; HL WILL BE SET UP TO POINT TO TAB1-1, WHICH IS THE TABLE OF
; ALL DIRECT AND STATEMENT COMMANDS.
;
; A '.' IN THE STRING WILL TERMINATE THE TEST AND THE PARTIAL
; MATCH WILL BE CONSIDERED AS A MATCH.  E.G., 'P.', 'PR.',
; 'PRI.', 'PRIN.', OR 'PRINT' WILL ALL MATCH 'PRINT'.
;
; THE TABLE CONSISTS OF ANY NUMBER OF ITEMS.  EACH ITEM
; IS A STRING OF CHARACTERS WITH BIT 7 SET TO 0 AND
; A JUMP ADDRESS STORED HI-LOW WITH BIT 7 OF THE HIGH
; BYTE SET TO 1.
;
; END OF TABLE IS AN ITEM WITH A JUMP ADDRESS ONLY.  IF THE
; STRING DOES NOT MATCH ANY OF THE OTHER ITEMS, IT WILL
; MATCH THIS NULL ITEM AS DEFAULT.
;*************************************************************
tab1:									; direct commands
				.db "LIST"
				dwa(list)
				.db "RUN"
				dwa(run)
				.db "NEW"
				dwa(new)
				.db "CLEAR"
				dwa(clear)
#ifdef PLATFORM
				.db "BYE"
				dwa(bye)
#endif
tab2:									; direct/statements
				.db "NEXT"
				dwa(next)
				.db "LET"
				dwa(let)
				.db "IF"
				dwa(iff)
				.db "GOTO"
				dwa(goto)
				.db "GOSUB"
				dwa(gosub)
				.db "RETURN"
				dwa(return)
				.db "REM"
				dwa(rem)
				.db "FOR"
				dwa(for)
				.db "INPUT"
				dwa(input)
				.db "PRINT"
				dwa(print)
				.db "POKE"
				dwa(poke)
				.db "OUT"
				dwa(outp)
#ifdef CPM
				.db "LOAD"
				dwa(load)
				.db "SAVE"
				dwa(save)
#endif
datastmt:
				.db "DATA"
				dwa(data)
				.db "READ"
				dwa(read)
				.db "RESTORE"
				dwa(restore)
				.db "END"
				dwa(endd)
				dwa(deflt)
tab4:									; functions
				.db "PEEK"
				dwa(peek)
				.db "IN"
				dwa(inp)
				.db "RND"
				dwa(rnd)
				.db "ABS"
				dwa(abs)
				.db "USR"
				dwa(usrexec)
				.db "SIZE"
				dwa(size)
				dwa(xp40)
tab5:									; 'TO' in 'FOR'
				.db "TO"
				dwa(fr1)
tab6:									; 'STEP' in 'FOR'
				.db "STEP"
				dwa(fr2)
				dwa(fr3)
tab8:									; relational operators
				.db ">="
				dwa(xp11)
				.db "#"
				dwa(xp12)
				.db ">"
				dwa(xp13)
				.db "="
				dwa(xp15)
				.db "<="
				dwa(xp14)
				.db "<"
				dwa(xp16)
				dwa(xp17)

direct:
				ld hl,tab1-1				; ** Direct **
exec:
				call skipspace				; ** Exec **
				push de
ex1:
				ld a,(de)
				inc de
				cp '.'
				jr z,ex3
				inc hl
				cp (hl)
				jr z,ex1
				ld a,7fh
				dec de
				cp (hl)
				jr c,ex5
ex2:
				inc hl
				cp (hl)
				jr nc,ex2
				inc hl
				pop de
				jr exec
ex3:
				ld a,7fh
ex4:
				inc hl
				cp (hl)
				jr nc,ex4
ex5:
				ld a,(hl)
				inc hl
				ld l,(hl)
				and 7fh
				ld h,a
				pop af
				jp (hl)

;-------------------------------------------------------------------------------

LST_ROM:			; all the above _can_ be in rom
				; all following *must* be in ram
padding				.equ (TBC_LOC + USRPTR_OFFSET - $)
				.echo "TASTYBASIC ROM padding: "
				.echo padding
				.echo " bytes.\n"
				.org TBC_LOC + USRPTR_OFFSET
usrptr				.ds 2					; -> user defined function area
usrfunc				.equ $					; start of user defined function area
				.org TBC_LOC + INTERNAL_OFFSET		; start of state
ocsw				.ds 1					; output control switch
current				.ds 2					; points to current line
stkgos				.ds 2					; saves sp in 'GOSUB'
varnext				.ds 2					; temp storage
stkinp				.ds 2					; save sp in 'INPUT'
loopvar				.ds 2					; 'FOR' loop save area
loopinc				.ds 2					; loop increment
looplmt				.ds 2					; loop limit
loopln				.ds 2					; loop line number
loopptr				.ds 2					; loop text pointer
rndptr				.ds 2					; random number pointer
readptr				.ds 2					; read pointer
textunfilled			.ds 2					; -> unfilled text area
textbegin			.ds 2					; start of text save area
				.org TBC_LOC + TEXTEND_OFFSET
textend				.ds 0					; end of text area
varbegin			.ds 55					; variable @(0)
varend				.equ $					; end of variable area
buffer				.ds 72					; input buffer
bufend				.ds 1
stacklimit			.equ $
				.org TBC_LOC + STACK_OFFSET
stack				.equ $

#ifdef ROMWBW
slack				.equ (TBC_END - LST_ROM)
				.fill slack,'t'

				.echo "TASTYBASIC space remaining: "
				.echo slack
				.echo " bytes.\n"
#endif
				.end
