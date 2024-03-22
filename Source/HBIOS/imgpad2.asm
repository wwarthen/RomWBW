#INCLUDE "std.asm"
;
SLACK		.EQU	$8000
		.FILL	SLACK,00H
;
		.ECHO	"Padspace space created: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"

		.END