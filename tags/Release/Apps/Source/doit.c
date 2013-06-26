#include "stdio.h"

main()
{
	FILE * fd;
	fd = fopen("$$$.SUB","w");
	fprintf(fd,"%ca:getcfg\n",9);
	fprintf(fd,"%ca:dump syscfg.bin\n",18);
	fprintf(fd,"%ctype a:sect0000.h\n",17);
	fclose(fd);
}
