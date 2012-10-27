/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <sys/stat.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "cpmdir.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/
/* #defines */ /*{{{*/
#undef CPMFS_DEBUG

/* Number of _used_ bits per int */

#define INTBITS ((int)(sizeof(int)*8))

/* There are four reserved entries: ., .., [passwd] and [label] */

#define RESERVED_ENTRIES 4

/* CP/M does not support any kind of inodes, so they are simulated.
Inode 0-(maxdir-1) are used by files which lowest extent is stored in
the respective directory entry.  Inode maxdir is the root directory
and inode maxdir+1 is the passwd file, if any. */

#define RESERVED_INODES 3

#define PASSWD_RECLEN 24
/*}}}*/

extern char **environ;
const char *boo;
static mode_t s_ifdir=1;
static mode_t s_ifreg=1;

/* memcpy7            -- Copy string, leaving 8th bit alone      */ /*{{{*/
static void memcpy7(char *dest, const char *src, int count)
{
  while (count--)
  {
    *dest = ((*dest) & 0x80) | ((*src) & 0x7F);
    ++dest;
    ++src;
  }
}
/*}}}*/

/* file name conversions */ 
/* splitFilename      -- split file name into name and extension */ /*{{{*/
static int splitFilename(const char *fullname, int type, char *name, char *ext, int *user) 
{
  int i,j;

  assert(fullname!=(const char*)0);
  assert(name!=(char*)0);
  assert(ext!=(char*)0);
  assert(user!=(int*)0);
  memset(name,' ',8);
  memset(ext,' ',3);
  if (!isdigit(fullname[0]) || !isdigit(fullname[1]))
  {
    boo="illegal CP/M filename";
    return -1;
  }
  *user=10*(fullname[0]-'0')+(fullname[1]-'0');
  fullname+=2;
  if ((fullname[0]=='\0') || (type==CPMFS_DR22 && *user>=16) || (type==CPMFS_P2DOS && *user>=32))
  {
    boo="illegal CP/M filename";
    return -1;
  }
  for (i=0; i<8 && fullname[i] && fullname[i]!='.'; ++i) if (!ISFILECHAR(i,fullname[i]))
  {
    boo="illegal CP/M filename";
    return -1;
  }
  else name[i]=toupper(fullname[i]);
  if (fullname[i]=='.')
  {
    ++i;
    for (j=0; j<3 && fullname[i]; ++i,++j) if (!ISFILECHAR(1,fullname[i]))
    {
      boo="illegal CP/M filename";
      return -1;
    }
    else ext[j]=toupper(fullname[i]);
    if (i==1 && j==0)
    {
      boo="illegal CP/M filename";
      return -1;
    }
  }
  return 0;
}
/*}}}*/
/* isMatching         -- do two file names match?                */ /*{{{*/
static int isMatching(int user1, const char *name1, const char *ext1, int user2, const char *name2, const char *ext2)
{
  int i;

  assert(name1!=(const char*)0);
  assert(ext1!=(const char*)0);
  assert(name2!=(const char*)0);
  assert(ext2!=(const char*)0);
  if (user1!=user2) return 0;
  for (i=0; i<8; ++i) if ((name1[i]&0x7f)!=(name2[i]&0x7f)) return 0;
  for (i=0; i<3; ++i) if ((ext1[i]&0x7f)!=(ext2[i]&0x7f)) return 0;
  return 1;
}
/*}}}*/

/* time conversions */
/* cpm2unix_time      -- convert CP/M time to UTC                */ /*{{{*/
static time_t cpm2unix_time(int days, int hour, int min)
{
  /* CP/M stores timestamps in local time.  We don't know which     */
  /* timezone was used and if DST was in effect.  Assuming it was   */
  /* the current offset from UTC is most sensible, but not perfect. */

  int year,days_per_year;
  static int days_per_month[]={31,0,31,30,31,30,31,31,30,31,30,31};
  char **old_environ;
  static char gmt0[]="TZ=GMT0";
  static char *gmt_env[]={ gmt0, (char*)0 };
  struct tm tms;
  time_t lt,t;

  time(&lt);
  t=lt;
  tms=*localtime(&lt);
  old_environ=environ;
  environ=gmt_env;
  lt=mktime(&tms);
  lt-=t;
  tms.tm_sec=0;
  tms.tm_min=((min>>4)&0xf)*10+(min&0xf);
  tms.tm_hour=((hour>>4)&0xf)*10+(hour&0xf);
  tms.tm_mday=1;
  tms.tm_mon=0;
  tms.tm_year=78;
  tms.tm_isdst=-1;
  for (;;)
  {
    year=tms.tm_year+1900;
    days_per_year=((year%4)==0 && ((year%100) || (year%400)==0)) ? 366 : 365;
    if (days>days_per_year)
    {
      days-=days_per_year;
      ++tms.tm_year;
    }
    else break;
  }
  for (;;)
  {
    days_per_month[1]=(days_per_year==366) ? 29 : 28;
    if (days>days_per_month[tms.tm_mon])
    {
      days-=days_per_month[tms.tm_mon];
      ++tms.tm_mon;
    }
    else break;
  }
  t=mktime(&tms)+(days-1)*24*3600;
  environ=old_environ;
  t-=lt;
  return t;
}
/*}}}*/
/* unix2cpm_time      -- convert UTC to CP/M time                */ /*{{{*/
static void unix2cpm_time(time_t now, int *days, int *hour, int *min) 
{
  struct tm *tms;
  int i;

  tms=localtime(&now);
  *min=((tms->tm_min/10)<<4)|(tms->tm_min%10);
  *hour=((tms->tm_hour/10)<<4)|(tms->tm_hour%10);
  for (i=1978,*days=0; i<1900+tms->tm_year; ++i)
  {
    *days+=365;
    if (i%4==0 && (i%100!=0 || i%400==0)) ++*days;
  }
  *days += tms->tm_yday+1;
}
/*}}}*/

/* allocation vector bitmap functions */
/* alvInit            -- init allocation vector                  */ /*{{{*/
static void alvInit(const struct cpmSuperBlock *d)
{
  int i,j,offset,block;

  assert(d!=(const struct cpmSuperBlock*)0);
  /* clean bitmap */ /*{{{*/
  memset(d->alv,0,d->alvSize*sizeof(int));
  /*}}}*/
  /* mark directory blocks as used */ /*{{{*/
  *d->alv=(1<<((d->maxdir*32+d->blksiz-1)/d->blksiz))-1;
  /*}}}*/
  for (i=0; i<d->maxdir; ++i) /* mark file blocks as used */ /*{{{*/
  {
    if (d->dir[i].status>=0 && d->dir[i].status<=(d->type==CPMFS_P2DOS ? 31 : 15))
    {
#ifdef CPMFS_DEBUG
      fprintf(stderr,"alvInit: allocate extent %d\n",i);
#endif
      for (j=0; j<16; ++j)
      {
        block=(unsigned char)d->dir[i].pointers[j];
        if (d->size>=256) block+=(((unsigned char)d->dir[i].pointers[++j])<<8);
        if (block && block<d->size)
        {
#ifdef CPMFS_DEBUG
          fprintf(stderr,"alvInit: allocate block %d\n",block);
#endif
          offset=block/INTBITS;
          d->alv[offset]|=(1<<block%INTBITS);
        }
      }
    }
  }
  /*}}}*/
}
/*}}}*/
/* allocBlock         -- allocate a new disk block               */ /*{{{*/
static int allocBlock(const struct cpmSuperBlock *drive)
{
  int i,j,bits,block;

  assert(drive!=(const struct cpmSuperBlock*)0);
  for (i=0; i<drive->alvSize; ++i)
  {
    for (j=0,bits=drive->alv[i]; j<INTBITS; ++j)
    {
      if ((bits&1)==0)
      {
        block=i*INTBITS+j;
        if (block>=drive->size)
        {
          boo="device full";
          return -1;
        }
        drive->alv[i] |= (1<<j);
        return block;
      }
      bits >>= 1;
    }
  }
  boo="device full";
  return -1;
}
/*}}}*/

