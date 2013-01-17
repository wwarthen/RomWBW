/* cbanner.c 3/12/2012 dwg - */

#include "portab.h"
#include "globals.h"
#include "applvers.h"

char * lines = "----------------------------------------";
char * line1 = "12345678.123 mm/dd/yyyy  Version x.x.x.x";
char * line2 = "S/N CPM80-DWG-654321 Licensed under GPL3";
char * line3 = "Copyright (C) 2011-12 Douglas W. Goodall";

sbanner(program)
	char *program;
{
	char szTemp[128];
	
	printf("%s ",program);
	printf("%2d/%2d/%4d  ",A_MONTH,A_DAY,A_YEAR);
	printf("Version %d.%d.%d.%d ",A_RMJ,A_RMN,A_RUP,A_RTP);
	printf("COPR Douglas Goodall Licensed w/GPLv3\n");
}

banner(program)
	char *program;
{
	char szTemp[128];
	
	printf("%s\n",lines);
	strcpy(szTemp,program);
	while(12 > strlen(szTemp)) {
	strcat(szTemp," ");
	}
	printf("%s ",szTemp);
	printf("%2d/%2d/%4d  ",A_MONTH,A_DAY,A_YEAR);
	printf("Version %d.%d.%d.%d\n",A_RMJ,A_RMN,A_RUP,A_RTP);
	printf("%s\n",line2);
	printf("%s\n",line3);
	printf("%s\n",lines);
}

