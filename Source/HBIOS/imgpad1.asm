#INCLUDE "std.asm"
;
SLACK		.EQU	($8000-BAS_SIZ-TBC_SIZ-FTH_SIZ-GAM_SIZ-USR_SIZ)
		.FILL	SLACK,00H
;
MON_STACK	.EQU	$
;
		.ECHO	"Padspace space created: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"

		.END