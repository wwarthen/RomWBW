/* hex2bin.c -- yet another reader and writer of Intel hex files 
   Copyright (C) 2011 John R Coffman <johninsd@gmail.com>.
***********************************************************************
   When invoked as 'hex2bin' read a sequence of Intel hex files
   and create an overlaid binary file.

   When invoked as 'bin2hex' read a binary file and create an
   Intel hex file.

   All command line numeric constants may be specified in any
   radix.
***********************************************************************

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    in the file COPYING in the distribution directory along with this
    program.  If not, see <http://www.gnu.org/licenses/>.

**********************************************************************/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "mytypes.h"

#define true   1
#define false  0
#define SEG_MASK 0x00FFFFu
#define LBA_MASK 0x00FF0000ul
#define MAX_MASK (LBA_MASK|SEG_MASK)
#define ONE_MEG 0x100000ul

dword upper_lba = 0;     /* upper address */
dword address_mask = SEG_MASK;  /* address mask  */
byte pad = 0xFF;
byte *buffer;
dword rom_size = 0;
dword overwrite;     /* count of possible overwrites */
byte h2b, verbose, segmented;
char *outfilename = NULL;
char *binfilename = NULL;
dword source_address, source_limit;
dword dest_address, dest_limit;
FILE *infile;
FILE *outfile;
byte checksum;
char line[1024];
char *lp;
long int lineno;



dword convert_constant(char *str)
{
   char *final;
   dword value = strtoul(str, &final, 0);

   if (*final == 'k' || *final == 'K') value *= 1024ul;
   else if (*final == 'M' || *final == 'm') value *= ONE_MEG;

   return value;
}

void error(byte level, char *msg)
{
   printf("%s(%d): %s\n",
         level>1 ? "Error" : "Warning", (int)level, msg);
   if (level>1) exit(level);
   else if (level==0) printf("line %ld  %s", lineno, line);
}


int getnibble(void)
{
   char ch;

	ch = -1;
   if (lp) {
      ch = *lp++;
      if (ch>='0' && ch<='9') ch -= '0';
      else if (ch>='A' && ch<='F') ch -= 'A'-10;
      else if (ch>='a' && ch<='f') ch -= 'a'-10;
      else {
         error(0,"Illegal hex digit");
         ch = -1;
      }
   }
   else error(0,"Line is too short");
   return (int)ch;
}

int getbyte(void)
{
   int b = getnibble();
   b <<= 4;
   b += getnibble();
   checksum += b;
   return b;
}

int getword(void)
{
   int w = getbyte();
   w <<= 8;
   w += getbyte();
   return w;
}

dword getdword(void)
{
   dword d = getword();
   d <<= 16;
   d += getword();
   return d;
}

/* added for SREC files */
dword get6word(void)
{
   dword d = getword();
   d <<= 8;
   d += getbyte();
   return d;
}


void putbyte(dword address, byte data)
{
   if (address < source_address  ||  address > source_limit) return;
   address -= source_address;
   address += dest_address;
   if (address > dest_limit) return;
   if (address >= rom_size) {
      printf("Line %ld ", lineno); error(2,"Data beyond end of ROM");
   }
   if (buffer[address] != pad) {
      overwrite++;
      if (verbose || overwrite<=100) printf("Warning(1): Overwrite at ROM address 0x%lX\n", address);
   }
   buffer[address] = data;
}


