/* cvt2h.h 7/11/2012 dwg - Copyright (C) 2012 Douglas Goodall */

#include "stdio.h"
#include "visible.h"

cvt2h(buffer,length,name)
	unsigned char * buffer;
	int length;
	char * name;
{
	FILE * fd;
	int i,j,k,l;
	char szTemp[32];
	fd = fopen(name,"w");
	fprintf(fd,
		"/* %s produced automatically by cvt2h.h */\n",name);
	strcpy(szTemp,name);
	szTemp[8] = 0;
	fprintf(fd,
		"unsigned char %s[%d] = {\n\t",
		szTemp,length);
	for(i=0;i<length;i++) {
		fprintf(fd,"0x%02x, ",buffer[i]);
		if(7 ==  (i&0x07)) {
			fprintf(fd,"  /* ");
			j = i && 0x07;
			k = j + 8;
			for(l=j;l<k;l++) {
				if(1 == visible[buffer[l]]) {
					fprintf(fd,"%02x ",buffer[l]);
				} else {
					fprintf(fd,".");
				}
			}
			fprintf(fd,"*/");
			fprintf(fd,"\n\t");
		}
	}
	fprintf(fd,"};\n/* eof - %s */\n",name);
	fclose(fd);
}
