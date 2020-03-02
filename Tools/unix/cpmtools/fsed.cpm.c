/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <assert.h>
#include <ctype.h>
#if NEED_NCURSES
#if HAVE_NCURSES_NCURSES_H
#include <ncurses/ncurses.h>
#else
#include <ncurses.h>
#endif
#else
#include <curses.h>
#endif
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "cpmfs.h"
#include "getopt_.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/

extern char **environ;

static char *mapbuf;

static struct tm *cpmtime(char lday, char hday, char hour, char min) /*{{{*/
{
  static struct tm tm;
  unsigned long days=(lday&0xff)|((hday&0xff)<<8);
  int d;
  unsigned int md[12]={31,0,31,30,31,30,31,31,30,31,30,31};

  tm.tm_sec=0;
  tm.tm_min=((min>>4)&0xf)*10+(min&0xf);
  tm.tm_hour=((hour>>4)&0xf)*10+(hour&0xf);
  tm.tm_mon=0;
  tm.tm_year=1978;
  tm.tm_isdst=-1;
  if (days) --days;
  while (days>=(d=(((tm.tm_year%400)==0 || ((tm.tm_year%4)==0 && (tm.tm_year%100))) ? 366 : 365)))
  {
    days-=d;
    ++tm.tm_year;
  }
  md[1]=((tm.tm_year%400)==0 || ((tm.tm_year%4)==0 && (tm.tm_year%100))) ? 29 : 28;
  while (days>=md[tm.tm_mon])
  {
    days-=md[tm.tm_mon];
    ++tm.tm_mon;
  }
  tm.tm_mday=days+1;
  tm.tm_year-=1900;
  return &tm;
}
/*}}}*/
static void info(struct cpmSuperBlock *sb, const char *format, const char *image) /*{{{*/
{
  const char *msg;

  clear();
  msg="File system characteristics";
  move(0,(COLS-strlen(msg))/2); printw(msg);
  move(2,0); printw("                      Image: %s",image);
  move(3,0); printw("                     Format: %s",format);
  move(4,0); printw("                File system: ");
  switch (sb->type)
  {
    case CPMFS_DR22: printw("CP/M 2.2"); break;
    case CPMFS_P2DOS: printw("P2DOS 2.3"); break;
    case CPMFS_DR3: printw("CP/M Plus"); break;
  }

  move(6,0); printw("              Sector length: %d",sb->secLength);
  move(7,0); printw("           Number of tracks: %d",sb->tracks);
  move(8,0); printw("          Sectors per track: %d",sb->sectrk);

  move(10,0);printw("                 Block size: %d",sb->blksiz);
  move(11,0);printw("Number of directory entries: %d",sb->maxdir);
  move(12,0);printw("        Logical sector skew: %d",sb->skew);
  move(13,0);printw("    Number of system tracks: %d",sb->boottrk);
  move(14,0);printw(" Logical extents per extent: %d",sb->extents);
  move(15,0);printw("    Allocatable data blocks: %d",sb->size-(sb->maxdir*32+sb->blksiz-1)/sb->blksiz);

  msg="Any key to continue";
  move(23,(COLS-strlen(msg))/2); printw(msg);
  getch();
}
/*}}}*/
static void map(struct cpmSuperBlock *sb) /*{{{*/
{
  const char *msg;
  char bmap[18*80];
  int secmap,sys,directory;
  int pos;

  clear();
  msg="Data map";
  move(0,(COLS-strlen(msg))/2); printw(msg);

  secmap=(sb->tracks*sb->sectrk+80*18-1)/(80*18);
  memset(bmap,' ',sizeof(bmap));
  sys=sb->boottrk*sb->sectrk;
  memset(bmap,'S',sys/secmap);
  directory=(sb->maxdir*32+sb->secLength-1)/sb->secLength;
  memset(bmap+sys/secmap,'D',directory/secmap);
  memset(bmap+(sys+directory)/secmap,'.',sb->sectrk*sb->tracks/secmap);

  for (pos=0; pos<(sb->maxdir*32+sb->secLength-1)/sb->secLength; ++pos)
  {
    int entry;

    Device_readSector(&sb->dev,sb->boottrk+pos/(sb->sectrk*sb->secLength),pos/sb->secLength,mapbuf);
    for (entry=0; entry<sb->secLength/32 && (pos*sb->secLength/32)+entry<sb->maxdir; ++entry)
    {
      int i;

      if (mapbuf[entry*32]>=0 && mapbuf[entry*32]<=(sb->type==CPMFS_P2DOS ? 31 : 15))
      {
        for (i=0; i<16; ++i)
        {
          int sector;

          sector=mapbuf[entry*32+16+i]&0xff;
          if (sb->size>=256) sector|=(((mapbuf[entry*32+16+ ++i]&0xff)<<8));
          if (sector>0 && sector<=sb->size)
          {
            /* not entirely correct without the last extent record count */
            sector=sector*(sb->blksiz/sb->secLength)+sb->sectrk*sb->boottrk;
            memset(bmap+sector/secmap,'#',sb->blksiz/(sb->secLength*secmap));
          }
        }
      }
    }
  }

  for (pos=0; pos<(int)sizeof(bmap); ++pos)
  {
    move(2+pos%18,pos/18);
    addch(bmap[pos]);
  }
  move(21,0); printw("S=System area   D=Directory area   #=File data   .=Free");
  msg="Any key to continue";
  move(23,(COLS-strlen(msg))/2); printw(msg);
  getch();
}
/*}}}*/
static void data(struct cpmSuperBlock *sb, const char *buf, unsigned long int pos) /*{{{*/
{
  int offset=(pos%sb->secLength)&~0x7f;
  unsigned int i;

  for (i=0; i<128; ++i)
  {
    move(4+(i>>4),(i&0x0f)*3+!!(i&0x8)); printw("%02x",buf[i+offset]&0xff);
    if (pos%sb->secLength==i+offset) attron(A_REVERSE);
    move(4+(i>>4),50+(i&0x0f)); printw("%c",isprint(buf[i+offset]) ? buf[i+offset] : '.');
    attroff(A_REVERSE);
  }
  move(4+((pos&0x7f)>>4),((pos&0x7f)&0x0f)*3+!!((pos&0x7f)&0x8)+1);
}
/*}}}*/