void usage(void)
{
   printf("hex2bin.c (bin2hex) -- " __TIMESTAMP__ ".\n"
          "Copyright (c) 2011 John R Coffman. All rights reserved.\n"
          "Distributed under the GNU General Public License, a copy of which\n"
          "is contained in the file COPYING in the distribution directory.\n\n");
   if (h2b) printf(
   "Usage:\n"
   "    hex2bin <options> [<flags> <filename>[/M]]+\n\n"
   "    Options:\n"
   "        -o <output filename>\n"
   "        -p <pad byte>\n"
   "        -R <ROM size> default 64K\n"
   "        -v [<verbosity level>]\n"
   "    Flags:\n"
   "        -d <destination address in BIN file>\n"
   "        -D <destination limit in BIN file>\n"
   "        -s <source address in HEX file>\n"
   "        -S <source limit in HEX file>\n"
	"    Suffix:\n"
	"        /M marks a Motorola S-record input file\n"
   );
   else printf(
   "Usage:\n"
   "    bin2hex <options> [<flags> <filename>]+\n\n"
   "    Options:\n"
   "        -g use Intel seGmented addressing\n"
   "        -o <output filename>\n"
   "        -p <pad byte>\n"
   "        -R <ROM size> default 1024K\n"
   "        -v [<verbosity level>]\n"
   "    Flags:\n"
   "        -d <destination address in HEX file>\n"
   "        -D <destination limit in HEX file>\n"
   "        -s <source address in BIN file>\n"
   "        -S <source limit in BIN file>\n"
   );
}


void hout_byte(byte data)
{
   checksum -= data;
   fprintf(outfile, "%02X", (int)data);
}
void hout_word(word data)
{
   hout_byte(data>>8);
   hout_byte(data);
}
void begin_record(byte length)
{
   checksum = 0;
   fputc(':', outfile);
   hout_byte(length);
}
void end_record(void)
{
   hout_byte(checksum);
   fputc('\n', outfile);
}

void write_lba(dword address)
{
   if (verbose==5) printf("Address: %06lX\n", address);

   if ((address & LBA_MASK) != upper_lba) {
      upper_lba = address & LBA_MASK;
      begin_record(2);
      hout_word(0);
      if (rom_size > ONE_MEG || !segmented) {
         hout_byte(4);     /* linear address */
         hout_word(upper_lba>>16);
      }
      else {   /* handle ROMs 1meg and smaller */
         hout_byte(2);     /* segment address */
         hout_word(upper_lba>>4);
      }
      end_record();
   }
}

void write_data(word nbytes, byte *buf, dword address)
{
   /* compress from the high end */
   while (nbytes && buf[nbytes-1]==pad) --nbytes;
   /* compress from the low end */
   while (nbytes && *buf==pad) {
      ++buf;
      ++address;
      --nbytes;
   }
   if (nbytes) {
      write_lba(address);
      begin_record(nbytes);
      hout_word(address & 0xFFFFu);
      hout_byte(0);     /* data record */
      while(nbytes--) hout_byte(*buf++);
      end_record();
   }
}

#define min(a,b) ((a)<(b)?(a):(b))
#define NREC 16

void write_hex_file(FILE *outfile)
{
   dword nbytes;
   dword vaddr;
   dword n;
   byte *buf;

   buf = buffer;
   vaddr = 0;
   nbytes = rom_size;
   n = min(nbytes, NREC);
   do {
      write_data(n, buf, vaddr);
      buf += n;
      vaddr += n;
      nbytes -= n;
      n = min(nbytes, NREC);
   } while (n);
/* write the end-of-file record */
   fprintf(outfile,":00000001FF\n");
}


void scan_bin_file(char *filename)
{
   dword length;
   dword nbytes;
   int data;
   dword inaddr;

   infile = fopen(filename, "rb");
   if (!infile) {
      strcpy(line,"Cannot find file: ");
      error(5, strcat(line, filename));
   }
/***   length = filelength(fileno(infile));    ***/
   fseek(infile, 0L, SEEK_END);
   length = ftell(infile);
/***/
   nbytes = 0;
   inaddr = dest_address;
   if (source_address < length) {
      fseek(infile, source_address, SEEK_SET);
      while (inaddr<rom_size && inaddr<=dest_limit) {
         data = fgetc(infile);
         if (data == EOF) break;
         buffer[inaddr++] = data;
      }
   }

   fclose(infile);
}