/* logical block I/O */
/* readBlock          -- read a (partial) block                  */ /*{{{*/
static int readBlock(const struct cpmSuperBlock *d, int blockno, char *buffer, int start, int end)
{
  int sect, track, counter;

  assert(blockno>=0);
  assert(blockno<d->size);
  assert(buffer!=(char*)0);
  if (end<0) end=d->blksiz/d->secLength-1;
  sect=(blockno*(d->blksiz/d->secLength)+ d->sectrk*d->boottrk)%d->sectrk;
  track=(blockno*(d->blksiz/d->secLength)+ d->sectrk*d->boottrk)/d->sectrk;
  for (counter=0; counter<=end; ++counter)
  {
    const char *err;

    if (counter>=start && (err=Device_readSector(&d->dev,track,d->skewtab[sect],buffer+(d->secLength*counter))))
    {
      boo=err;
      return -1;
    }
    ++sect;
    if (sect>=d->sectrk) 
    {
      sect = 0;
      ++track;
    }
  }
  return 0;
}
/*}}}*/
/* writeBlock         -- write a (partial) block                 */ /*{{{*/
static int writeBlock(const struct cpmSuperBlock *d, int blockno, const char *buffer, int start, int end)
{
  int sect, track, counter;

  assert(blockno>=0);
  assert(blockno<d->size);
  assert(buffer!=(const char*)0);
  if (end < 0) end=d->blksiz/d->secLength-1;
  sect = (blockno*(d->blksiz/d->secLength))%d->sectrk;
  track = (blockno*(d->blksiz/d->secLength))/d->sectrk+d->boottrk;
  for (counter = 0; counter<=end; ++counter)
  {
    const char *err;

    if (counter>=start && (err=Device_writeSector(&d->dev,track,d->skewtab[sect],buffer+(d->secLength*counter))))
    {
      boo=err;
      return -1;
    }
    ++sect;
    if (sect>=d->sectrk) 
    {
      sect=0;
      ++track;
    }
  }
  return 0;
}
/*}}}*/

/* directory management */
/* findFileExtent     -- find first/next extent for a file       */ /*{{{*/
static int findFileExtent(const struct cpmSuperBlock *sb, int user, const char *name, const char *ext, int start, int extno)
{
  boo="file already exists";
  for (; start<sb->maxdir; ++start)
  {
    if
    (
      ((unsigned char)sb->dir[start].status)<=(sb->type==CPMFS_P2DOS ? 31 : 15)
      && (extno==-1 || (EXTENT(sb->dir[start].extnol,sb->dir[start].extnoh)/sb->extents)==(extno/sb->extents))
      && isMatching(user,name,ext,sb->dir[start].status,sb->dir[start].name,sb->dir[start].ext)
    ) return start;
  }
  boo="file not found";
  return -1;
}
/*}}}*/
/* findFreeExtent     -- find first free extent                  */ /*{{{*/
static int findFreeExtent(const struct cpmSuperBlock *drive)
{
  int i;

  for (i=0; i<drive->maxdir; ++i) if (drive->dir[i].status==(char)0xe5) return (i);
  boo="directory full";
  return -1;
}
/*}}}*/
/* updateTimeStamps   -- convert time stamps to CP/M format      */ /*{{{*/
static void updateTimeStamps(const struct cpmInode *ino, int extent)
{
  struct PhysDirectoryEntry *date;
  int i;
  int ca_min,ca_hour,ca_days,u_min,u_hour,u_days;

  if (!S_ISREG(ino->mode)) return;
#ifdef CPMFS_DEBUG
  fprintf(stderr,"CPMFS: updating time stamps for inode %d (%d)\n",extent,extent&3);
#endif
  unix2cpm_time(ino->sb->cnotatime ? ino->ctime : ino->atime,&ca_days,&ca_hour,&ca_min);
  unix2cpm_time(ino->mtime,&u_days,&u_hour,&u_min);
  if ((ino->sb->type==CPMFS_P2DOS || ino->sb->type==CPMFS_DR3) && (date=ino->sb->dir+(extent|3))->status==0x21)
  {
    ino->sb->dirtyDirectory=1;
    switch (extent&3)
    {
      case 0: /* first entry */ /*{{{*/
      {
        date->name[0]=ca_days&0xff; date->name[1]=ca_days>>8;
        date->name[2]=ca_hour;
        date->name[3]=ca_min;
        date->name[4]=u_days&0xff; date->name[5]=u_days>>8;
        date->name[6]=u_hour;
        date->name[7]=u_min;
        break;
      }
      /*}}}*/
      case 1: /* second entry */ /*{{{*/
      {
        date->ext[2]=ca_days&0xff; date->extnol=ca_days>>8;
        date->lrc=ca_hour;
        date->extnoh=ca_min;
        date->blkcnt=u_days&0xff; date->pointers[0]=u_days>>8;
        date->pointers[1]=u_hour;
        date->pointers[2]=u_min;
        break;
      }
      /*}}}*/
      case 2: /* third entry */ /*{{{*/
      {
        date->pointers[5]=ca_days&0xff; date->pointers[6]=ca_days>>8;
        date->pointers[7]=ca_hour;
        date->pointers[8]=ca_min;
        date->pointers[9]=u_days&0xff; date->pointers[10]=u_days>>8;
        date->pointers[11]=u_hour;
        date->pointers[12]=u_min;
        break;
      }
      /*}}}*/
    }
  }
}
/*}}}*/

