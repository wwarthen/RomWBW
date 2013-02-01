
/* echolf.c */

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

	if(argc>2) {
	   	printf(" ");
		strcpy(szTemp,argv[2]);
          	for(index=0;index<strlen(szTemp);index++) {
                	printf("%c",szTemp[index]);
        	}
	}

        if(argc>3) {
                printf(" ");
                strcpy(szTemp,argv[3]);
                for(index=0;index<strlen(szTemp);index++) {
                        printf("%c",szTemp[index]);
                }
        }

        if(argc>4) {
                printf(" ");
                strcpy(szTemp,argv[4]);
                for(index=0;index<strlen(szTemp);index++) {
                        printf("%c",szTemp[index]);
                }
        }

	printf("%c",0x0a);
	return EXIT_SUCCESS;
}

