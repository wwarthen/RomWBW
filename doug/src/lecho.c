#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc,char **argv)
{
	char szTemp[128];
	int index;

	strcpy(szTemp,argv[1]);
	for(index=0;index<strlen(szTemp);index++) {
		printf("%c",szTemp[index]);
	}
	return EXIT_SUCCESS;
}