/* diskdefReadSuper   -- read super block from diskdefs file     */ /*{{{*/
static int diskdefReadSuper(struct cpmSuperBlock *d, const char *format)
{
  char line[256];
  FILE *fp;
  int insideDef=0,found=0;

  if ((fp=fopen(DISKDEFS,"r"))==(FILE*)0 && (fp=fopen("diskdefs","r"))==(FILE*)0)
  {
    fprintf(stderr,"%s: Neither " DISKDEFS " nor diskdefs could be opened.\n",cmd);
    exit(1);
  }
  while (fgets(line,sizeof(line),fp)!=(char*)0)
  {
    int argc;
    char *argv[2];

    for (argc=0; argc<1 && (argv[argc]=strtok(argc ? (char*)0 : line," \t\n")); ++argc);
    if ((argv[argc]=strtok((char*)0,"\n"))!=(char*)0) ++argc;
    if (insideDef)
    {
      if (argc==1 && strcmp(argv[0],"end")==0)
      {
        insideDef=0;
        d->size=(d->secLength*d->sectrk*(d->tracks-d->boottrk))/d->blksiz;
        if (d->extents==0) d->extents=((d->size>=256 ? 8 : 16)*d->blksiz)/16384;
        if (d->extents==0) d->extents=1;
        if (found) break;
      }
      else if (argc==2)
      {
        if (strcmp(argv[0],"seclen")==0) d->secLength=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"tracks")==0) d->tracks=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"sectrk")==0) d->sectrk=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"blocksize")==0) d->blksiz=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"maxdir")==0) d->maxdir=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"skew")==0) d->skew=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"skewtab")==0)
        {
          int pass,sectors;

          for (pass=0; pass<2; ++pass)
          {
            char *s;

            sectors=0;
            for (s=argv[1]; *s; )
            {
              int phys;
              char *end;

              phys=strtol(s,&end,10);
              if (pass==1) d->skewtab[sectors]=phys;
              if (end==s)
              {
                fprintf(stderr,"%s: invalid skewtab `%s' at `%s'\n",cmd,argv[1],s);
                exit(1);
              }
              s=end;
              ++sectors;
              if (*s==',') ++s;
            }
            if (pass==0) d->skewtab=malloc(sizeof(int)*sectors);
          }
        }
        else if (strcmp(argv[0],"boottrk")==0) d->boottrk=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"logicalextents")==0) d->extents=strtol(argv[1],(char**)0,0);
        else if (strcmp(argv[0],"os")==0)
        {
          if (strcmp(argv[1],"2.2")==0) d->type=CPMFS_DR22;
          else if (strcmp(argv[1],"3")==0) d->type=CPMFS_DR3;
          else if (strcmp(argv[1],"p2dos")==0) d->type=CPMFS_P2DOS;
        }
      }
      else if (argc>0 && argv[0][0]!='#')
      {
        fprintf(stderr,"%s: invalid keyword `%s'\n",cmd,argv[0]);
        exit(1);
      }
    }
    else if (argc==2 && strcmp(argv[0],"diskdef")==0)
    {
      insideDef=1;
      d->skew=1;
      d->extents=0;
      d->type=CPMFS_DR3;
      d->skewtab=(int*)0;
      if (strcmp(argv[1],format)==0) found=1;
    }
  }
  fclose(fp);
  if (!found)
  {
    fprintf(stderr,"%s: unknown format %s\n",cmd,format);
    exit(1);
  }
  return 0;
}
/*}}}*/
/* amsReadSuper       -- read super block from amstrad disk      */ /*{{{*/
static int amsReadSuper(struct cpmSuperBlock *d, const char *format)
{
  unsigned char boot_sector[512], *boot_spec;
  const char *err;

  Device_setGeometry(&d->dev,512,9,40);
  if ((err=Device_readSector(&d->dev, 0, 0, (char *)boot_sector)))
  {
    fprintf(stderr,"%s: Failed to read Amstrad superblock (%s)\n",cmd,err);
    exit(1);
  }
  boot_spec=(boot_sector[0] == 0 || boot_sector[0] == 3)?boot_sector:(unsigned char*)0;
  /* Check for JCE's extension to allow Amstrad and MSDOS superblocks
   * in the same sector (for the PCW16)
   */
  if
  (
    (boot_sector[0] == 0xE9 || boot_sector[0] == 0xEB)
    && !memcmp(boot_sector + 0x2B, "CP/M", 4)
    && !memcmp(boot_sector + 0x33, "DSK",  3)
    && !memcmp(boot_sector + 0x7C, "CP/M", 4)
  ) boot_spec = boot_sector + 128;
  if (boot_spec==(unsigned char*)0)
  {
    fprintf(stderr,"%s: Amstrad superblock not present\n",cmd);
    exit(1);
  }
  /* boot_spec[0] = format number: 0 for SS SD, 3 for DS DD
              [1] = single/double sided and density flags
              [2] = cylinders per side
              [3] = sectors per cylinder
              [4] = Physical sector shift, 2 => 512
              [5] = Reserved track count
              [6] = Block shift
              [7] = No. of directory blocks
   */
  d->type = CPMFS_DR3;	/* Amstrads are CP/M 3 systems */
  d->secLength = 128 << boot_spec[4];
  d->tracks    = boot_spec[2];
  if (boot_spec[1] & 3) d->tracks *= 2;
  d->sectrk    = boot_spec[3];
  d->blksiz    = 128 << boot_spec[6];
  d->maxdir    = (d->blksiz / 32) * boot_spec[7];
  d->skew      = 1; /* Amstrads skew at the controller level */
  d->skewtab   = (int*)0;
  d->boottrk   = boot_spec[5];
  d->size      = (d->secLength*d->sectrk*(d->tracks-d->boottrk))/d->blksiz;
  d->extents   = ((d->size>=256 ? 8 : 16)*d->blksiz)/16384;
 
  return 0;
}
/*}}}*/

/* match              -- match filename against a pattern        */ /*{{{*/
static int recmatch(const char *a, const char *pattern)
{
  int first=1;

  while (*pattern)
  {
    switch (*pattern)
    {
      case '*':
      {
        if (*a=='.' && first) return 1;
        ++pattern;
        while (*a) if (recmatch(a,pattern)) return 1; else ++a;
        break;
      }
      case '?':
      {
        if (*a) { ++a; ++pattern; } else return 0;
        break;
      }
      default: if (tolower(*a)==tolower(*pattern)) { ++a; ++pattern; } else return 0;
    }
    first=0;
  }
  return (*pattern=='\0' && *a=='\0');
}

int match(const char *a, const char *pattern) 
{
  int user;
  char pat[255];

  assert(strlen(pattern)<255);
  if (isdigit(*pattern) && *(pattern+1)==':') { user=(*pattern-'0'); pattern+=2; }
  else if (isdigit(*pattern) && isdigit(*(pattern+1)) && *(pattern+2)==':') { user=(10*(*pattern-'0')+(*(pattern+1)-'0')); pattern+=3; }
  else user=-1;
  if (user==-1) sprintf(pat,"??%s",pattern);
  else sprintf(pat,"%02d%s",user,pattern);
  return recmatch(a,pat);
}

