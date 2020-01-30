/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "device.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/

/* Device_open           -- Open an image file                      */ /*{{{*/
const char *Device_open(struct Device *this, const char *filename, int mode, const char *deviceOpts)
{
  this->fd=open(filename,mode);
  this->opened=(this->fd==-1?0:1);
  return ((this->fd==-1)?strerror(errno):(const char*)0);
}
/*}}}*/
/* Device_setGeometry    -- Set disk geometry                       */ /*{{{*/
const char *Device_setGeometry(struct Device *this, int secLength, int sectrk, int tracks, off_t offset, const char *libdskGeometry)
{
  this->secLength=secLength;
  this->sectrk=sectrk;
  this->tracks=tracks;
  this->offset=offset;
  return NULL;
}
/*}}}*/
/* Device_close          -- Close an image file                     */ /*{{{*/
const char *Device_close(struct Device *this)
{
  this->opened=0;
  return ((close(this->fd)==-1)?strerror(errno):(const char*)0);
}
/*}}}*/
/* Device_readSector     -- read a physical sector                  */ /*{{{*/
const char *Device_readSector(const struct Device *this, int track, int sector, char *buf)
{
  int res;

  assert(this);
  assert(sector>=0);
  assert(sector<this->sectrk);
  assert(track>=0);
  assert(track<this->tracks);
  assert(buf);
  if (lseek(this->fd,(off_t)(((sector+track*this->sectrk)*this->secLength)+this->offset),SEEK_SET)==-1) 
  {
    return strerror(errno);
  }
  if ((res=read(this->fd, buf, this->secLength)) != this->secLength) 
  {
    if (res==-1)
    {
      return strerror(errno);
    }
    else memset(buf+res,0,this->secLength-res); /* hit end of disk image */
  }
  return (const char*)0;
}
/*}}}*/
/* Device_writeSector    -- write physical sector                   */ /*{{{*/
const char *Device_writeSector(const struct Device *this, int track, int sector, const char *buf)
{
  assert(sector>=0);
  assert(sector<this->sectrk);
  assert(track>=0);
  assert(track<this->tracks);
  if (lseek(this->fd,(off_t)(((sector+track*this->sectrk)*this->secLength)+this->offset),SEEK_SET)==-1)
  {
    return strerror(errno);
  }
  if (write(this->fd, buf, this->secLength) == this->secLength) return (const char*)0;
  return strerror(errno);
}
/*}}}*/