void scan_srec_file(char *filename)
{
   byte ldata;
   dword laddr;
   byte rectype;
   dword index;
   byte data;
   byte EndOfFile = 0;

   infile = fopen(filename, "rt");
   if (!infile) {
      strcpy(line,"Cannot find file: ");
      error(5, strcat(line, filename));
   }
   lineno = 0;
	laddr = 0;
   do {
      lineno++;
      lp = fgets(line, nelem(line)-1, infile);
      if (lp == NULL) break;
      if (*lp++ != 'S') {
         printf("Illegal: %s",--lp);
         continue;
      }
      if (verbose>=3) printf("%s", lp-1);
      checksum = 0;
      rectype = getnibble();
      ldata = getbyte();
		switch(rectype) {		/* get variable address field */
			case 0:
			case 1:
			case 5:
			case 9:
				laddr = getword();
				ldata -= 2;
				break;
			case 2:
			case 8:
				laddr = get6word();
				ldata -= 3;
				break;
			case 3:
			case 7:
				laddr = getdword();
				ldata -= 4;
				break;
			default:
            error(0,"Unknown record type:");
		}
		if (rectype>=1 && rectype<=3) {
         index = 0;
         while (--ldata) {
            data = getbyte();
					/* no address mask used */
            putbyte(laddr + index, data);
            index++;
         }
		}
		else if (rectype==0) {
			printf("Comment: ");
			while (--ldata) {
				printf("%c", (char)getbyte());
			}
			printf("\n");
		}
	/* else  records 5,7,8,9 are ignored */

      data = getbyte();           /* get final checksum */
      if (checksum != 0xFF) {
         error(0,"Checksum failure");
      }
   } while (lp && !EndOfFile);
   fclose(infile);
}

void scan_Intel_file(char *filename)
{
   byte ldata;
   dword laddr;
   byte rectype;
   dword value;
   dword index;
   byte data;
   byte EndOfFile = 0;

   infile = fopen(filename, "rt");
   if (!infile) {
      strcpy(line,"Cannot find file: ");
      error(5, strcat(line, filename));
   }
   upper_lba = 0;
   lineno = 0;
   do {
      lineno++;
      lp = fgets(line, nelem(line)-1, infile);
      if (lp == NULL) break;
      if (*lp++ != ':') {
         printf("Comment: %s",--lp);
         continue;
      }
      if (verbose>=3) printf("%s", lp-1);
      checksum = 0;
      ldata = getbyte();
      laddr = getword();
      rectype = getbyte();
      switch (rectype) {
         case 0:                 /* data record */
            index = 0;
            while (ldata--) {
               data = getbyte();
               putbyte(upper_lba + ((laddr + index)&address_mask), data);
               index++;
            }
            break;
         case 1:                 /* end of file record */
            EndOfFile = 1;
            break;
         case 2:                 /* segment address */
            address_mask = SEG_MASK;
            value = getword();
            upper_lba = value<<4;   /* start of segment */
            ldata -= 2;
            break;
         case 4:                 /* linear upper address */
            address_mask = MAX_MASK;
            value = getword();
            upper_lba = value<<16;  /* full 32-bit address range */
            ldata -= 2;
            break;
         case 3:                 /* start CS:IP */
         case 5:                 /* linear start address */
            value = getdword();
            ldata -= 4;
				break;
         default:
            error(0,"Unknown record type:");
      }
      getbyte();           /* get final checksum */
      if ( (checksum & 0xFF) ) {
         error(0,"Checksum failure");
      }
   } while (lp && !EndOfFile);
   fclose(infile);
}


void scan_hex_file(char *filename)
{
	int i = strlen(filename);

	if (i>3  &&  filename[i-2]=='/'
			&& (filename[i-1]=='M') )   {
		filename[i-2] = 0;		/* remove suffix */
		scan_srec_file(filename);
	}
	else scan_Intel_file(filename);
}