/*}}}*/
/* cpmglob            -- expand CP/M style wildcards             */ /*{{{*/
void cpmglob(int optin, int argc, char * const argv[], struct cpmInode *root, int *gargc, char ***gargv)
{
  struct cpmFile dir;
  int entries,dirsize=0;
  struct cpmDirent *dirent=(struct cpmDirent*)0;
  int gargcap=0,i,j;

  *gargv=(char**)0;
  *gargc=0;
  cpmOpendir(root,&dir);
  entries=0;
  dirsize=8;
  dirent=malloc(sizeof(struct cpmDirent)*dirsize);
  while (cpmReaddir(&dir,&dirent[entries]))
  {
    ++entries;
    if (entries==dirsize) dirent=realloc(dirent,sizeof(struct cpmDirent)*(dirsize*=2));
  }
  for (i=optin; i<argc; ++i)
  {
    int found;

    for (j=0,found=0; j<entries; ++j)
    {
      if (match(dirent[j].name,argv[i]))
      {
        if (*gargc==gargcap) *gargv=realloc(*gargv,sizeof(char*)*(gargcap ? (gargcap*=2) : (gargcap=16)));
        (*gargv)[*gargc]=strcpy(malloc(strlen(dirent[j].name)+1),dirent[j].name);
        ++*gargc;
        ++found;
      }
    }
    if (found==0)
    {
      char pat[255];
      char *pattern=argv[i];
      int user;

      if (isdigit(*pattern) && *(pattern+1)==':') { user=(*pattern-'0'); pattern+=2; }
      else if (isdigit(*pattern) && isdigit(*(pattern+1)) && *(pattern+2)==':') { user=(10*(*pattern-'0')+(*(pattern+1)-'0')); pattern+=3; }
      else user=-1;
      if (user==-1) sprintf(pat,"??%s",pattern);
      else sprintf(pat,"%02d%s",user,pattern);

      if (*gargc==gargcap) *gargv=realloc(*gargv,sizeof(char*)*(gargcap ? (gargcap*=2) : (gargcap=16)));
      (*gargv)[*gargc]=strcpy(malloc(strlen(pat)+1),pat);
      ++*gargc;
    }
  }
  free(dirent);
}
/*}}}*/

