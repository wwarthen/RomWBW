; program to test user LEDs on Z80 MBC clock board
; by Andrew Lynch, 6 Jul 2021

  org $0100
	LD	A,%00000011
    OUT	($70),A	; turn on USERLED0 and USERLED1
    RET
	end