void global_options(int argc, char *argv[])
{
   int iarg;
   char *cp;
   char *tp;
   char ch;

   h2b = false;
   rom_size = ONE_MEG;     /* bin2hex default value */
/* decide which conversion to do */
   if (strstr(argv[0],"hex2bin")
#ifdef   MSDOS
         || strstr(argv[0],"HEX2BIN")
#endif
      ) {
         h2b = true;
         rom_size = 64 * 1024ul; /* default value */
   }  /* assume 'bin2hex' otherwise */
      
   if (argc<2) { usage(); exit(0); }

/* scan the global command line options */
   for (iarg = 0; iarg<argc; iarg++) {
      cp = argv[iarg];
      if (*cp == '-'
#ifdef   MSDOS
                  || *cp == '/'
#endif
                                 ) {
         ch = cp[1];
         tp = cp + 2;
         switch (ch) {
            case 'g':
               segmented = 1;    /* enable segmented addressing */
               break;            /* for ROMs <= 1M in size      */
            case 'h':
               usage();
               exit(0);
            case 'o':   /* outfile name specification */
               if (!*tp) tp = argv[++iarg];
               outfilename = strdup(tp);
               *cp = *tp = 0;
               break;
            case 'p':   /* specify the pad byte */
               if (!*tp) tp = argv[++iarg];
               pad = (byte)convert_constant(tp);
               *cp = *tp = 0;
               break;
            case 'R':   /* ROM file size specification */
               if (!*tp) tp = argv[++iarg];
               rom_size = convert_constant(tp);
               if (rom_size > MAX_MASK+1) error(5, "ROM size too big");
               if (rom_size < 256) error(5, "ROM size too small");
               *cp = *tp = 0;
               break;
            case 'v':   /* print verbose statistics */
               verbose++;
               if (!*tp) tp = argv[++iarg];
               if (*tp>='1' && *tp<='5' && tp[1]==0) verbose += (*tp - '1');
               else tp = cp;
               *cp = *tp = 0;
               break;
            case 'Y': {
                  int i;
                  for (i=0; i<argc; i++)
                     printf(" %s", argv[i]);
                  printf("\n");
                  exit(0);
               }
            default:
               break;
         }
      }  // if '-'
   }  // for (iarg ...
}


void process_cmd_input(int argc, char *argv[])
{
   int iarg;
   char *cp;
   char *tp;

   source_address = dest_address = 0;
   source_limit = dest_limit = MAX_MASK;

   for (iarg=1; iarg<argc; iarg++) {
      cp = argv[iarg];
      if (*cp == '-'
#ifdef   MSDOS
                  || *cp == '/'
#endif
                                 ) {
         ++cp;
         tp = cp + 1;
         switch (*cp) {
            case 's':            /* source */
               if (!*tp) tp = argv[++iarg];
               source_address = convert_constant(tp);
               break;
            case 'S':            /* source limit */
               if (!*tp) tp = argv[++iarg];
               source_limit = convert_constant(tp);
               break;
            case 'd':            /* destination */
               if (!*tp) tp = argv[++iarg];
               dest_address = convert_constant(tp);
               break;
            case 'D':            /* destination limit */
               if (!*tp) tp = argv[++iarg];
               dest_limit = convert_constant(tp) - 1;
               break;
         } // switch
      }  // if (*cp == '-' ...
      else if (*cp) {            /* this must be a filename */
         if (h2b) scan_hex_file(cp);
         else scan_bin_file(cp);

      /* reset the local relocation options */
         source_address = 0;
         dest_address = 0;
         source_limit = MAX_MASK;
         dest_limit = MAX_MASK;
      }
   } // for (iarg
}



int main(int argc, char *argv[])
{
   dword index;
   byte *ptr;

   verbose = 0;
   global_options(argc, argv);
   
   buffer = malloc(rom_size);
   if (!buffer) error(5,"Cannot allocate ROM buffer");
   for (ptr=buffer, index=rom_size; index; index--) *ptr++ = pad;

   process_cmd_input(argc, argv);

   if (!outfilename) {
      if (h2b) {
         outfilename = "out.bin";
      }
      else {
         outfilename = "out.hex";
      }
      error(1,"No output file specified");
      printf("Using file named '%s' for output\n", outfilename);
   }
   outfile = fopen(outfilename, h2b ? "wb" : "wt");
   if (!outfile) error(5,"Cannot create output file");

   if (h2b) while (rom_size--) fputc(*buffer++, outfile);
   else write_hex_file(outfile);

   fclose(outfile);

   return EXIT_SUCCESS;
}

