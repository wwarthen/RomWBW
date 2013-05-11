#include "stdio.h"
#include "rasm80.h"

main()
{
	FILE * fd;
	fd = fopen("rasm8080.com","w");
	fwrite(rasm80,sizeof(rasm80),1,fd);
	fclose(fd);
}
