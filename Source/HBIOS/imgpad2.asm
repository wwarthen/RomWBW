#INCLUDE "std.asm"
;
SLACK		.EQU	($8000-NET_SIZ)
		.FILL	SLACK,00H
;
MON_STACK	.EQU	$
;
		.ECHO	"Padspace space created: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"

		.END