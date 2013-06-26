/* cvt2inc.h 7/23/2012 dwg - make tasm include file  from binary buffer */

cvt2inc(buffer,length,name)
	unsigned char * buffer;
	int length;
	char * name;
{
	FILE * fd;
	int i,j,k,l;
	char szTemp[32];
	fd = fopen(name,"w");
	fprintf(fd,
		"; %s produced automatically by cvt2inc.h \n",name);
	strcpy(szTemp,name);
	szTemp[8] = 0;
	fprintf(fd,"%s:\n",szTemp);
	fprintf(fd,"  .DB  ");
	i = 0;

	for(i=0;i<length;i++) {
		fprintf(fd,"%03xh",buffer[i]);
		if(7 ==  (i&0x07)) {
			fprintf(fd,"  ; ");
			j = i & 0xfff8;
			k = j + 8;
			fprintf(fd," %04x: ",j);

			for(l=j;l<k;l++) {
				if(1 == visible[buffer[l]]) {
					fprintf(fd,"%c ",buffer[l]);
				} else {
					fprintf(fd,". ");
				}
			}

			if(i != length-1) fprintf(fd,"\n  .DB  ");

		} else {
		  fprintf(fd,",");
		}
	}
	fprintf(fd,"\n");
	fclose(fd);
}
