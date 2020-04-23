#ifndef DEVICE_H
#define DEVICE_H

#ifdef _WIN32
/* The type of device the file system is on: */
#define CPMDRV_FILE  0 /* Regular file or Unix block device */
#define CPMDRV_WIN95 1 /* Windows 95 floppy drive accessed via VWIN32 */
#define CPMDRV_WINNT 2 /* Windows NT floppy drive accessed via CreateFile */
#endif

struct Device
{
  int opened;

  int secLength;
  int tracks;
  int sectrk;
  off_t offset;
#if HAVE_LIBDSK_H
  DSK_PDRIVER   dev;
  DSK_GEOMETRY geom; 
#endif
#if HAVE_WINDOWS_H
  int drvtype;
  HANDLE hdisk;
#endif
  int fd;
};

const char *Device_open(struct Device *self, const char *filename, int mode, const char *deviceOpts);
const char *Device_setGeometry(struct Device *self, int secLength, int sectrk, int tracks, off_t offset, const char *libdskGeometry);
const char *Device_close(struct Device *self);
const char *Device_readSector(const struct Device *self, int track, int sector, char *buf);
const char *Device_writeSector(const struct Device *self, int track, int sector, const char *buf);

#endif