const char cmd[]="fsed.cpm";

int main(int argc, char *argv[]) /*{{{*/
{
  /* variables */ /*{{{*/
  const char *devopts=(const char*)0;
  char *image;
  const char *err;
  struct cpmSuperBlock drive;
  struct cpmInode root;
  const char *format;
  int c,usage=0;
  off_t pos;
  chtype ch;
  int reload;
  char *buf;
  /*}}}*/

  /* parse options */ /*{{{*/
  if (!(format=getenv("CPMTOOLSFMT"))) format=FORMAT;
  while ((c=getopt(argc,argv,"T:f:h?"))!=EOF) switch(c)
  {
    case 'f': format=optarg; break;
    case 'T': devopts=optarg; break;
    case 'h':
    case '?': usage=1; break;
  }

  if (optind!=(argc-1)) usage=1;
  else image=argv[optind++];

  if (usage)
  {
    fprintf(stderr,"Usage: fsed.cpm [-f format] image\n");
    exit(1);
  }
  /*}}}*/
  /* open image */ /*{{{*/
  if ((err=Device_open(&drive.dev,image,O_RDONLY,devopts))) 
  {
    fprintf(stderr,"%s: cannot open %s (%s)\n",cmd,image,err);
    exit(1);
  }
  if (cpmReadSuper(&drive,&root,format)==-1)
  {
    fprintf(stderr,"%s: cannot read superblock (%s)\n",cmd,boo);
    exit(1);
  }
  /*}}}*/
  /* alloc sector buffers */ /*{{{*/
  if ((buf=malloc(drive.secLength))==(char*)0 || (mapbuf=malloc(drive.secLength))==(char*)0)
  {
    fprintf(stderr,"fsed.cpm: can not allocate sector buffer (%s).\n",strerror(errno));
    exit(1);
  }
  /*}}}*/
  /* init curses */ /*{{{*/
  initscr();
  noecho();
  raw();
  nonl();
  idlok(stdscr,TRUE);
  idcok(stdscr,TRUE);
  keypad(stdscr,TRUE);
  clear();
  /*}}}*/

  pos=0;
  reload=1;
  do
  {
    /* display position and load data */ /*{{{*/
    clear();
    move(2,0); printw("Byte %8lu (0x%08lx)  ",pos,pos);
    if (pos<(drive.boottrk*drive.sectrk*drive.secLength))
    {
      printw("Physical sector %3lu  ",((pos/drive.secLength)%drive.sectrk)+1);
    }
    else
    {
      printw("Sector %3lu ",((pos/drive.secLength)%drive.sectrk)+1);
      printw("(physical %3d)  ",drive.skewtab[(pos/drive.secLength)%drive.sectrk]+1);
    }
    printw("Offset %5lu  ",pos%drive.secLength);
    printw("Track %5lu",pos/(drive.secLength*drive.sectrk));
    move(LINES-3,0); printw("N)ext track    P)revious track");
    move(LINES-2,0); printw("n)ext record   p)revious record     f)orward byte      b)ackward byte");
    move(LINES-1,0); printw("i)nfo          q)uit");
    if (reload)
    {
      if (pos<(drive.boottrk*drive.sectrk*drive.secLength))
      {
        err=Device_readSector(&drive.dev,pos/(drive.secLength*drive.sectrk),(pos/drive.secLength)%drive.sectrk,buf);
      }
      else
      {
        err=Device_readSector(&drive.dev,pos/(drive.secLength*drive.sectrk),drive.skewtab[(pos/drive.secLength)%drive.sectrk],buf);
      }
      if (err)
      {
        move(4,0); printw("Data can not be read: %s",err);
      }
      else reload=0;
    }
    /*}}}*/

    if /* position before end of system area */ /*{{{*/
    (pos<(drive.boottrk*drive.sectrk*drive.secLength))
    {
      const char *msg;

      msg="System area"; move(0,(COLS-strlen(msg))/2); printw(msg);
      move(LINES-3,36); printw("F)orward 16 byte   B)ackward 16 byte");
      if (!reload) data(&drive,buf,pos);
      switch (ch=getch())
      {
        case 'F': /* next 16 byte */ /*{{{*/
        {
          if (pos+16<(drive.sectrk*drive.tracks*(off_t)drive.secLength))
          {
            if (pos/drive.secLength!=(pos+16)/drive.secLength) reload=1;
            pos+=16;
          }
          break;
        }
        /*}}}*/
        case 'B': /* previous 16 byte */ /*{{{*/
        {
          if (pos>=16)
          {
            if (pos/drive.secLength!=(pos-16)/drive.secLength) reload=1;
            pos-=16;
          }
          break;
        }
        /*}}}*/
      }
    }
    /*}}}*/
    else if /* position before end of directory area */ /*{{{*/
    (pos<(drive.boottrk*drive.sectrk*drive.secLength+drive.maxdir*32))
    {
      const char *msg;
      unsigned long entrystart=(pos&~0x1f)%drive.secLength;
      int entry=(pos-(drive.boottrk*drive.sectrk*drive.secLength))>>5;
      int offset=pos&0x1f;

      msg="Directory area"; move(0,(COLS-strlen(msg))/2); printw(msg);
      move(LINES-3,36); printw("F)orward entry     B)ackward entry");

      move(13,0); printw("Entry %3d: ",entry);      
      if /* free or used directory entry */ /*{{{*/
      ((buf[entrystart]>=0 && buf[entrystart]<=(drive.type==CPMFS_P2DOS ? 31 : 15)) || buf[entrystart]==(char)0xe5)
      {
        int i;

        if (buf[entrystart]==(char)0xe5)
        {
          if (offset==0) attron(A_REVERSE);
          printw("Free");
          attroff(A_REVERSE);
        }
        else printw("Directory entry");
        move(15,0);
        if (buf[entrystart]!=(char)0xe5)
        {
          printw("User: ");
          if (offset==0) attron(A_REVERSE);
          printw("%2d",buf[entrystart]);
          attroff(A_REVERSE);
          printw(" ");
        }
        printw("Name: ");
        for (i=0; i<8; ++i)
        {
          if (offset==1+i) attron(A_REVERSE);
          printw("%c",buf[entrystart+1+i]&0x7f);
          attroff(A_REVERSE);
        }
        printw(" Extension: ");
        for (i=0; i<3; ++i)
        {
          if (offset==9+i) attron(A_REVERSE);
          printw("%c",buf[entrystart+9+i]&0x7f);
          attroff(A_REVERSE);
        }
        move(16,0); printw("Extent: %3d",((buf[entrystart+12]&0xff)+((buf[entrystart+14]&0xff)<<5))/drive.extents);
        printw(" (low: ");
        if (offset==12) attron(A_REVERSE);
        printw("%2d",buf[entrystart+12]&0xff);
        attroff(A_REVERSE);
        printw(", high: ");
        if (offset==14) attron(A_REVERSE);
        printw("%2d",buf[entrystart+14]&0xff);
        attroff(A_REVERSE);
        printw(")");
        move(17,0); printw("Last extent record count: ");
        if (offset==15) attron(A_REVERSE);
        printw("%3d",buf[entrystart+15]&0xff);
        attroff(A_REVERSE);
        move(18,0); printw("Last record byte count: ");
        if (offset==13) attron(A_REVERSE);
        printw("%3d",buf[entrystart+13]&0xff);
        attroff(A_REVERSE);
        move(19,0); printw("Data blocks:");
        for (i=0; i<16; ++i)
        {
          unsigned int block=buf[entrystart+16+i]&0xff;
          if (drive.size>=256)
          {
            printw(" ");
            if (offset==16+i || offset==16+i+1) attron(A_REVERSE);
            printw("%5d",block|(((buf[entrystart+16+ ++i]&0xff)<<8)));
            attroff(A_REVERSE);
          }
          else
          {
            printw(" ");
            if (offset==16+i) attron(A_REVERSE);
            printw("%3d",block);
            attroff(A_REVERSE);
          }
        }
      }
      /*}}}*/
      else if /* disc label */ /*{{{*/
      (buf[entrystart]==0x20 && drive.type==CPMFS_DR3)
      {
        int i;
        const struct tm *tm;
        char s[30];

        if (offset==0) attron(A_REVERSE);
        printw("Disc label");
        attroff(A_REVERSE);
        move(15,0);
        printw("Label: ");
        for (i=0; i<11; ++i)
        {
          if (i+1==offset) attron(A_REVERSE);
          printw("%c",buf[entrystart+1+i]&0x7f);
          attroff(A_REVERSE);
        }
        move(16,0);
        printw("Bit 0,7: ");
        if (offset==12) attron(A_REVERSE);
        printw("Label %s",buf[entrystart+12]&1 ? "set" : "not set");
        printw(", password protection %s",buf[entrystart+12]&0x80 ? "set" : "not set");
        attroff(A_REVERSE);
        move(17,0);
        printw("Bit 4,5,6: ");
        if (offset==12) attron(A_REVERSE);
        printw("Time stamp ");
        if (buf[entrystart+12]&0x10) printw("on create, ");
        else printw("not on create, ");
        if (buf[entrystart+12]&0x20) printw("on modification, ");
        else printw("not on modifiction, ");
        if (buf[entrystart+12]&0x40) printw("on access");
        else printw("not on access");
        attroff(A_REVERSE); 
        move(18,0);
        printw("Password: ");
        for (i=0; i<8; ++i)
        {
          char printable;

          if (offset==16+(7-i)) attron(A_REVERSE);
          printable=(buf[entrystart+16+(7-i)]^buf[entrystart+13])&0x7f;
          printw("%c",isprint(printable) ? printable : ' ');
          attroff(A_REVERSE);
        }
        printw(" XOR value: ");
        if (offset==13) attron(A_REVERSE);
        printw("0x%02x",buf[entrystart+13]&0xff);
        attroff(A_REVERSE);
        move(19,0);
        printw("Created: ");
        tm=cpmtime(buf[entrystart+24],buf[entrystart+25],buf[entrystart+26],buf[entrystart+27]);
        if (offset==24 || offset==25) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==26) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==27) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
        printw(" Updated: ");
        tm=cpmtime(buf[entrystart+28],buf[entrystart+29],buf[entrystart+30],buf[entrystart+31]);
        if (offset==28 || offset==29) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==30) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==31) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
      }
      /*}}}*/
      else if /* time stamp */ /*{{{*/
      (buf[entrystart]==0x21 && (drive.type==CPMFS_P2DOS || drive.type==CPMFS_DR3))
      {
        const struct tm *tm;
        char s[30];

        if (offset==0) attron(A_REVERSE);
        printw("Time stamps");
        attroff(A_REVERSE);
        move(15,0);
        printw("3rd last extent: Created/Accessed ");
        tm=cpmtime(buf[entrystart+1],buf[entrystart+2],buf[entrystart+3],buf[entrystart+4]);
        if (offset==1 || offset==2) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==3) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==4) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
        printw(" Modified ");
        tm=cpmtime(buf[entrystart+5],buf[entrystart+6],buf[entrystart+7],buf[entrystart+8]);
        if (offset==5 || offset==6) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==7) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==8) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);

        move(16,0);
        printw("2nd last extent: Created/Accessed ");
        tm=cpmtime(buf[entrystart+11],buf[entrystart+12],buf[entrystart+13],buf[entrystart+14]);
        if (offset==11 || offset==12) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==13) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==14) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
        printw(" Modified ");
        tm=cpmtime(buf[entrystart+15],buf[entrystart+16],buf[entrystart+17],buf[entrystart+18]);
        if (offset==15 || offset==16) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==17) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==18) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);

        move(17,0);
        printw("    Last extent: Created/Accessed ");
        tm=cpmtime(buf[entrystart+21],buf[entrystart+22],buf[entrystart+23],buf[entrystart+24]);
        if (offset==21 || offset==22) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==23) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==24) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
        printw(" Modified ");
        tm=cpmtime(buf[entrystart+25],buf[entrystart+26],buf[entrystart+27],buf[entrystart+28]);
        if (offset==25 || offset==26) attron(A_REVERSE);
        strftime(s,sizeof(s),"%x",tm);
        printw("%s",s);
        attroff(A_REVERSE);
        printw(" ");
        if (offset==27) attron(A_REVERSE);
        printw("%2d",tm->tm_hour);
        attroff(A_REVERSE);
        printw(":");
        if (offset==28) attron(A_REVERSE);
        printw("%02d",tm->tm_min);
        attroff(A_REVERSE);
      }
      /*}}}*/
      else if /* password */ /*{{{*/
      (buf[entrystart]>=16 && buf[entrystart]<=31 && drive.type==CPMFS_DR3)
      {
        int i;

        if (offset==0) attron(A_REVERSE);
        printw("Password");
        attroff(A_REVERSE);

        move(15,0);
        printw("Name: ");
        for (i=0; i<8; ++i)
        {
          if (offset==1+i) attron(A_REVERSE);
          printw("%c",buf[entrystart+1+i]&0x7f);
          attroff(A_REVERSE);
        }
        printw(" Extension: ");
        for (i=0; i<3; ++i)
        {
          if (offset==9+i) attron(A_REVERSE);
          printw("%c",buf[entrystart+9+i]&0x7f);
          attroff(A_REVERSE);
        }

        move(16,0);
        printw("Password required for: ");
        if (offset==12) attron(A_REVERSE);
        if (buf[entrystart+12]&0x80) printw("Reading ");
        if (buf[entrystart+12]&0x40) printw("Writing ");
        if (buf[entrystart+12]&0x20) printw("Deleting ");
        attroff(A_REVERSE);

        move(17,0);
        printw("Password: ");
        for (i=0; i<8; ++i)
        {
          char printable;

          if (offset==16+(7-i)) attron(A_REVERSE);
          printable=(buf[entrystart+16+(7-i)]^buf[entrystart+13])&0x7f;
          printw("%c",isprint(printable) ? printable : ' ');
          attroff(A_REVERSE);
        }
        printw(" XOR value: ");
        if (offset==13) attron(A_REVERSE);
        printw("0x%02x",buf[entrystart+13]&0xff);
        attroff(A_REVERSE);
      }
      /*}}}*/
      else /* bad status */ /*{{{*/
      {
        printw("Bad status ");
        if (offset==0) attron(A_REVERSE);
        printw("0x%02x",buf[entrystart]);
        attroff(A_REVERSE);
      }
      /*}}}*/
      if (!reload) data(&drive,buf,pos);
      switch (ch=getch())
      {
        case 'F': /* next entry */ /*{{{*/
        {
          if (pos+32<(drive.sectrk*drive.tracks*(off_t)drive.secLength))
          {
            if (pos/drive.secLength!=(pos+32)/drive.secLength) reload=1;
            pos+=32;
          }
          break;
        }
        /*}}}*/
        case 'B': /* previous entry */ /*{{{*/
        {
          if (pos>=32)
          {
            if (pos/drive.secLength!=(pos-32)/drive.secLength) reload=1;
            pos-=32;
          }
          break;
        }
        /*}}}*/
      }
    }
    /*}}}*/
    else /* data area */ /*{{{*/
    {
      const char *msg;

      msg="Data area"; move(0,(COLS-strlen(msg))/2); printw(msg);
      if (!reload) data(&drive,buf,pos);
      ch=getch();
    }
    /*}}}*/

    /* process common commands */ /*{{{*/
    switch (ch)
    {
      case 'n': /* next record */ /*{{{*/
      {
        if (pos+128<(drive.sectrk*drive.tracks*(off_t)drive.secLength))
        {
          if (pos/drive.secLength!=(pos+128)/drive.secLength) reload=1;
          pos+=128;
        }
        break;
      }
      /*}}}*/
      case 'p': /* previous record */ /*{{{*/
      {
        if (pos>=128)
        {
          if (pos/drive.secLength!=(pos-128)/drive.secLength) reload=1;
          pos-=128;
        }
        break;
      }
      /*}}}*/
      case 'N': /* next track */ /*{{{*/
      {
        if ((pos+drive.sectrk*drive.secLength)<(drive.sectrk*drive.tracks*drive.secLength))
        {
          pos+=drive.sectrk*drive.secLength;
          reload=1;
        }
        break;
      }
      /*}}}*/
      case 'P': /* previous track */ /*{{{*/
      {
        if (pos>=drive.sectrk*drive.secLength)
        {
          pos-=drive.sectrk*drive.secLength;
          reload=1;
        }
        break;
      }
      /*}}}*/
      case 'b': /* byte back */ /*{{{*/
      {
        if (pos)
        {
          if (pos/drive.secLength!=(pos-1)/drive.secLength) reload=1;
          --pos;
        }
        break;
      }
      /*}}}*/
      case 'f': /* byte forward */ /*{{{*/
      {
        if (pos+1<drive.tracks*drive.sectrk*drive.secLength)
        {
          if (pos/drive.secLength!=(pos+1)/drive.secLength) reload=1;
          ++pos;
        }
        break;
      }
      /*}}}*/
      case 'i': info(&drive,format,image); break;
      case 'm': map(&drive); break;
    }
    /*}}}*/
  } while (ch!='q');

  /* exit curses */ /*{{{*/
  move(LINES-1,0);
  refresh();
  echo();
  noraw();
  endwin();
  /*}}}*/
  exit(0);
}
/*}}}*/
