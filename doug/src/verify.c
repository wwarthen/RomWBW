#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int compare(char *file1,unsigned int offset1,char *file2,unsigned int offset2,unsigned int length)
{
	int count1,count2,index;
	unsigned char buffer1[65535];
	unsigned char buffer2[65535];
	FILE * fp1,*fp2;

	fp1 = fopen(file1,"r");
	if(NULL == fp1) {
		printf("Sorry, cannot open %s\n",file1);
		exit(EXIT_FAILURE);
	}
	count1 = fread(buffer1,offset1+length,1,fp1);
	if(1 != count1) {
		printf("Sorry, cannot read %d bytes from %s\n",offset1+length,file1);
		printf("bytes read were %d\n",count1);
		printf("ferror returned %d\n",ferror(fp1));
		fclose(fp1);
		exit(EXIT_FAILURE);
	}
	fclose(fp1);
	
	fp2 = fopen(file2,"r");
	if(NULL == fp2) {
		printf("Sorry, cannot open %s\n",file2);
		fclose(fp1);
		exit(EXIT_FAILURE);
	}

        count2 = fread(buffer2,length,1,fp2);
        if(1 != count2) {
                printf("Sorry, cannot read %d bytes from %s\n",length,file2);
		fclose(fp2);
		exit(EXIT_FAILURE);
        }
	fclose(fp2);

	for(index=0;index<length;index++) {
		if(buffer1[offset1+index] != buffer2[offset2+index]) {
			printf("difference index was %04X "
			       "byte1 is %02X "
			       "byte2 is %02X\n",
				index,
				buffer1[offset1+index],
				buffer2[offset2+index]);

			return(1);
		}

	}
	return(0);
}

int main(int argc,char **argv)
{
	printf("%s %s %s %s\n",argv[0],__FILE__,__DATE__,__TIME__);

	printf("%s %s %s %s %s\n",argv[1],argv[2],argv[3],argv[4],argv[5]);

	printf("0xE600 is %d\n",0xe600);

	int rc = compare(
		argv[1],atoi(argv[2]),
		argv[3],atoi(argv[4]),
		atoi(argv[5])
	);

	return EXIT_SUCCESS;
}

