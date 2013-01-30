// ---------------------------------------------------
// load.c       21-May-11   Running on Mac OS X 10.6.6
// S/n 2011-1042-654321  Written by Douglas W. Goodall
// Copyright(c)2011 Douglas W. Goodall, United States.
// ---------------------------------------------------
// This file is part of Vintage Modern Assembler Plus Tools.
//
// VMAPT is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// VMAPT is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with VMAPT.  If not, see <http://www.gnu.org/licenses/>.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DATA_RECORD 0x00
#define EOF_RECORD  0x01

int main(int argc,char **argv)
{
	FILE * fcom, * fhex;
	char g_szBuffer2[128];
	char szByteBuffer[2+1];
	char *p;
	int iTemp;
		
	char cColon;

	char szLength[2+1];
	int  iLength;
	
	char szAddress[4+1];
	unsigned int uiAddress;
	
	char szRecordType[2+1];
	unsigned char ucRecordType;
	
	char szData[80];
	unsigned char ucBinBuffer[32+1];
	
	char szChecksum[2+1];
	unsigned char ucChecksum;

	unsigned int uiLastByte = 0;
			
        char szComFile[255];
        char szHexFile[255];
	int i;

        unsigned char memory[0xfff0];

        if(1 == argc) {
                printf("usage - load <hexfilespec>\n");
		exit(EXIT_FAILURE);
        }

        strcpy(szHexFile,argv[1]);
        strcpy(szComFile,argv[1]);

        strcat(szComFile,".com");
        strcat(szHexFile,".hex");

	memset(memory,0,sizeof(memory));

	fhex = fopen(szHexFile,"r");		
	if(NULL == fhex) {
		printf("Sorry, cannot open %s for input\n",szHexFile);
		exit(EXIT_FAILURE);
	}
	p = fgets(g_szBuffer2,sizeof(g_szBuffer2),fhex);			
	while(NULL != p) {
		g_szBuffer2[strlen(g_szBuffer2)-1] = 0;
		cColon = g_szBuffer2[0];

		memset(szLength,0,sizeof(szLength));
		memcpy(szLength,&g_szBuffer2[1],2);
		sscanf(szLength,"%02X",&iLength);

		memset(szAddress,0,sizeof(szAddress));
		memcpy(szAddress,&g_szBuffer2[3],4);
		sscanf(szAddress,"%04X",&uiAddress);

		memset(szRecordType,0,sizeof(szRecordType));
		memcpy(szRecordType,&g_szBuffer2[7],2);

		sscanf(szRecordType,"%02X",&iTemp);
		ucRecordType = (unsigned char)iTemp;

		if(0 == ucRecordType) {
			memset(szData,0,sizeof(szData));
			memcpy(szData,&g_szBuffer2[9],iLength*2);
			for(i=0;i<iLength;i++) {
				memset(szByteBuffer,0,sizeof(szByteBuffer));
				memcpy(szByteBuffer,&g_szBuffer2[1+2+4+2+(i*2)],2);
				sscanf(szByteBuffer,"%02X",&iTemp);
				ucBinBuffer[i] = iTemp;
				memory[uiAddress+i] = (unsigned char)iTemp;
			}
		}

		memset(szChecksum,0,sizeof(szChecksum));
		memcpy(szChecksum,&g_szBuffer2[1+2+4+2+(iLength*2)],2);

		sscanf(szChecksum,"%02X",&iTemp);
		ucChecksum = (unsigned char)iTemp;

		if(uiLastByte < uiAddress + iLength) {
			uiLastByte = uiAddress + iLength;
		}

		p = fgets(g_szBuffer2,sizeof(g_szBuffer2),fhex);
	}
	fclose(fhex);

	fcom = fopen(szComFile,"w");

	fwrite(&memory[0x100],1,uiLastByte-0x100,fcom);
	fclose(fcom);

}
