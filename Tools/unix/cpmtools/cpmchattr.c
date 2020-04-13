/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "getopt_.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/

const char cmd[]="cpmchattr";

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
  const char *attrs; 
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
    attrs = argv[optind++];
  }    

  if (usage)
  {
    fprintf(stderr,"Usage: %s [-f format] [-T dsktype] image [NMrsa1234] pattern ...\n",cmd);
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
    int rc;
    cpm_attr_t attrib;

    rc = cpmNamei(&root,gargv[i], &ino)==-1;
    if (!rc) rc = cpmAttrGet(&ino, &attrib);
    if (!rc)
    {
        unsigned int n;
        int m;

        m = 0;
	for (n = 0; n < strlen(attrs); n++)
	{
          int mask = 0;
	  switch (attrs[n])
          {
            case 'n':
            case 'N': mask = 0; attrib = 0; break;
            case 'm':
            case 'M': mask = 0; m = !m;   break;
            case '1': mask = CPM_ATTR_F1; break;
            case '2': mask = CPM_ATTR_F2; break;
            case '3': mask = CPM_ATTR_F3; break;
            case '4': mask = CPM_ATTR_F4; break;
            case 'r': 
            case 'R': mask = CPM_ATTR_RO; break;
            case 's':
            case 'S': mask = CPM_ATTR_SYS; break;
            case 'a':
            case 'A': mask = CPM_ATTR_ARCV; break;
	    default: fprintf(stderr, "%s: Unknown attribute %c\n", cmd, attrs[n]);
                     exit(1);
          } 
          if (m) attrib &= ~mask; else attrib |= mask;
	}
        rc = cpmAttrSet(&ino, attrib);
    }
    if (rc)
    {
      fprintf(stderr,"%s: can not set attributes for %s: %s\n",cmd,gargv[i],boo);
      exitcode=1;
    }
  }
  cpmUmount(&drive);
  exit(exitcode);
}
/*}}}*/
