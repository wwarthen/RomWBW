/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "getopt_.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/
/* #defines */ /*{{{*/
#ifndef O_BINARY
#define O_BINARY 0
#endif
/*}}}*/

/* mkfs -- make file system */ /*{{{*/
static int mkfs(struct cpmSuperBlock *drive, const char *name, const char *label, char *bootTracks)
{
  /* variables */ /*{{{*/
  int i;
  char buf[128];
  char firstbuf[128];
  int fd;
  int bytes;
  int trkbytes;
  /*}}}*/

  /* open image file */ /*{{{*/
  if ((fd = open(name, O_BINARY|O_CREAT|O_WRONLY, 0666)) < 0)
  {
    boo=strerror(errno);
    return -1;
  }
  /*}}}*/
  /* write system tracks */ /*{{{*/
  /* this initialises only whole tracks, so it skew is not an issue */
  trkbytes=drive->secLength*drive->sectrk;
  for (i=0; i<trkbytes*drive->boottrk; i+=drive->secLength) if (write(fd, bootTracks+i, drive->secLength)!=drive->secLength)
  {
    boo=strerror(errno);
    close(fd);
    return -1;
  }
  /*}}}*/
  /* write directory */ /*{{{*/
  memset(buf,0xe5,128);
  bytes=drive->maxdir*32;
  if (bytes%trkbytes) bytes=((bytes+trkbytes)/trkbytes)*trkbytes;
  if (drive->type==CPMFS_P2DOS || drive->type==CPMFS_DR3) buf[3*32]=0x21;
  memcpy(firstbuf,buf,128);
  if (drive->type==CPMFS_DR3)
  {
    time_t now;
    struct tm *t;
    int min,hour,days;

    firstbuf[0]=0x20;
    for (i=0; i<11 && *label; ++i,++label) firstbuf[1+i]=toupper(*label&0x7f);
    while (i<11) firstbuf[1+i++]=' ';
    firstbuf[12]=0x11; /* label set and first time stamp is creation date */
    memset(&firstbuf[13],0,1+2+8);
    time(&now);
    t=localtime(&now);
    min=((t->tm_min/10)<<4)|(t->tm_min%10);
    hour=((t->tm_hour/10)<<4)|(t->tm_hour%10);
    for (i=1978,days=0; i < 1900 + t->tm_year; ++i)
    {
      days+=365;
      if (i%4==0 && (i%100!=0 || i%400==0)) ++days;
    }
    days += t->tm_yday + 1;
    firstbuf[24]=firstbuf[28]=days&0xff; firstbuf[25]=firstbuf[29]=days>>8;
    firstbuf[26]=firstbuf[30]=hour;
    firstbuf[27]=firstbuf[31]=min;
  }
  for (i=0; i < bytes; i += 128) if (write(fd, i==0 ? firstbuf : buf, 128)!=128)
  {
    boo=strerror(errno);
    close(fd);
    return -1;
  }
  /*}}}*/
  /* close image file */ /*{{{*/
  if (close(fd)==-1)
  {
    boo=strerror(errno);
    return -1;
  }
  /*}}}*/
  return 0;
}
/*}}}*/

const char cmd[]="mkfs.cpm";

int main(int argc, char *argv[]) /*{{{*/
{
  char *image;
  const char *format=FORMAT;
  int c,usage=0;
  struct cpmSuperBlock drive;
  struct cpmInode root;
  const char *label="unlabeled";
  size_t bootTrackSize,used;
  char *bootTracks;
  const char *boot[4]={(const char*)0,(const char*)0,(const char*)0,(const char*)0};

  while ((c=getopt(argc,argv,"b:f:L:h?"))!=EOF) switch(c)
  {
    case 'b':
    {
      if (boot[0]==(const char*)0) boot[0]=optarg;
      else if (boot[1]==(const char*)0) boot[1]=optarg;
      else if (boot[2]==(const char*)0) boot[2]=optarg;
      else if (boot[3]==(const char*)0) boot[3]=optarg;
      else usage=1;
      break;
    }
    case 'f': format=optarg; break;
    case 'L': label=optarg; break;
    case 'h':
    case '?': usage=1; break;
  }

  if (optind!=(argc-1)) usage=1;
  else image=argv[optind++];

  if (usage)
  {
    fprintf(stderr,"Usage: %s [-f format] [-b boot] [-L label] image\n",cmd);
    exit(1);
  }
  drive.dev.opened=0;
  cpmReadSuper(&drive,&root,format);
  bootTrackSize=drive.boottrk*drive.secLength*drive.sectrk;
  if ((bootTracks=malloc(bootTrackSize))==(void*)0)
  {
    fprintf(stderr,"%s: can not allocate boot track buffer: %s\n",cmd,strerror(errno));
    exit(1);
  }
  memset(bootTracks,0xe5,bootTrackSize);
  used=0; 
  for (c=0; c<4 && boot[c]; ++c)
  {
    int fd;
    size_t size;

    if ((fd=open(boot[c],O_BINARY|O_RDONLY))==-1)
    {
      fprintf(stderr,"%s: can not open %s: %s\n",cmd,boot[c],strerror(errno));
      exit(1);
    }
    size=read(fd,bootTracks+used,bootTrackSize-used);
#if 0
    fprintf(stderr,"%d %04x %s\n",c,used+0x800,boot[c]);
#endif
    if (size%drive.secLength) size=(size|(drive.secLength-1))+1;
    used+=size;
    close(fd);
  }
  if (mkfs(&drive,image,label,bootTracks)==-1)
  {
    fprintf(stderr,"%s: can not make new file system: %s\n",cmd,boo);
    exit(1);
  }
  else exit(0);
}
/*}}}*/
