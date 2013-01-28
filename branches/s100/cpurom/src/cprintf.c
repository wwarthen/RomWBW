/* Copyright (C) 1996 Robert de Bath <robert@mayday.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* Modified 14-Jan-2002 by John Coffman <johninsd@san.rr.com> for inclusion
 * in the set of LILO diagnostics.  This code is the property of Robert
 * de Bath, and is used with his permission.
 */

/* Modified 14-Sep-2010 by John Coffman <johninsd@gmail.com> for use with
 * the N8VEM SBC-188 BIOS project.
 */
#include <stdlib.h>
#include <stdarg.h>

#undef printf
#define ASM_CVT 0
#ifndef strlen
int strlen(char *s);
#endif

void outchar(char ch);
#define putch(ch) outchar((char)ch)


#ifndef NULL
# define NULL ((void*)0L)
#endif

#define __fastcall
#define NUMLTH 11
static unsigned char * __fastcall __numout(long i, int base, unsigned char out[]);

int cprintf(const char * fmt, ...)
{
   register int c;
   int count = 0;
   int type, base;
   long val;
   char * cp;
   char padch=' ';
   int  minsize, maxsize;
   unsigned char out[NUMLTH+1];
   va_list ap;

   va_start(ap, fmt);

   while(c=*fmt++)
   {
      count++;
      if(c!='%')
      {
	 if (c=='\n') putch('\r');
	 putch(c);
      }
      else
      {
	 type=1;
	 padch = *fmt;
	 maxsize=minsize=0;
	 if(padch == '-') fmt++;

	 for(;;)
	 {
	    c=*fmt++;
	    if( c<'0' || c>'9' ) break;
	    minsize*=10; minsize+=c-'0';
	 }

	 if( c == '.' )
	    for(;;)
	    {
	       c=*fmt++;
	       if( c<'0' || c>'9' ) break;
	       maxsize*=10; maxsize+=c-'0';
	    }

	 if( padch == '-' ) minsize = -minsize;
	 else
	 if( padch != '0' ) padch=' ';

	 if( c == 0 ) break;
	 if(c=='h')
	 {
	    c=*fmt++;
	    type = 0;
	 }
	 else if(c=='l')
	 {
	    c=*fmt++;
	    type = 2;
	 }

	 switch(c)
	 {
       case 'X':
	    case 'x': base=16; type |= 4;   if(0) {
	    case 'o': base= 8; type |= 4; } if(0) {
	    case 'u': base=10; type |= 4; } if(0) {
	    case 'd': base=-10; }
	       switch(type)
	       {
		  case 0: val=va_arg(ap, short); break; 
		  case 1: val=va_arg(ap, int);   break;
		  case 2: val=va_arg(ap, long);  break;
		  case 4: val=va_arg(ap, unsigned short); break; 
		  case 5: val=va_arg(ap, unsigned int);   break;
		  case 6: val=va_arg(ap, unsigned long);  break;
		  default:val=0; break;
	       }
	       cp = __numout(val,base,out);
	       if(0) {
	    case 's':
	          cp=va_arg(ap, char *);
	       }
	       count--;
	       c = strlen(cp);
	       if( !maxsize ) maxsize = c;
	       if( minsize > 0 )
	       {
		  minsize -= c;
		  while(minsize>0) { putch(padch); count++; minsize--; }
		  minsize=0;
	       }
	       if( minsize < 0 ) minsize= -minsize-c;
	       while(*cp && maxsize-->0 )
	       {
		  putch(*cp++);
		  count++;
	       }
	       while(minsize>0) { putch(' '); count++; minsize--; }
	       break;
	    case 'c':
	       putch(va_arg(ap, int));
	       break;
	    default:
	       putch(c);
	       break;
	 }
      }
   }
   va_end(ap);
   return count;
}

const char nstring[]="0123456789ABCDEF";

#if ASM_CVT==0

static unsigned char *
__fastcall
__numout(long i, int base, unsigned char *out)
{
   int n;
   int flg = 0;
   unsigned long val;

   if (base<0)
   {
      base = -base;
      if (i<0)
      {
      	 flg = 1;
      	 i = -i;
      }
   }
   val = i;

   out[NUMLTH] = '\0';
   n = NUMLTH-1;
   do
   {
#if 1
      out[n] = nstring[val % base];
      val /= base;
      --n;
#else
      out[n--] = nstring[remLS(val,base)];
      val = divLS(val,base);
#endif
   }
   while(val);
   if(flg) out[n--] = '-';
   
   return &out[n+1];
}
#else

#asm
! numout.s
!
#if 0
.data
_nstring:
.ascii	"0123456789ABCDEF"
.byte	0
#endif

.bss
___out	lcomm	$C

.text
___numout:
push	bp
mov	bp,sp
push	di
push	si
add	sp,*-4
mov	byte ptr -8[bp],*$0	! flg = 0
mov	si,4[bp]	; i or val.lo
mov	di,6[bp]	; i or val.hi
mov	cx,8[bp]	; base
test	cx,cx			! base < 0 ?
jge 	.3num
neg  cx				! base = -base
or	di,di			! i < 0 ?
jns	.5num
mov	byte ptr -8[bp],*1	! flg = 1
neg	di			! i = -i
neg	si
sbb	di,*0
.5num:
.3num:
mov	byte ptr [___out+$B],*$0	! out[11] = nul
mov	-6[bp],*$A		! n = 10

.9num:
!!!         out[n--] = nstring[val % base];
xor  dx,dx
xchg ax,di
div  cx
xchg ax,di
xchg ax,si
div  cx
xchg ax,si			! val(new) = val / base

mov  bx,dx			! dx = val % base

mov	al,_nstring[bx]
mov	bx,-6[bp]
dec	word ptr -6[bp]
mov	___out[bx],al

mov  ax,si
or   ax,di			! while (val)
jne	.9num

cmp	byte ptr -8[bp],*$0	! flg == 0 ?
je  	.Dnum

mov	bx,-6[bp]
dec	word ptr -6[bp]
mov	byte ptr ___out[bx],*$2D	! out[n--] = minus

.Dnum:
mov	ax,-6[bp]
add	ax,#___out+1

add	sp,*4
pop	si
pop	di
pop	bp
ret
#endasm

#endif
