; test program for user button on Z80 MBC clock board
; by Andrew Lynch, 6 Jul 2021


  ORG    00100H

MAIN_LOOP:

	IN	A,($70)		    ; READ USER BUTTON STATUS
	AND	%01000000	    ; REMOVE ALL EXCEPT USER BUTTON (D6)
	    			    ; 0=PRESSED, 1=NOT PRESSED
	JR	NZ,MAIN_LOOP	; IF NOT PRESSED TRY AGAIN

	LD	A,%00000011	    ; TURN ON BOTH USER LEDS
	OUT	($70),A		    ;

    RET
    
    end
