/* Emulation of the Z80 CPU with hooks into the other parts of xz80.
 * Copyright (C) 1994 Ian Collier.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include<stdio.h>
#include "zxcc.h"

#define parity(a) (partable[a])

unsigned char partable[256]={
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
      4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
   };

#ifdef DEBUG
// Avoid name conflict with built-in log math function
#define log z80_log

static unsigned short breakpoint=0;
static unsigned int breaks=0;

static void inline log(fp,name,val)
FILE *fp;
char *name;
unsigned short val;
{
   int i;
   fprintf(fp,"%s=%04X ",name,val);
   for(i=0;i<8;i++,val++)fprintf(fp," %02X",fetch(val));
   putc('\n',fp);
}
#endif

void mainloop(word spc, word ssp){
   register unsigned char a, f, b, c, d, e, h, l;
   unsigned char r, a1, f1, b1, c1, d1, e1, h1, l1, i, iff1, iff2, im;
   register unsigned short pc;
   unsigned short ix, iy, sp;
   register unsigned long tstates;
   register unsigned int radjust;
   register unsigned char ixoriy, new_ixoriy;
   unsigned char intsample;
   register unsigned char op;
#ifdef DEBUG
   char flags[9];
   int bit;
   FILE *fp=0;
   register unsigned short af2=0,bc2=0,de2=0,hl2=0,ix2=0,iy2=0,sp2=0;
   register unsigned char i2=0;
   /*unsigned char *memory=memptr[0];*/
   struct _next {unsigned char bytes[8];} *next;
   unsigned short BC, DE, HL, AF;

   fputs("Press F11 to log\n",stderr);
#endif
   a=f=b=c=d=e=h=l=a1=f1=b1=c1=d1=e1=h1=l1=i=r=iff1=iff2=im=0;
   ixoriy=new_ixoriy=0;
   ix=iy=0;
   pc=spc;
   sp=ssp;
   tstates=radjust=0;
   while(1){
      ixoriy=new_ixoriy;
      new_ixoriy=0;
#ifdef DEBUG
      next=(struct _next *)&fetch(pc);
      BC=bc;DE=de;HL=hl;AF=(a<<8)|f;
      if(fp && !ixoriy){
         log(fp,"pc",pc);
         if(sp!=sp2)log(fp,"sp",sp2=sp);
         if(iy!=iy2)log(fp,"iy",iy2=iy);
         if(ix!=ix2)log(fp,"ix",ix2=ix);
         if(hl!=hl2)log(fp,"hl",hl2=hl);
         if(de!=de2)log(fp,"de",de2=de);
         if(bc!=bc2)log(fp,"bc",bc2=bc);
         if(((a<<8)|f)!=af2){
            af2=(a<<8)|f;
            strcpy(flags,"SZ H VNC");
            for(bit=0;bit<8;bit++)if(!(f&(1<<(7-bit))))flags[bit]=' ';
            fprintf(fp,"af=%04X  %s\n",af2,flags);
         }
         if(i!=i2)fprintf(fp,"ir=%02X%02X\n",i2=i,r);
         putc('\n',fp);
      }
      if(pc==breakpoint && pc)
         breaks++; /* some code at which to set a breakpoint */
      a=AF>>8; f=AF; h=HL>>8; l=HL; d=DE>>8; e=DE; b=BC>>8; c=BC;
#endif
/*
{
                static int tr = 1;
                static int id = 0;
//              static byte b = 0;
//
//		if (pc == 0x1177) tr = 1;
 //               if (pc == 0x1185) tr = 0;
	if (tr >= 1) ++id;
        if (tr >= 1) printf("%d: PC=%04x %02x AF=%02x:%02x BC=%04x DE=%04x HL=%04x IX=%04x IY=%04x\n",
                        id, pc, fetch(pc), a,f, bc, de, hl, ix, iy);
}
*/
      intsample=1;
      op=fetch(pc);
      pc++;
      radjust++;
      switch(op){
#include "z80ops.h"
      }
/***
 * ZXCC doesn't do interrupts at all, so all this is commented out 
      if(tstates>=int_cycles && intsample){
         tstates-=int_cycles;
         frames++;
         // Carry out X-related tasks (including waiting for timer
         //  signal if necessary) 
         switch(interrupt()){
            case Z80_quit:
#ifdef DEBUG
               if(fp)fclose(fp);
#endif
               return;
            case Z80_NMI:
               if(fetch(pc)==0x76)pc++;
               iff2=iff1;
               iff1=0;
               // The Z80 performs a machine fetch cycle for 5 Tstates
               // but ignores the result.  It takes a further 10 Tstates
               // to jump to the NMI routine at 0x66. 
               tstates+=15;
               push2(pc);
               pc=0x66;
               break;
            case Z80_reset:
               a=f=b=c=d=e=h=l=a1=f1=b1=c1=d1=e1=
                 h1=l1=i=r=iff1=iff2=im=0;
               ix=iy=sp=pc=0;
               radjust=0;
               break;
#ifdef DEBUG
            case Z80_log:
               if(fp){
                  fclose(fp);
                  fp=0;
                  fputs("Logging turned off\n",stderr);
               } else {
                  fp=fopen(config.log,"a");
                  if(fp)fprintf(stderr,"Logging to file %s\n",config.log);
                  else perror(config.log);
               }
               break;
#endif

            case Z80_load:
               stopwatch();
               if(snapload()){
                  a=snapa;
                  f=snapf;
                  b=snapb;
                  c=snapc;
                  d=snapd;
                  e=snape;
                  h=snaph;
                  l=snapl;
                  a1=snapa1;
                  f1=snapf1;
                  b1=snapb1;
                  c1=snapc1;
                  d1=snapd1;
                  e1=snape1;
                  h1=snaph1;
                  l1=snapl1;
                  iff1=snapiff1;
                  iff2=snapiff2;
                  i=snapi;
                  r=snapr;
                  radjust=r;
                  im=snapim;
                  ix=snapix;
                  iy=snapiy;
                  sp=snapsp;
                  pc=snappc;
               }
               startwatch(1);
               break;
            case Z80_save:
               r=(r&0x80)|(radjust&0x7f);
               snapa=a;
               snapf=f;
               snapb=b;
               snapc=c;
               snapd=d;
               snape=e;
               snaph=h;
               snapl=l;
               snapa1=a1;
               snapf1=f1;
               snapb1=b1;
               snapc1=c1;
               snapd1=d1;
               snape1=e1;
               snaph1=h1;
               snapl1=l1;
               snapiff1=iff1;
               snapiff2=iff2;
               snapi=i;
               snapr=r;
               snapim=im;
               snapix=ix;
               snapiy=iy;
               snapsp=sp;
               snappc=pc;
               snapsave();
               startwatch(1);
               break;

         }
         if(iff1){
#ifdef DEBUG
            if(fp)fprintf(fp,"Interrupt (im=%d)\n\n",im);
#endif
            if(fetch(pc)==0x76)pc++;
            iff1=iff2=0;
            tstates+=5; // accompanied by an input from the data bus //
            switch(im){
               case 0: // IM 0 //
               case 1: // undocumented //
               case 2: // IM 1 //
                  // there is little to distinguish between these cases //
                  tstates+=8;
                  push2(pc);
                  pc=0x38;
                  break;
               case 3: // IM 2 //
                  tstates+=14;
                  {
                     int addr=fetch2((i<<8)|0xff);
                     push2(pc);
                     pc=addr;
                  }
            }
         }
      }*/
   }
}
