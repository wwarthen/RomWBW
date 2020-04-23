/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "getopt_.h"
#include "cpmdir.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/
/* #defines */ /*{{{*/
/* your favourite password *:-) */

#define T0 'G'
#define T1 'E'
#define T2 'H'
#define T3 'E'
#define T4 'I'
#define T5 'M'
#define T6 ' '
#define T7 ' '

#define PB ((char)(T0+T1+T2+T3+T4+T5+T6+T7))
#define P0 ((char)(T7^PB))
#define P1 ((char)(T6^PB))
#define P2 ((char)(T5^PB))
#define P3 ((char)(T4^PB))
#define P4 ((char)(T3^PB))
#define P5 ((char)(T2^PB))
#define P6 ((char)(T1^PB))
#define P7 ((char)(T0^PB))
/*}}}*/

/* types */ /*{{{*/
enum Result { OK=0, MODIFIED=1, BROKEN=2 };
/*}}}*/
/* variables */ /*{{{*/
static int norepair=0;
/*}}}*/

/* bcdCheck -- check format and range of BCD digit */ /*{{{*/
static int bcdCheck(int n, int max, const char *msg, const char *unit, int extent1, int extent2)
{
  if (((n>>4)&0xf)>10 || (n&0xf)>10 || (((n>>4)&0xf)*10+(n&0xf))>=max)
  {
    printf("Error: Bad %s %s (extent=%d/%d, %s=%02x)\n",msg,unit,extent1,extent2,unit,n&0xff);
    return -1;
  }
  else return 0;
}
/*}}}*/
/* pwdCheck -- check password */ /*{{{*/
static int pwdCheck(int extent, const char *pwd, char decode)
{
  char c;
  int i;

  for (i=0; i<8; ++i) if ((c=((char)(pwd[7-i]^decode)))<' ' || c&0x80)
  {
    printf("Error: non-printable character in password (extent=%d, password=",extent);
    for (i=0; i<8; ++i)
    {
      c=pwd[7-i]^decode;
      if (c<' ' || c&0x80)
      {
        putchar('\\'); putchar('0'+((c>>6)&0x01));
        putchar('0'+((c>>3)&0x03));
        putchar('0'+(c&0x03));
      }
      else putchar(c);
    }
    printf(")\n");
    return -1;
  }
  return 0;
}
/*}}}*/
/* ask -- ask user and return answer */ /*{{{*/
static int ask(const char *msg)
{
  while (1)
  {
    char buf[80];

    if (norepair) return 0;
    printf("%s [Y]? ",msg); fflush(stdout);
    if (fgets(buf,sizeof(buf),stdin)==(char*)0) exit(1);
    switch (toupper(buf[0]))
    {
      case '\n':
      case 'Y': return 1;
      case 'N': return 0;
    }
  }
}
/*}}}*/
/* prfile -- print file name */ /*{{{*/
static char *prfile(struct cpmSuperBlock *sb, int extent)
{
  struct PhysDirectoryEntry *dir;
  static char name[80];
  char *s=name;
  int i;
  char c;

  dir=sb->dir+extent;
  for (i=0; i<8; ++i)
  {
    c=dir->name[i];
    if ((c&0x7f)<' ')
    {
      *s++='\\'; *s++=('0'+((c>>6)&0x01));
      *s++=('0'+((c>>3)&0x03));
      *s++=('0'+(c&0x03));
    }
    else *s++=(c&0x7f);
  }
  *s++='.';
  for (i=0; i<3; ++i)
  {
    c=dir->ext[i];
    if ((c&0x7f)<' ')
    {
      *s++='\\'; *s++=('0'+((c>>6)&0x01));
      *s++=('0'+((c>>3)&0x03));
      *s++=('0'+(c&0x03));
    }
    else *s++=(c&0x7f);
  }
  *s='\0';
  return name;
}
/*}}}*/
/* fsck -- file system check */ /*{{{*/
static int fsck(struct cpmInode *root, const char *image)
{
  /* variables */ /*{{{*/
  enum Result ret=OK;
  int extent,extent2;
  struct PhysDirectoryEntry *dir,*dir2;
  struct cpmSuperBlock *sb=root->sb;
  /*}}}*/

  /* Phase 1: check extent fields */ /*{{{*/
  printf("Phase 1: check extent fields\n");
  for (extent=0; extent<sb->maxdir; ++extent)
  {
    char *status;
    int usedBlocks=0;

    dir=sb->dir+extent;
    status=&dir->status;
    if (*status>=0 && *status<=(sb->type==CPMFS_P2DOS ? 31 : 15)) /* directory entry */ /*{{{*/
    {
      /* check name and extension */ /*{{{*/
      {
        int i;
        char *c;

        for (i=0; i<8; ++i)
        {
          c=&(dir->name[i]);
          if (!ISFILECHAR(i,*c&0x7f) || islower(*c&0x7f))
          {
            printf("Error: Bad name (extent=%d, name=\"%s\", position=%d)\n",extent,prfile(sb,extent),i);
            if (ask("Remove file"))
            {
              *status=(char)0xE5;
              ret|=MODIFIED;
              break;
            }
            else ret|=BROKEN;
          }
        }
        if (*status==(char)0xe5) continue;
        for (i=0; i<3; ++i)
        {
          c=&(dir->ext[i]);
          if (!ISFILECHAR(1,*c&0x7f) || islower(*c&0x7f))
          {
            printf("Error: Bad name (extent=%d, name=\"%s\", position=%d)\n",extent,prfile(sb,extent),i);
            if (ask("Remove file"))
            {
              *status=(char)0xE5;
              ret|=MODIFIED;
              break;
            }
            else ret|=BROKEN;
          }
        }
        if (*status==(char)0xe5) continue;
      }
      /*}}}*/
      /* check extent number */ /*{{{*/
      if ((dir->extnol&0xff)>0x1f)
      {
        printf("Error: Bad lower bits of extent number (extent=%d, name=\"%s\", low bits=%d)\n",extent,prfile(sb,extent),dir->extnol&0xff);
        if (ask("Remove file"))
        {
          *status=(char)0xE5;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
      if (*status==(char)0xe5) continue;
      if ((dir->extnoh&0xff)>0x3f)
      {
        printf("Error: Bad higher bits of extent number (extent=%d, name=\"%s\", high bits=%d)\n",extent,prfile(sb,extent),dir->extnoh&0xff);
        if (ask("Remove file"))
        {
          *status=(char)0xE5;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
      if (*status==(char)0xe5) continue;
      /*}}}*/
      /* check last record byte count */ /*{{{*/
      if ((dir->lrc&0xff)>128)
      {
        printf("Error: Bad last record byte count (extent=%d, name=\"%s\", lrc=%d)\n",extent,prfile(sb,extent),dir->lrc&0xff);
        if (ask("Clear last record byte count"))
        {
          dir->lrc=(char)0;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
      if (*status==(char)0xe5) continue;
      /*}}}*/
      /* check block number range */ /*{{{*/
      {
        int block,min,max,i;

        min=(sb->maxdir*32+sb->blksiz-1)/sb->blksiz;
        max=sb->size;
        for (i=0; i<16; ++i)
        {
          block=dir->pointers[i]&0xff;
          if (sb->size>=256) block+=(dir->pointers[++i]&0xff)<<8;
          if (block>0)
          {
            ++usedBlocks;
            if (block<min || block>=max)
            {
              printf("Error: Bad block number (extent=%d, name=\"%s\", block=%d)\n",extent,prfile(sb,extent),block);
              if (ask("Remove file"))
              {
                *status=(char)0xE5;
                ret|=MODIFIED;
                break;
              }
              else ret|=BROKEN;
            }
          }
        }
        if (*status==(char)0xe5) continue;
      }
      /*}}}*/
      /* check number of used blocks ? */ /*{{{*/
      /*}}}*/
      /* check record count */ /*{{{*/
      {
        int i,min,max,recordsInBlocks,used=0;

        min=(dir->extnol%sb->extents)*16/sb->extents;
        max=((dir->extnol%sb->extents)+1)*16/sb->extents;
        assert(min<max);
        for (i=min; i<max; ++i)
        {
        /* [JCE] Rewritten because the previous implementation didn't work
         *       properly with Visual C++ */
          if (dir->pointers[i] || (sb->size>=256 && dir->pointers[i+1])) ++used;
          if (sb->size >= 256) ++i;
        }
        recordsInBlocks=(((unsigned char)dir->blkcnt)*128+sb->blksiz-1)/sb->blksiz;
        if (recordsInBlocks!=used)
        {
          printf("Error: Bad record count (extent=%d, name=\"%s\", record count=%d)\n",extent,prfile(sb,extent),dir->blkcnt&0xff);
          if (ask("Remove file"))
          {
            *status=(char)0xE5;
            ret|=MODIFIED;
          }
          else ret|=BROKEN;
        }
        if (*status==(char)0xe5) continue;
      }
      /*}}}*/
      /* check for too large .com files */ /*{{{*/
      if (((EXTENT(dir->extnol,dir->extnoh)==3 && dir->blkcnt>=126) || EXTENT(dir->extnol,dir->extnoh)>=4) && (dir->ext[0]&0x7f)=='C' && (dir->ext[1]&0x7f)=='O' && (dir->ext[2]&0x7f)=='M')
      {
        printf("Warning: Oversized .COM file (extent=%d, name=\"%s\")\n",extent,prfile(sb,extent));
      }
      /*}}}*/
    }
    /*}}}*/
    else if ((sb->type==CPMFS_P2DOS || sb->type==CPMFS_DR3) && *status==33) /* check time stamps ? */ /*{{{*/
    {
      unsigned long created,modified;
      char s;

      if ((s=sb->dir[extent2=(extent&~3)].status)>=0 && s<=(sb->type==CPMFS_P2DOS ? 31 : 15)) /* time stamps for first of the three extents */ /*{{{*/
      {
        bcdCheck(dir->name[2],24,sb->cnotatime ? "creation date" : "access date","hour",extent,extent2);
        bcdCheck(dir->name[3],60,sb->cnotatime ? "creation date" : "access date","minute",extent,extent2);
        bcdCheck(dir->name[6],24,"modification date","hour",extent,extent2);
        bcdCheck(dir->name[7],60,"modification date","minute",extent,extent2);
        created=(dir->name[4]+(dir->name[1]<<8))*(0x60*0x60)+dir->name[2]*0x60+dir->name[3];
        modified=(dir->name[0]+(dir->name[5]<<8))*(0x60*0x60)+dir->name[6]*0x60+dir->name[7];
        if (sb->cnotatime && modified<created)
        {
          printf("Warning: Modification date earlier than creation date (extent=%d/%d)\n",extent,extent2);
        }
      }
      /*}}}*/
      if ((s=sb->dir[extent2=(extent&~3)+1].status)>=0 && s<=(sb->type==CPMFS_P2DOS ? 31 : 15)) /* time stamps for second */ /*{{{*/
      {
        bcdCheck(dir->lrc,24,sb->cnotatime ? "creation date" : "access date","hour",extent,extent2);
        bcdCheck(dir->extnoh,60,sb->cnotatime ? "creation date" : "access date","minute",extent,extent2);
        bcdCheck(dir->pointers[1],24,"modification date","hour",extent,extent2);
        bcdCheck(dir->pointers[2],60,"modification date","minute",extent,extent2);
        created=(dir->ext[2]+(dir->extnol<<8))*(0x60*0x60)+dir->lrc*0x60+dir->extnoh;
        modified=(dir->blkcnt+(dir->pointers[0]<<8))*(0x60*0x60)+dir->pointers[1]*0x60+dir->pointers[2];
        if (sb->cnotatime && modified<created)
        {
          printf("Warning: Modification date earlier than creation date (extent=%d/%d)\n",extent,extent2);
        }
      }
      /*}}}*/
      if ((s=sb->dir[extent2=(extent&~3)+2].status)>=0 && s<=(sb->type==CPMFS_P2DOS ? 31 : 15)) /* time stamps for third */ /*{{{*/
      {
        bcdCheck(dir->pointers[7],24,sb->cnotatime ? "creation date" : "access date","hour",extent,extent2);
        bcdCheck(dir->pointers[8],60,sb->cnotatime ? "creation date" : "access date","minute",extent,extent2);
        bcdCheck(dir->pointers[11],24,"modification date","hour",extent,extent2);
        bcdCheck(dir->pointers[12],60,"modification date","minute",extent,extent2);
        created=(dir->pointers[5]+(dir->pointers[6]<<8))*(0x60*0x60)+dir->pointers[7]*0x60+dir->pointers[8];
        modified=(dir->pointers[9]+(dir->pointers[10]<<8))*(0x60*0x60)+dir->pointers[11]*0x60+dir->pointers[12];
        if (sb->cnotatime && modified<created)
        {
          printf("Warning: Modification date earlier than creation date (extent=%d/%d)\n",extent,extent2);
        }
      }
      /*}}}*/
    }
    /*}}}*/
    else if (sb->type==CPMFS_DR3 && *status==32) /* disc label */ /*{{{*/
    {
      unsigned long created,modified;

      bcdCheck(dir->pointers[10],24,sb->cnotatime ? "creation date" : "access date","hour",extent,extent);
      bcdCheck(dir->pointers[11],60,sb->cnotatime ? "creation date" : "access date","minute",extent,extent);
      bcdCheck(dir->pointers[14],24,"modification date","hour",extent,extent);
      bcdCheck(dir->pointers[15],60,"modification date","minute",extent,extent);
      created=(dir->pointers[8]+(dir->pointers[9]<<8))*(0x60*0x60)+dir->pointers[10]*0x60+dir->pointers[11];
      modified=(dir->pointers[12]+(dir->pointers[13]<<8))*(0x60*0x60)+dir->pointers[14]*0x60+dir->pointers[15];
      if (sb->cnotatime && modified<created)
      {
        printf("Warning: Label modification date earlier than creation date (extent=%d)\n",extent);
      }
      if (dir->extnol&0x40 && dir->extnol&0x10)
      {
        printf("Error: Bit 4 and 6 can only be exclusively be set (extent=%d, label byte=0x%02x)\n",extent,(unsigned char)dir->extnol);
        if (ask("Time stamp on creation"))
        {
          dir->extnol&=~0x40;
          ret|=MODIFIED;
        }
        else if (ask("Time stamp on access"))
        {
          dir->extnol&=~0x10;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
      if (dir->extnol&0x80 && pwdCheck(extent,dir->pointers,dir->lrc))
      {
        char msg[80];

        sprintf(msg,"Set password to %c%c%c%c%c%c%c%c",T0,T1,T2,T3,T4,T5,T6,T7);
        if (ask(msg))
        {
          dir->pointers[0]=P0;
          dir->pointers[1]=P1;
          dir->pointers[2]=P2;
          dir->pointers[3]=P3;
          dir->pointers[4]=P4;
          dir->pointers[5]=P5;
          dir->pointers[6]=P6;
          dir->pointers[7]=P7;
          dir->lrc=PB;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
    }
    /*}}}*/
    else if (sb->type==CPMFS_DR3 && *status>=16 && *status<=31) /* password */ /*{{{*/
    {
      /* check name and extension */ /*{{{*/
      {
        int i;
        char *c;

        for (i=0; i<8; ++i)
        {
          c=&(dir->name[i]);
          if (!ISFILECHAR(i,*c&0x7f) || islower(*c&0x7f))
          {
            printf("Error: Bad name (extent=%d, name=\"%s\", position=%d)\n",extent,prfile(sb,extent),i);
            if (ask("Clear password entry"))
            {
              *status=(char)0xE5;
              ret|=MODIFIED;
              break;
            }
            else ret|=BROKEN;
          }
        }
        if (*status==(char)0xe5) continue;
        for (i=0; i<3; ++i)
        {
          c=&(dir->ext[i]);
          if (!ISFILECHAR(1,*c&0x7f) || islower(*c&0x7f))
          {
            printf("Error: Bad name (extent=%d, name=\"%s\", position=%d)\n",extent,prfile(sb,extent),i);
            if (ask("Clear password entry"))
            {
              *status=(char)0xE5;
              ret|=MODIFIED;
              break;
            }
            else ret|=BROKEN;
          }
        }
        if (*status==(char)0xe5) continue;
      }
      /*}}}*/
      /* check password */ /*{{{*/
      if (dir->extnol&(0x80|0x40|0x20) && pwdCheck(extent,dir->pointers,dir->lrc))
      {
        char msg[80];

        sprintf(msg,"Set password to %c%c%c%c%c%c%c%c",T0,T1,T2,T3,T4,T5,T6,T7);
        if (ask(msg))
        {
          dir->pointers[0]=P0;
          dir->pointers[1]=P1;
          dir->pointers[2]=P2;
          dir->pointers[3]=P3;
          dir->pointers[4]=P4;
          dir->pointers[5]=P5;
          dir->pointers[6]=P6;
          dir->pointers[7]=P7;
          dir->lrc=PB;
          ret|=MODIFIED;
        }
        else ret|=BROKEN;
      }
      /*}}}*/
    }
    /*}}}*/
    else if (*status!=(char)0xe5) /* bad status */ /*{{{*/
    {
      printf("Error: Bad status (extent=%d, name=\"%s\", status=0x%02x)\n",extent,prfile(sb,extent),*status&0xff);
      if (ask("Clear entry"))
      {
        *status=(char)0xE5;
        ret|=MODIFIED;
      }
      else ret|=BROKEN;
      continue;
    }
    /*}}}*/
  }
  /*}}}*/
  /* Phase 2: check extent connectivity */ /*{{{*/
  printf("Phase 2: check extent connectivity\n");
  /* check multiple allocated blocks */ /*{{{*/
  for (extent=0; extent<sb->maxdir; ++extent) if ((dir=sb->dir+extent)->status>=0 && dir->status<=(sb->type==CPMFS_P2DOS ? 31 : 15))
  {
    int i,j,block,block2;

    for (i=0; i<16; ++i)
    {
      block=dir->pointers[i]&0xff;
      if (sb->size>=256) block+=(dir->pointers[++i]&0xff)<<8;
      for (extent2=0; extent2<sb->maxdir; ++extent2) if ((dir2=sb->dir+extent2)->status>=0 && dir2->status<=(sb->type==CPMFS_P2DOS ? 31 : 15))
      {
        for (j=0; j<16; ++j)
        {
          block2=dir2->pointers[j]&0xff;
          if (sb->size>=256) block2+=(dir2->pointers[++j]&0xff)<<8;
          if (block!=0 && block2!=0 && block==block2 && !(extent==extent2 && i==j))
          {
            printf("Error: Multiple allocated block (extent=%d,%d, name=\"%s\"",extent,extent2,prfile(sb,extent));
            printf(",\"%s\" block=%d)\n",prfile(sb,extent2),block);
            ret|=BROKEN;
          }
        }
      }
    }
  }
  /*}}}*/
  /* check multiple extents */ /*{{{*/
  for (extent=0; extent<sb->maxdir; ++extent) if ((dir=sb->dir+extent)->status>=0 && dir->status<=(sb->type==CPMFS_P2DOS ? 31 : 15))
  {
    for (extent2=0; extent2<sb->maxdir; ++extent2) if ((dir2=sb->dir+extent2)->status>=0 && dir2->status<=(sb->type==CPMFS_P2DOS ? 31 : 15))
    {
      if (extent!=extent2 && EXTENT(dir->extnol,dir->extnoh)==EXTENT(dir2->extnol,dir2->extnoh) && dir->status==dir2->status)
      {
        int i;

        for (i=0; i<8 && (dir->name[i]&0x7f)==(dir2->name[i]&0x7f); ++i);
        if (i==8)
        {
          for (i=0; i<3 && (dir->ext[i]&0x7f)==(dir2->ext[i]&0x7f); ++i);
          if (i==3)
          {
            printf("Error: Duplicate extent (extent=%d,%d)\n",extent,extent2);
            ret|=BROKEN;
          }
        }
      }
    }
  }
  /*}}}*/
  /*}}}*/
  if (ret==0) /* print statistics */ /*{{{*/
  {
    struct cpmStatFS statfsbuf;
    int fragmented=0,borders=0;

    cpmStatFS(root,&statfsbuf);
    for (extent=0; extent<sb->maxdir; ++extent) if ((dir=sb->dir+extent)->status>=0 && dir->status<=(sb->type==CPMFS_P2DOS ? 31 : 15))
    {
      int i,block,previous=-1;

      for (i=0; i<16; ++i)
      {
        block=dir->pointers[i]&0xff;
        if (sb->size>=256) block+=(dir->pointers[++i]&0xff)<<8;
        if (previous!=-1)
        {
          if (block!=0 && block!=(previous+1)) ++fragmented;
          ++borders;
        }
        previous=block;
      }
    }
    fragmented=(borders ? (1000*fragmented)/borders : 0);
    printf("%s: %ld/%ld files (%d.%d%% non-contigous), %ld/%ld blocks\n",image,statfsbuf.f_files-statfsbuf.f_ffree,statfsbuf.f_files,fragmented/10,fragmented%10,statfsbuf.f_blocks-statfsbuf.f_bfree,statfsbuf.f_blocks);
  }
  /*}}}*/
  return ret;
}
/*}}}*/

const char cmd[]="fsck.cpm";

/* main */ /*{{{*/
int main(int argc, char *argv[])
{
  const char *err;
  const char *image;
  const char *format;
  const char *devopts=NULL;
  int c,usage=0;
  struct cpmSuperBlock sb;
  struct cpmInode root;
  enum Result ret;

  if (!(format=getenv("CPMTOOLSFMT"))) format=FORMAT;
  while ((c=getopt(argc,argv,"T:f:nh?"))!=EOF) switch(c)
  {
    case 'f': format=optarg; break;
    case 'T': devopts=optarg; break;
    case 'n': norepair=1; break;
    case 'h':
    case '?': usage=1; break;
  }

  if (optind!=(argc-1)) usage=1;
  else image=argv[optind++];

  if (usage)
  {
    fprintf(stderr,"Usage: %s [-f format] [-n] image\n",cmd);
    exit(1);
  }
  if ((err=Device_open(&sb.dev, image, (norepair ? O_RDONLY : O_RDWR), devopts)))
  {
    if ((err=Device_open(&sb.dev, image,O_RDONLY, devopts)))
    {
      fprintf(stderr,"%s: cannot open %s: %s\n",cmd,image,err);
      exit(1);
    }
    else
    {
      fprintf(stderr,"%s: cannot open %s for writing, no repair possible\n",cmd,image);
    }
  }
  if (cpmReadSuper(&sb,&root,format)==-1)
  {
    fprintf(stderr,"%s: cannot read superblock (%s)\n",cmd,boo);
    exit(1);
  }
  ret=fsck(&root,image);
  if (ret&MODIFIED)
  {
    if (cpmSync(&sb)==-1)
    {
      fprintf(stderr,"%s: write error on %s: %s\n",cmd,image,strerror(errno));
      ret|=BROKEN;
    }
    fprintf(stderr,"%s: FILE SYSTEM ON %s MODIFIED",cmd,image);
    if (ret&BROKEN) fprintf(stderr,", PLEASE CHECK AGAIN");
    fprintf(stderr,"\n");
  }
  cpmUmount(&sb);
  if (ret&BROKEN) return 2;
  else return 0;
}
/*}}}*/