/* cpmReadSuper       -- get DPB and init in-core data for drive */ /*{{{*/
int cpmReadSuper(struct cpmSuperBlock *d, struct cpmInode *root, const char *format)
{
  while (s_ifdir && !S_ISDIR(s_ifdir)) s_ifdir<<=1;
  assert(s_ifdir);
  while (s_ifreg && !S_ISREG(s_ifreg)) s_ifreg<<=1;
  assert(s_ifreg);
  if (strcmp(format, "amstrad")==0) amsReadSuper(d,format);
  else diskdefReadSuper(d,format);
  Device_setGeometry(&d->dev,d->secLength,d->sectrk,d->tracks);
  if (d->skewtab==(int*)0) /* generate skew table */ /*{{{*/
  {
    int	i,j,k;

    if (( d->skewtab = malloc(d->sectrk*sizeof(int))) == (int*)0) 
    {
      fprintf(stderr,"%s: can not allocate memory for skew sector table\n",cmd);
      exit(1);
    }
    memset(d->skewtab,0,d->sectrk*sizeof(int));
    for (i=j=0; i<d->sectrk; ++i,j=(j+d->skew)%d->sectrk)
    {
      while (1)
      {
        for (k=0; k<i && d->skewtab[k]!=j; ++k);
        if (k<i) j=(j+1)%d->sectrk;
        else break;
      }
      d->skewtab[i]=j;
    }
  }
  /*}}}*/
  /* initialise allocation vector bitmap */ /*{{{*/
  {
    d->alvSize=((d->secLength*d->sectrk*(d->tracks-d->boottrk))/d->blksiz+INTBITS-1)/INTBITS;
    if ((d->alv=malloc(d->alvSize*sizeof(int)))==(int*)0) 
    {
      boo="out of memory";
      return -1;
    }
  }
  /*}}}*/
  /* allocate directory buffer */ /*{{{*/
  if ((d->dir=malloc(d->maxdir*32))==(struct PhysDirectoryEntry*)0)
  {
    boo="out of memory";
    return -1;
  }
  /*}}}*/
  if (d->dev.opened==0) /* create empty directory in core */ /*{{{*/
  {
    memset(d->dir,0xe5,d->maxdir*32);
  }
  /*}}}*/
  else /* read directory in core */ /*{{{*/
  {
    int i,blocks,entry;

    blocks=(d->maxdir*32+d->blksiz-1)/d->blksiz;
    entry=0;
    for (i=0; i<blocks; ++i) 
    {
      if (readBlock(d,i,(char*)(d->dir+entry),0,-1)==-1) return -1;
      entry+=(d->blksiz/32);
    }
  }
  /*}}}*/
  alvInit(d);
  if (d->type==CPMFS_DR3) /* read additional superblock information */ /*{{{*/
  {
    int i;

    /* passwords */ /*{{{*/
    {
      int passwords=0;

      for (i=0; i<d->maxdir; ++i) if (d->dir[i].status>=16 && d->dir[i].status<=31) ++passwords;
#ifdef CPMFS_DEBUG
      fprintf(stderr,"getformat: found %d passwords\n",passwords);
#endif
      if ((d->passwdLength=passwords*PASSWD_RECLEN))
      {
        if ((d->passwd=malloc(d->passwdLength))==(char*)0)
        {
          boo="out of memory";
          return -1;
        }
        for (i=0,passwords=0; i<d->maxdir; ++i) if (d->dir[i].status>=16 && d->dir[i].status<=31)
        {
          int j,pb;
          char *p=d->passwd+(passwords++*PASSWD_RECLEN);

          p[0]='0'+(d->dir[i].status-16)/10;
          p[1]='0'+(d->dir[i].status-16)%10;
          for (j=0; j<8; ++j) p[2+j]=d->dir[i].name[j]&0x7f;
          p[10]=(d->dir[i].ext[0]&0x7f)==' ' ? ' ' : '.';
          for (j=0; j<3; ++j) p[11+j]=d->dir[i].ext[j]&0x7f;
          p[14]=' ';
          pb=(unsigned char)d->dir[i].lrc;
          for (j=0; j<8; ++j) p[15+j]=((unsigned char)d->dir[i].pointers[7-j])^pb;
#ifdef CPMFS_DEBUG
          p[23]='\0';
          fprintf(stderr,"getformat: %s\n",p);
#endif        
          p[23]='\n';
        }
      }
    }
    /*}}}*/
    /* disc label */ /*{{{*/
    for (i=0; i<d->maxdir; ++i) if (d->dir[i].status==(char)0x20)
    {
      int j;

      d->cnotatime=d->dir[i].extnol&0x10;
      if (d->dir[i].extnol&0x1)
      {
        d->labelLength=12;
        if ((d->label=malloc(d->labelLength))==(char*)0)
        {
          boo="out of memory";
          return -1;
        }
        for (j=0; j<8; ++j) d->label[j]=d->dir[i].name[j]&0x7f;
        for (j=0; j<3; ++j) d->label[8+j]=d->dir[i].ext[j]&0x7f;
        d->label[11]='\n';
      }
      else
      {
        d->labelLength=0;
      }
      break;
    }
    if (i==d->maxdir)
    {
      d->cnotatime=1;
      d->labelLength=0;
    }
    /*}}}*/
  }
  /*}}}*/
  else
  {
    d->passwdLength=0;
    d->cnotatime=1;
    d->labelLength=0;
  }
  d->root=root;
  root->ino=d->maxdir;
  root->sb=d;
  root->mode=(s_ifdir|0777);
  root->size=0;
  root->atime=root->mtime=root->ctime=0;
  return 0;
}
/*}}}*/
/* cpmNamei           -- map name to inode                       */ /*{{{*/
int cpmNamei(const struct cpmInode *dir, const char *filename, struct cpmInode *i)
{
  /* variables */ /*{{{*/
  int user;
  char name[8],extension[3];
  struct PhysDirectoryEntry *date;
  int highestExtno,highestExt=-1,lowestExtno,lowestExt=-1;
  int protectMode=0;
  /*}}}*/

  if (!S_ISDIR(dir->mode))
  {
    boo="No such file";
    return -1;
  }
  if (strcmp(filename,".")==0 || strcmp(filename,"..")==0) /* root directory */ /*{{{*/
  {
    *i=*dir;
    return 0;
  }
  /*}}}*/
  else if (strcmp(filename,"[passwd]")==0 && dir->sb->passwdLength) /* access passwords */ /*{{{*/
  {
    i->attr=0;
    i->ino=dir->sb->maxdir+1;
    i->mode=s_ifreg|0444;
    i->sb=dir->sb;
    i->atime=i->mtime=i->ctime=0;
    i->size=i->sb->passwdLength;
    return 0;
  }
  /*}}}*/
  else if (strcmp(filename,"[label]")==0 && dir->sb->labelLength) /* access label */ /*{{{*/
  {
    i->attr=0;
    i->ino=dir->sb->maxdir+2;
    i->mode=s_ifreg|0444;
    i->sb=dir->sb;
    i->atime=i->mtime=i->ctime=0;
    i->size=i->sb->labelLength;
    return 0;
  }
  /*}}}*/
  if (splitFilename(filename,dir->sb->type,name,extension,&user)==-1) return -1;
  /* find highest and lowest extent */ /*{{{*/
  {
    int extent;

    i->size=0;
    extent=-1;
    highestExtno=-1;
    lowestExtno=2049;
    while ((extent=findFileExtent(dir->sb,user,name,extension,extent+1,-1))!=-1)
    {
      int extno=EXTENT(dir->sb->dir[extent].extnol,dir->sb->dir[extent].extnoh);

      if (extno>highestExtno)
      {
        highestExtno=extno;
        highestExt=extent;
      }
      if (extno<lowestExtno)
      {
        lowestExtno=extno;
        lowestExt=extent;
      }
    }
  }
  /*}}}*/
  if (highestExtno==-1) return -1;
  /* calculate size */ /*{{{*/
  {
    int block;

    i->size=highestExtno*16384;
    if (dir->sb->size<256) for (block=15; block>=0; --block)
    {
      if (dir->sb->dir[highestExt].pointers[block]) break;
    }
    else for (block=7; block>=0; --block)
    {
      if (dir->sb->dir[highestExt].pointers[2*block] || dir->sb->dir[highestExt].pointers[2*block+1]) break;
    }
    if (dir->sb->dir[highestExt].blkcnt) i->size+=((dir->sb->dir[highestExt].blkcnt&0xff)-1)*128;
    i->size+=dir->sb->dir[highestExt].lrc ? (dir->sb->dir[highestExt].lrc&0xff) : 128;
#ifdef CPMFS_DEBUG
    fprintf(stderr,"cpmNamei: size=%ld\n",(long)i->size);
#endif
  }
  /*}}}*/
  i->ino=lowestExt;
  i->mode=s_ifreg;
  i->sb=dir->sb;
  /* set timestamps */ /*{{{*/
  if 
  (
    (dir->sb->type==CPMFS_P2DOS || dir->sb->type==CPMFS_DR3)
    && (date=dir->sb->dir+(lowestExt|3))->status==0x21
  )
  {
    /* variables */ /*{{{*/
    int u_days=0,u_hour=0,u_min=0;
    int ca_days=0,ca_hour=0,ca_min=0;
    /*}}}*/

    switch (lowestExt&3)
    {
      case 0: /* first entry of the four */ /*{{{*/
      {
        ca_days=((unsigned char)date->name[0])+(((unsigned char)date->name[1])<<8);
        ca_hour=(unsigned char)date->name[2];
        ca_min=(unsigned char)date->name[3];
        u_days=((unsigned char)date->name[4])+(((unsigned char)date->name[5])<<8);
        u_hour=(unsigned char)date->name[6];
        u_min=(unsigned char)date->name[7];
	protectMode=(unsigned char)date->ext[0];
        break;
      }
      /*}}}*/
      case 1: /* second entry */ /*{{{*/
      {
        ca_days=((unsigned char)date->ext[2])+(((unsigned char)date->extnol)<<8);
        ca_hour=(unsigned char)date->lrc;
        ca_min=(unsigned char)date->extnoh;
        u_days=((unsigned char)date->blkcnt)+(((unsigned char)date->pointers[0])<<8);
        u_hour=(unsigned char)date->pointers[1];
        u_min=(unsigned char)date->pointers[2];
        protectMode=(unsigned char)date->pointers[3];
        break;
      }
      /*}}}*/
      case 2: /* third one */ /*{{{*/
      {
        ca_days=((unsigned char)date->pointers[5])+(((unsigned char)date->pointers[6])<<8);
        ca_hour=(unsigned char)date->pointers[7];
        ca_min=(unsigned char)date->pointers[8];
        u_days=((unsigned char)date->pointers[9])+(((unsigned char)date->pointers[10])<<8);
        u_hour=(unsigned char)date->pointers[11];
        u_min=(unsigned char)date->pointers[12];
        protectMode=(unsigned char)date->pointers[13];
        break;
      }
      /*}}}*/
    }
    if (i->sb->cnotatime)
    {
      i->ctime=cpm2unix_time(ca_days,ca_hour,ca_min);
      i->atime=0;
    }
    else
    {
      i->ctime=0;
      i->atime=cpm2unix_time(ca_days,ca_hour,ca_min);
    }
    i->mtime=cpm2unix_time(u_days,u_hour,u_min);
  }
  else i->atime=i->mtime=i->ctime=0;
  /*}}}*/

  /* Determine the inode attributes */
  i->attr = 0;
  if (dir->sb->dir[lowestExt].name[0]&0x80) i->attr |= CPM_ATTR_F1;
  if (dir->sb->dir[lowestExt].name[1]&0x80) i->attr |= CPM_ATTR_F2;
  if (dir->sb->dir[lowestExt].name[2]&0x80) i->attr |= CPM_ATTR_F3;
  if (dir->sb->dir[lowestExt].name[3]&0x80) i->attr |= CPM_ATTR_F4;
  if (dir->sb->dir[lowestExt].ext [0]&0x80) i->attr |= CPM_ATTR_RO;
  if (dir->sb->dir[lowestExt].ext [1]&0x80) i->attr |= CPM_ATTR_SYS;
  if (dir->sb->dir[lowestExt].ext [2]&0x80) i->attr |= CPM_ATTR_ARCV;
  if (protectMode&0x20)                     i->attr |= CPM_ATTR_PWDEL;
  if (protectMode&0x40)                     i->attr |= CPM_ATTR_PWWRITE;
  if (protectMode&0x80)                     i->attr |= CPM_ATTR_PWREAD;

  if (dir->sb->dir[lowestExt].ext[1]&0x80) i->mode|=01000;
  i->mode|=0444;
  if (!(dir->sb->dir[lowestExt].ext[0]&0x80)) i->mode|=0222;
  if (extension[0]=='C' && extension[1]=='O' && extension[2]=='M') i->mode|=0111;
  return 0;
}
/*}}}*/
/* cpmStatFS          -- statfs                                  */ /*{{{*/
void cpmStatFS(const struct cpmInode *ino, struct cpmStatFS *buf)
{
  int i;
  struct cpmSuperBlock *d;

  d=ino->sb;
  buf->f_bsize=d->blksiz;
  buf->f_blocks=(d->tracks*d->sectrk*d->secLength)/d->blksiz;
  buf->f_bfree=0;
  buf->f_bused=-(d->maxdir*32+d->blksiz-1)/d->blksiz;
  for (i=0; i<d->alvSize; ++i)
  {
    int temp,j;

    temp = *(d->alv+i);
    for (j=0; j<INTBITS; ++j)
    {
      if (i*INTBITS+j < d->size)
      {
        if (1&temp)
        {
#ifdef CPMFS_DEBUG
          fprintf(stderr,"cpmStatFS: block %d allocated\n",(i*INTBITS+j));
#endif
          ++buf->f_bused;
        }
        else ++buf->f_bfree;
      }
      temp >>= 1;
    }
  }
  buf->f_bavail=buf->f_bfree;
  buf->f_files=d->maxdir;
  buf->f_ffree=0;
  for (i=0; i<d->maxdir; ++i)
  {
    if (d->dir[i].status==(char)0xe5) ++buf->f_ffree;
  }
  buf->f_namelen=11;
}
/*}}}*/
/* cpmUnlink          -- unlink                                  */ /*{{{*/
int cpmUnlink(const struct cpmInode *dir, const char *fname)
{
  int user;
  char name[8],extension[3];
  int extent;
  struct cpmSuperBlock *drive;

  if (!S_ISDIR(dir->mode))
  {
    boo="No such file";
    return -1;
  }
  drive=dir->sb;
  if (splitFilename(fname,dir->sb->type,name,extension,&user)==-1) return -1;
  if ((extent=findFileExtent(drive,user,name,extension,0,-1))==-1) return -1;
  drive->dirtyDirectory=1;
  drive->dir[extent].status=(char)0xe5;
  do
  {
    drive->dir[extent].status=(char)0xe5;
  } while ((extent=findFileExtent(drive,user,name,extension,extent+1,-1))>=0);
  alvInit(drive);
  return 0;
}
/*}}}*/
/* cpmRename          -- rename                                  */ /*{{{*/
int cpmRename(const struct cpmInode *dir, const char *old, const char *new)
{
  struct cpmSuperBlock *drive;
  int extent;
  int olduser;
  char oldname[8], oldext[3];
  int newuser;
  char newname[8], newext[3];

  if (!S_ISDIR(dir->mode))
  {
    boo="No such file";
    return -1;
  }
  drive=dir->sb;
  if (splitFilename(old,dir->sb->type, oldname, oldext,&olduser)==-1) return -1;
  if (splitFilename(new,dir->sb->type, newname, newext,&newuser)==-1) return -1;
  if ((extent=findFileExtent(drive,olduser,oldname,oldext,0,-1))==-1) return -1;
  if (findFileExtent(drive,newuser,newname, newext,0,-1)!=-1) 
  {
    boo="file already exists";
    return -1;
  }
  do 
  {
    drive->dirtyDirectory=1;
    drive->dir[extent].status=newuser;
    memcpy7(drive->dir[extent].name, newname, 8);
    memcpy7(drive->dir[extent].ext, newext, 3);
  } while ((extent=findFileExtent(drive,olduser,oldname,oldext,extent+1,-1))!=-1);
  return 0;
}
/*}}}*/
/* cpmOpendir         -- opendir                                 */ /*{{{*/
int cpmOpendir(struct cpmInode *dir, struct cpmFile *dirp)
{
  if (!S_ISDIR(dir->mode))
  {
    boo="No such file";
    return -1;
  }
  dirp->ino=dir;
  dirp->pos=0;
  dirp->mode=O_RDONLY;
  return 0;
}
/*}}}*/
/* cpmReaddir         -- readdir                                 */ /*{{{*/
int cpmReaddir(struct cpmFile *dir, struct cpmDirent *ent)
{
  /* variables */ /*{{{*/
  struct PhysDirectoryEntry *cur=(struct PhysDirectoryEntry*)0;
  char buf[2+8+1+3+1]; /* 00foobarxy.zzy\0 */
  int i;
  char *bufp;
  int hasext;
  /*}}}*/

  if (!(S_ISDIR(dir->ino->mode))) /* error: not a directory */ /*{{{*/
  {
    boo="not a directory";
    return -1;
  }
  /*}}}*/
  while (1)
  {
    if (dir->pos==0) /* first entry is . */ /*{{{*/
    {
      ent->ino=dir->ino->sb->maxdir;
      ent->reclen=1;
      strcpy(ent->name,".");
      ent->off=dir->pos;
      ++dir->pos;
      return 1;
    }
    /*}}}*/
    else if (dir->pos==1) /* next entry is .. */ /*{{{*/
    {
      ent->ino=dir->ino->sb->maxdir;
      ent->reclen=2;
      strcpy(ent->name,"..");
      ent->off=dir->pos;
      ++dir->pos;
      return 1;
    }
    /*}}}*/
    else if (dir->pos==2)
    {
      if (dir->ino->sb->passwdLength) /* next entry is [passwd] */ /*{{{*/
      {
        ent->ino=dir->ino->sb->maxdir+1;
        ent->reclen=8;
        strcpy(ent->name,"[passwd]");
        ent->off=dir->pos;
        ++dir->pos;
        return 1;
      }
      /*}}}*/
    }
    else if (dir->pos==3)
    {
      if (dir->ino->sb->labelLength) /* next entry is [label] */ /*{{{*/
      {
        ent->ino=dir->ino->sb->maxdir+2;
        ent->reclen=7;
        strcpy(ent->name,"[label]");
        ent->off=dir->pos;
        ++dir->pos;
        return 1;
      }
      /*}}}*/
    }
    else if (dir->pos>=RESERVED_ENTRIES && dir->pos<dir->ino->sb->maxdir+RESERVED_ENTRIES)
    {
      int first=dir->pos-RESERVED_ENTRIES;

      if ((cur=dir->ino->sb->dir+(dir->pos-RESERVED_ENTRIES))->status>=0 && cur->status<=(dir->ino->sb->type==CPMFS_P2DOS ? 31 : 15))
      {
        /* determine first extent for the current file */ /*{{{*/
        for (i=0; i<dir->ino->sb->maxdir; ++i) if (i!=(dir->pos-RESERVED_ENTRIES))
        {
          if (isMatching(cur->status,cur->name,cur->ext,dir->ino->sb->dir[i].status,dir->ino->sb->dir[i].name,dir->ino->sb->dir[i].ext) && EXTENT(cur->extnol,cur->extnoh)>EXTENT(dir->ino->sb->dir[i].extnol,dir->ino->sb->dir[i].extnoh)) first=i;
        }
        /*}}}*/
        if (first==(dir->pos-RESERVED_ENTRIES))
        {
          ent->ino=dir->pos-RESERVED_INODES;
          /* convert file name to UNIX style */ /*{{{*/
          buf[0]='0'+cur->status/10;
          buf[1]='0'+cur->status%10;
          for (bufp=buf+2,i=0; i<8 && (cur->name[i]&0x7f)!=' '; ++i) *bufp++=tolower(cur->name[i]&0x7f);
          for (hasext=0,i=0; i<3 && (cur->ext[i]&0x7f)!=' '; ++i)
          {
            if (!hasext) { *bufp++='.'; hasext=1; }
            *bufp++=tolower(cur->ext[i]&0x7f);
          }
          *bufp='\0';
          /*}}}*/
          assert(bufp<=buf+sizeof(buf));
          ent->reclen=bufp-buf;
          strcpy(ent->name,buf);
          ent->off=dir->pos;
          ++dir->pos;
          return 1;
        }
      }
    }
    else return 0;
    ++dir->pos;
  }
}
/*}}}*/
/* cpmStat            -- stat                                    */ /*{{{*/
void cpmStat(const struct cpmInode *ino, struct cpmStat *buf)
{
  buf->ino=ino->ino;
  buf->mode=ino->mode;
  buf->size=ino->size;
  buf->atime=ino->atime;
  buf->mtime=ino->mtime;
  buf->ctime=ino->ctime;
}
/*}}}*/
/* cpmOpen            -- open                                    */ /*{{{*/
int cpmOpen(struct cpmInode *ino, struct cpmFile *file, mode_t mode)
{
  if (S_ISREG(ino->mode))
  {
    if ((mode&O_WRONLY) && (ino->mode&0222)==0)
    {
      boo="permission denied";
      return -1;
    }
    file->pos=0;
    file->ino=ino;
    file->mode=mode;
    return 0;
  }
  else
  {
    boo="not a regular file";
    return -1;
  }
}
/*}}}*/
/* cpmRead            -- read                                    */ /*{{{*/
int cpmRead(struct cpmFile *file, char *buf, int count)
{
  int findext=1,findblock=1,extent=-1,block=-1,extentno=-1,got=0,nextblockpos=-1,nextextpos=-1;
  int blocksize=file->ino->sb->blksiz;
  int extcap;

  extcap=(file->ino->sb->size<256 ? 16 : 8)*blocksize;
  if (extcap>16384) extcap=16384*file->ino->sb->extents;
  if (file->ino->ino==file->ino->sb->maxdir+1) /* [passwd] */ /*{{{*/
  {
    if ((file->pos+count)>file->ino->size) count=file->ino->size-file->pos;
    if (count) memcpy(buf,file->ino->sb->passwd+file->pos,count);
    file->pos+=count;
#ifdef CPMFS_DEBUG
    fprintf(stderr,"cpmRead passwd: read %d bytes, now at position %ld\n",count,(long)file->pos);
#endif
    return count;
  }
  /*}}}*/
  else if (file->ino->ino==file->ino->sb->maxdir+2) /* [label] */ /*{{{*/
  {
    if ((file->pos+count)>file->ino->size) count=file->ino->size-file->pos;
    if (count) memcpy(buf,file->ino->sb->label+file->pos,count);
    file->pos+=count;
#ifdef CPMFS_DEBUG
    fprintf(stderr,"cpmRead label: read %d bytes, now at position %ld\n",count,(long)file->pos);
#endif
    return count;
  }
  /*}}}*/
  else while (count>0 && file->pos<file->ino->size)
  {
    char buffer[16384];

    if (findext)
    {
      extentno=file->pos/16384;
      extent=findFileExtent(file->ino->sb,file->ino->sb->dir[file->ino->ino].status,file->ino->sb->dir[file->ino->ino].name,file->ino->sb->dir[file->ino->ino].ext,0,extentno);
      nextextpos=(file->pos/extcap)*extcap+extcap;
      findext=0;
      findblock=1;
    }
    if (findblock)
    {
      if (extent!=-1)
      {
        int start,end,ptr;

        ptr=(file->pos%extcap)/blocksize;
        if (file->ino->sb->size>=256) ptr*=2;
        block=(unsigned char)file->ino->sb->dir[extent].pointers[ptr];
        if (file->ino->sb->size>=256) block+=((unsigned char)file->ino->sb->dir[extent].pointers[ptr+1])<<8;
        if (block==0)
        {
          memset(buffer,0,blocksize);
        }
        else
        {
          start=(file->pos%blocksize)/file->ino->sb->secLength;
          end=((file->pos%blocksize+count)>blocksize ? blocksize-1 : (file->pos%blocksize+count-1))/file->ino->sb->secLength;
          readBlock(file->ino->sb,block,buffer,start,end);
        }
      }
      nextblockpos=(file->pos/blocksize)*blocksize+blocksize;
      findblock=0;
    }
    if (file->pos<nextblockpos)
    {
      if (extent==-1) *buf++='\0'; else *buf++=buffer[file->pos%blocksize];
      ++file->pos;
      ++got;
      --count;
    }
    else if (file->pos==nextextpos) findext=1; else findblock=1;
  }
#ifdef CPMFS_DEBUG
  fprintf(stderr,"cpmRead: read %d bytes, now at position %ld\n",got,(long)file->pos);
#endif
  return got;
}
/*}}}*/
/* cpmWrite           -- write                                   */ /*{{{*/
int cpmWrite(struct cpmFile *file, const char *buf, int count)
{
  int findext=1,findblock=-1,extent=-1,extentno=-1,got=0,nextblockpos=-1,nextextpos=-1;
  int blocksize=file->ino->sb->blksiz;
  int extcap=(file->ino->sb->size<256 ? 16 : 8)*blocksize;
  int block=-1,start=-1,end=-1,ptr=-1,last=-1;
  char buffer[16384];

  while (count>0)
  {
    if (findext) /*{{{*/
    {
      extentno=file->pos/16384;
      extent=findFileExtent(file->ino->sb,file->ino->sb->dir[file->ino->ino].status,file->ino->sb->dir[file->ino->ino].name,file->ino->sb->dir[file->ino->ino].ext,0,extentno);
      nextextpos=(file->pos/extcap)*extcap+extcap;
      if (extent==-1)
      {
        if ((extent=findFreeExtent(file->ino->sb))==-1) return (got==0 ? -1 : got);
        file->ino->sb->dir[extent]=file->ino->sb->dir[file->ino->ino];
        memset(file->ino->sb->dir[extent].pointers,0,16);
        file->ino->sb->dir[extent].extnol=EXTENTL(extentno);
        file->ino->sb->dir[extent].extnoh=EXTENTH(extentno);
        file->ino->sb->dir[extent].blkcnt=0;
        file->ino->sb->dir[extent].lrc=0;
        updateTimeStamps(file->ino,extent);
      }
      findext=0;
      findblock=1;
    }
    /*}}}*/
    if (findblock) /*{{{*/
    {
      ptr=(file->pos%extcap)/blocksize;
      if (file->ino->sb->size>=256) ptr*=2;
      block=(unsigned char)file->ino->sb->dir[extent].pointers[ptr];
      if (file->ino->sb->size>=256) block+=((unsigned char)file->ino->sb->dir[extent].pointers[ptr+1])<<8;
      if (block==0) /* allocate new block, set start/end to cover it */ /*{{{*/
      {
        if ((block=allocBlock(file->ino->sb))==-1) return (got==0 ? -1 : got);
        file->ino->sb->dir[extent].pointers[ptr]=block&0xff;
        if (file->ino->sb->size>=256) file->ino->sb->dir[extent].pointers[ptr+1]=(block>>8)&0xff;
        start=0;
        end=(blocksize-1)/file->ino->sb->secLength;
        memset(buffer,0,blocksize);
      }
      /*}}}*/
      else /* read existing block and set start/end to cover modified parts */ /*{{{*/
      {
        start=(file->pos%blocksize)/file->ino->sb->secLength;
        end=((file->pos%blocksize+count)>blocksize ? blocksize-1 : (file->pos%blocksize+count-1))/file->ino->sb->secLength;
        if (file->pos%file->ino->sb->secLength) readBlock(file->ino->sb,block,buffer,start,start);
        if (end!=start && (file->pos+count-1)<blocksize) readBlock(file->ino->sb,block,buffer+end*file->ino->sb->secLength,end,end);
      }
      /*}}}*/
      nextblockpos=(file->pos/blocksize)*blocksize+blocksize;
      findblock=0;
    }
    /*}}}*/
    /* fill block and write it */ /*{{{*/
    file->ino->sb->dirtyDirectory=1;
    while (file->pos!=nextblockpos && count)
    {
      buffer[file->pos%blocksize]=*buf++;
      ++file->pos;
      if (file->ino->size<file->pos) file->ino->size=file->pos;
      ++got;
      --count;
    }
    (void)writeBlock(file->ino->sb,block,buffer,start,end);
    if (file->ino->sb->size<256) for (last=15; last>=0; --last)
    {
      if (file->ino->sb->dir[extent].pointers[last])
      {
        break;
      }
    }
    else for (last=14; last>0; last-=2)
    {
      if (file->ino->sb->dir[extent].pointers[last] || file->ino->sb->dir[extent].pointers[last+1])
      {
        last/=2;
        break;
      }
    }
    if (last>0) extentno+=(last*blocksize)/extcap;
    file->ino->sb->dir[extent].extnol=EXTENTL(extentno);
    file->ino->sb->dir[extent].extnoh=EXTENTH(extentno);
    file->ino->sb->dir[extent].blkcnt=((file->pos-1)%16384)/128+1;
    file->ino->sb->dir[extent].lrc=file->pos%128;
    updateTimeStamps(file->ino,extent);
    /*}}}*/
    if (file->pos==nextextpos) findext=1;
    else if (file->pos==nextblockpos) findblock=1;
  }
  return got;
}
/*}}}*/
/* cpmClose           -- close                                   */ /*{{{*/
int cpmClose(struct cpmFile *file)
{
  return 0;
}
/*}}}*/
/* cpmCreat           -- creat                                   */ /*{{{*/
int cpmCreat(struct cpmInode *dir, const char *fname, struct cpmInode *ino, mode_t mode)
{
  int user;
  char name[8],extension[3];
  int extent;
  struct cpmSuperBlock *drive;
  struct PhysDirectoryEntry *ent;

  if (!S_ISDIR(dir->mode))
  {
    boo="No such file or directory";
    return -1;
  }
  if (splitFilename(fname,dir->sb->type,name,extension,&user)==-1) return -1;
#ifdef CPMFS_DEBUG
  fprintf(stderr,"cpmCreat: %s -> %d:%-.8s.%-.3s\n",fname,user,name,extension);
#endif
  if (findFileExtent(dir->sb,user,name,extension,0,-1)!=-1) return -1;
  drive=dir->sb;
  if ((extent=findFreeExtent(dir->sb))==-1) return -1;
  ent=dir->sb->dir+extent;
  drive->dirtyDirectory=1;
  memset(ent,0,32);
  ent->status=user;
  memcpy(ent->name,name,8);
  memcpy(ent->ext,extension,3);
  ino->ino=extent;
  ino->mode=s_ifreg|mode;
  ino->size=0;
  time(&ino->atime);
  time(&ino->mtime);
  time(&ino->ctime);
  ino->sb=dir->sb;
  updateTimeStamps(ino,extent);
  return 0;
}
/*}}}*/
/* cpmAttrGet         -- get CP/M attributes                     */ /*{{{*/
int cpmAttrGet(struct cpmInode *ino, cpm_attr_t *attrib)
{
  *attrib = ino->attr;
  return 0;
}
/*}}}*/
/* cpmAttrSet         -- set CP/M attributes                     */ /*{{{*/
int cpmAttrSet(struct cpmInode *ino, cpm_attr_t attrib)
{
  struct cpmSuperBlock *drive;
  int extent;
  int user;
  char name[8], extension[3];
  
  memset(name,      0, sizeof(name));
  memset(extension, 0, sizeof(extension));
  drive  = ino->sb;
  extent = ino->ino;
  
  drive->dirtyDirectory=1;
  /* Strip off existing attribute bits */
  memcpy7(name,      drive->dir[extent].name, 8);
  memcpy7(extension, drive->dir[extent].ext,  3);
  user = drive->dir[extent].status;
  
  /* And set new ones */
  if (attrib & CPM_ATTR_F1)   name[0]      |= 0x80;
  if (attrib & CPM_ATTR_F2)   name[1]      |= 0x80;
  if (attrib & CPM_ATTR_F3)   name[2]      |= 0x80;
  if (attrib & CPM_ATTR_F4)   name[3]      |= 0x80;
  if (attrib & CPM_ATTR_RO)   extension[0] |= 0x80;
  if (attrib & CPM_ATTR_SYS)  extension[1] |= 0x80;
  if (attrib & CPM_ATTR_ARCV) extension[2] |= 0x80;
  
  do 
  {
    memcpy(drive->dir[extent].name, name, 8);
    memcpy(drive->dir[extent].ext, extension, 3);
  } while ((extent=findFileExtent(drive, user,name,extension,extent+1,-1))!=-1);

  /* Update the stored (inode) copies of the file attributes and mode */
  ino->attr=attrib;
  if (attrib&CPM_ATTR_RO) ino->mode&=~(S_IWUSR|S_IWGRP|S_IWOTH);
  else ino->mode|=(S_IWUSR|S_IWGRP|S_IWOTH);
  
  return 0;
}
/*}}}*/
/* cpmChmod           -- set CP/M r/o & sys                      */ /*{{{*/
int cpmChmod(struct cpmInode *ino, mode_t mode)
{
	/* Convert the chmod() into a chattr() call that affects RO */
	int newatt = ino->attr & ~CPM_ATTR_RO;

	if (!(mode & (S_IWUSR|S_IWGRP|S_IWOTH))) newatt |= CPM_ATTR_RO;
	return cpmAttrSet(ino, newatt);
}
/*}}}*/
/* cpmSync            -- write directory back                    */ /*{{{*/
int cpmSync(struct cpmSuperBlock *d)
{
  if (d->dirtyDirectory)
  {
    int i,blocks,entry;

    blocks=(d->maxdir*32+d->blksiz-1)/d->blksiz;
    entry=0;
    for (i=0; i<blocks; ++i) 
    {
      if (writeBlock(d,i,(char*)(d->dir+entry),0,-1)==-1) return -1;
      entry+=(d->blksiz/32);
    }
    d->dirtyDirectory=0;
  }
  return 0;
}
/*}}}*/
/* cpmUmount          -- free super block                        */ /*{{{*/
void cpmUmount(struct cpmSuperBlock *sb)
{
  cpmSync(sb);
  free(sb->alv);
  free(sb->skewtab);
  free(sb->dir);
  if (sb->passwdLength) free(sb->passwd);
}
/*}}}*/
