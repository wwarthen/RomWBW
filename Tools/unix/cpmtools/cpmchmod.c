/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "getopt_.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/

const char cmd[]="cpmchmod";

int main(int argc, char *argv[]) /*{{{*/
{
  /* variables */ /*{{{*/
  const char *err;
  const char *image;
  const char *format;
  const char *devopts=NULL;
  int c,i,usage=0,exitcode=0;
  struct cpmSuperBlock drive;
  struct cpmInode root;
  int gargc;
  char **gargv;
  unsigned int mode; 
  /*}}}*/

  /* parse options */ /*{{{*/
  if (!(format=getenv("CPMTOOLSFMT"))) format=FORMAT;
  while ((c=getopt(argc,argv,"T:f:h?"))!=EOF) switch(c)
  {
    case 'T': devopts=optarg; break;
    case 'f': format=optarg; break;
    case 'h':
    case '?': usage=1; break;
  }

  if (optind>=(argc-2)) usage=1;
  else 
  {
    image=argv[optind++];
    if (!sscanf(argv[optind++], "%o", &mode)) usage=1;
  }    

  if (usage)
  {
    fprintf(stderr,"Usage: %s [-f format] image mode pattern ...\n",cmd);
    exit(1);
  }
  /*}}}*/
  /* open image */ /*{{{*/
  if ((err=Device_open(&drive.dev, image, O_RDWR, devopts)))
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
  cpmglob(optind,argc,argv,&root,&gargc,&gargv);
  for (i=0; i<gargc; ++i)
  {
    struct cpmInode ino;

    if (cpmNamei(&root,gargv[i], &ino)==-1)
    {
      fprintf(stderr,"%s: can not find %s: %s\n",cmd,gargv[i],boo);
      exitcode=1;
    }
    else if (cpmChmod(&ino, mode) == -1)
    {
      fprintf(stderr,"%s: Failed to set attributes for %s: %s\n",cmd,gargv[i],boo);
      exitcode=1;
    }
  }
  cpmUmount(&drive);
  exit(exitcode);
}
/*}}}*/
