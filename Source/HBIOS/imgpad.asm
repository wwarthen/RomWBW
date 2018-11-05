#INCLUDE "std.asm"
;
SLACK		.EQU	($8000-LDR_SIZ-MON_SIZ-SYS_SIZ-SYS_SIZ-EGG_SIZ)
		.FILL	SLACK,00H
;
MON_STACK	.EQU	$
;
		.ECHO	"Padspace space created: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"

		.END
