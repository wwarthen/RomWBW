/*
 * copyfile.c 5/11/2011 dwg - 
 * Main C module uses cpmbdos.h bindings to access system services
 * Copyright (C) Douglas Goodall All Rights Reserved
 * For non-commercial use by N8VEM Community
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stdlib.h"
#include "cpmbdos.h"
#include "cprintf.h"

char sine[] = "copyfile.c(com) 5/11/2011 dwg - $";

struct FCB * prifcb = (struct FCB *)0x5c;
struct FCB * secfcb = (struct FCB *)0x6c;

struct FCB srcfcb;
struct FCB dstfcb;

struct BDOSCALL writestr = { C_WRITESTR, { (unsigned int)&sine   } };
struct BDOSCALL makedst  = { F_MAKE,     { (unsigned int)&dstfcb } };
struct BDOSCALL opensrc  = { F_OPEN,     { (unsigned int)&srcfcb } };
struct BDOSCALL readsrc  = { F_READ,     { (unsigned int)&srcfcb } };
struct BDOSCALL writedst = { F_WRITE,    { (unsigned int)&dstfcb } };
struct BDOSCALL closesrc = { F_CLOSE,    { (unsigned int)&srcfcb } };
struct BDOSCALL closedst = { F_CLOSE,    { (unsigned int)&dstfcb } };

struct BDOSCALL cwrite   = { C_WRITE,    { (unsigned int)'?' } };
struct BDOSCALL cread    = { C_READ,     { (unsigned int)0   } };

/* THESE ARE USED BY THE LIBRARY ROUTINES */
char getchar(void)
{
	struct BDOSCALL cread = { C_READ, { (unsigned int)0 } };
	return cpmbdos(&cread);
}
void outchar(char c)
{
	struct BDOSCALL cwrite = { C_WRITE, { (unsigned int)c } };
	cpmbdos(&cwrite);
}

int main(void)
{
	int rc;

	cpmbdos(&writestr);

	strncpy(srcfcb.filename,prifcb->filename,8+3);
	srcfcb.ex = srcfcb.rc = srcfcb.cr = 0;
	rc = cpmbdos(&opensrc); printf("\nrc from opensrc was %2d, ",rc);
	if(rc != 0) {
		printf("\nSorry, cannot open source file\n");
		return(EXIT_FAILURE);
	}

	strncpy(dstfcb.filename,secfcb->filename,8+3);
	dstfcb.ex = dstfcb.rc = dstfcb.cr = 0;
	rc = cpmbdos(&makedst); printf("rc from  makedst was %2d",rc);
	if(rc != 0) {
		printf("\nSorry, cannot open destination file\n");
		cpmbdos(&closesrc);
		return(EXIT_FAILURE);
	}

	rc = cpmbdos(&readsrc); printf("\nrc from read was %2d, ",rc);
	while(0 == rc) {
		rc = cpmbdos(&writedst); printf(  "rc from write was %2d",  rc);
		rc = cpmbdos(&readsrc);  printf("\nrc from read was %2d, ",rc);
	}
	rc = cpmbdos(&closesrc); printf("\nrc from closesrc was %2d, ",rc);
	rc = cpmbdos(&closedst); printf(  "rc from closedst was %2d",  rc);

	return EXIT_SUCCESS;
}

