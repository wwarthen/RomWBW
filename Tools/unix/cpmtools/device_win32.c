/* #includes */ /*{{{C}}}*//*{{{*/
#include "config.h"

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <stdio.h>

#include "cpmdir.h"
#include "cpmfs.h"

#ifdef USE_DMALLOC
#include <dmalloc.h>
#endif
/*}}}*/
/* types */ /*{{{*/
#define PHYSICAL_SECTOR_1       1 /* First physical sector */

/* Use the INT13 interface rather than INT25/INT26. This appears to
 * improve performance, but is less well tested. */
#define USE_INT13

/* Windows 95 disk I/O functions - based on Stan Mitchell's DISKDUMP.C */
#define VWIN32_DIOC_DOS_IOCTL   1   /* DOS ioctl calls 4400h-4411h */
#define VWIN32_DIOC_DOS_INT25   2   /* absolute disk read, DOS int 25h */
#define VWIN32_DIOC_DOS_INT26   3   /* absolute disk write, DOS int 26h */
#define VWIN32_DIOC_DOS_INT13   4   /* BIOS INT13 functions */

typedef struct _DIOC_REGISTERS {
    DWORD reg_EBX;
    DWORD reg_EDX;
    DWORD reg_ECX;
    DWORD reg_EAX;
    DWORD reg_EDI;
    DWORD reg_ESI;
    DWORD reg_Flags;
    }
    DIOC_REGISTERS, *PDIOC_REGISTERS;

#define   LEVEL0_LOCK   0
#define   LEVEL1_LOCK   1
#define   LEVEL2_LOCK   2
#define   LEVEL3_LOCK   3
#define   LEVEL1_LOCK_MAX_PERMISSION      0x0001

#define   DRIVE_IS_REMOTE                 0x1000
#define   DRIVE_IS_SUBST                  0x8000

/*********************************************************
 **** Note: all MS-DOS data structures must be packed ****
 ****       on a one-byte boundary.                   ****
 *********************************************************/
#pragma pack(1)

typedef struct _DISKIO {
    DWORD diStartSector;    /* sector number to start at */
    WORD  diSectors;        /* number of sectors */
    DWORD diBuffer;         /* address of buffer */
    }
    DISKIO, *PDISKIO;

typedef struct MID {
    WORD  midInfoLevel;       /* information level, must be 0 */
    DWORD midSerialNum;       /* serial number for the medium */
    char  midVolLabel[11];    /* volume label for the medium */
    char  midFileSysType[8];  /* type of file system as 8-byte ASCII */
    }
    MID, *PMID;

typedef struct driveparams {    /* Disk geometry */
    BYTE special;
    BYTE devicetype;
    WORD deviceattrs;
    WORD cylinders;
    BYTE mediatype;
    /* BPB starts here */
    WORD bytespersector;
    BYTE sectorspercluster;
    WORD reservedsectors;
    BYTE numberofFATs;
    WORD rootdirsize;
    WORD totalsectors;
    BYTE mediaid;
    WORD sectorsperfat;
    WORD sectorspertrack;
    WORD heads;
    DWORD hiddensectors;
    DWORD bigtotalsectors;
    BYTE  reserved[6];
    /* BPB ends here */
    WORD sectorcount;
    WORD sectortable[80];
    } DRIVEPARAMS, *PDRIVEPARAMS;
/*}}}*/

static char *strwin32error(void) /*{{{*/
{
    static char buffer[1024];

    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* Default language */
                  (LPTSTR)buffer,
                  1023, NULL);
    return buffer;
}
/*}}}*/
static BOOL LockVolume( HANDLE hDisk ) /*{{{*/
{
    DWORD ReturnedByteCount;

    return DeviceIoControl( hDisk, FSCTL_LOCK_VOLUME, NULL, 0, NULL,
                0, &ReturnedByteCount, NULL );
}
/*}}}*/
static BOOL UnlockVolume( HANDLE hDisk )  /*{{{*/
{
    DWORD ReturnedByteCount;

    return DeviceIoControl( hDisk, FSCTL_UNLOCK_VOLUME, NULL, 0, NULL,
                0, &ReturnedByteCount, NULL );
}
/*}}}*/
static BOOL DismountVolume( HANDLE hDisk ) /*{{{*/
{
    DWORD ReturnedByteCount;

    return DeviceIoControl( hDisk, FSCTL_DISMOUNT_VOLUME, NULL, 0, NULL,
                0, &ReturnedByteCount, NULL );
}
/*}}}*/
static int GetDriveParams( HANDLE hVWin32Device, int volume, DRIVEPARAMS* pParam ) /*{{{*/
  {
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x440d; /* IOCTL for block device */
  reg.reg_EBX = volume; /* one-based drive number */
  reg.reg_ECX = 0x0860; /* Get Device params */
  reg.reg_EDX = (DWORD)pParam;
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 

  if ( !bResult || (reg.reg_Flags & 1) ) 
      return (reg.reg_EAX & 0xffff);

  return 0;
  }
/*}}}*/
static int SetDriveParams( HANDLE hVWin32Device, int volume, DRIVEPARAMS* pParam ) /*{{{*/
  {
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x440d; /* IOCTL for block device */
  reg.reg_EBX = volume; /* one-based drive number */
  reg.reg_ECX = 0x0840; /* Set Device params */
  reg.reg_EDX = (DWORD)pParam;
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 

  if ( !bResult || (reg.reg_Flags & 1) ) 
      return (reg.reg_EAX & 0xffff);

  return 0;
  }
/*}}}*/
static int GetMediaID( HANDLE hVWin32Device, int volume, MID* pMid ) /*{{{*/
  {
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x440d; /* IOCTL for block device */
  reg.reg_EBX = volume; /* one-based drive number */
  reg.reg_ECX = 0x0866; /* Get Media ID */
  reg.reg_EDX = (DWORD)pMid;
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 );

  if ( !bResult || (reg.reg_Flags & 1) ) 
      return (reg.reg_EAX & 0xffff);

  return 0;
  }
/*}}}*/
static int VolumeCheck(HANDLE hVWin32Device, int volume, WORD* flags ) /*{{{*/
{
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x4409; /* Is Drive Remote */
  reg.reg_EBX = volume; /* one-based drive number */
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 

  if ( !bResult || (reg.reg_Flags & 1) ) 
      return (reg.reg_EAX & 0xffff);

  *flags = (WORD)(reg.reg_EDX & 0xffff);
  return 0;
}
/*}}}*/
static int LockLogicalVolume(HANDLE hVWin32Device, int volume, int lock_level, int permissions) /*{{{*/
{
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x440d; /* generic IOCTL */
  reg.reg_ECX = 0x084a; /* lock logical volume */
  reg.reg_EBX = volume | (lock_level << 8);
  reg.reg_EDX = permissions;
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 

  if ( !bResult || (reg.reg_Flags & 1) ) 
      return (reg.reg_EAX & 0xffff);

  return 0;
}
/*}}}*/
static int UnlockLogicalVolume( HANDLE hVWin32Device, int volume ) /*{{{*/
{
  DIOC_REGISTERS reg;
  BOOL bResult;
  DWORD cb;

  reg.reg_EAX = 0x440d;
  reg.reg_ECX = 0x086a; /* lock logical volume  */
  reg.reg_EBX = volume;
  reg.reg_Flags = 1; /* preset the carry flag */

  bResult = DeviceIoControl( hVWin32Device, VWIN32_DIOC_DOS_IOCTL,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 

  if ( !bResult || (reg.reg_Flags & 1) ) return -1;
  return 0;
}
/*}}}*/
static int w32mode(int mode) /*{{{*/
{
    switch(mode)
    {
        case O_RDONLY: return GENERIC_READ;
        case O_WRONLY: return GENERIC_WRITE;
    }
    return GENERIC_READ | GENERIC_WRITE;
}
/*}}}*/

/* Device_open           -- Open an image file                      */ /*{{{*/
const char *Device_open(struct Device *sb, const char *filename, int mode, const char *deviceOpts)
{
    /* Windows 95/NT: floppy drives using handles */ 
    if (strlen(filename) == 2 && filename[1] == ':')    /* Drive name */
    {
        char vname[20];
        DWORD dwVers;

        sb->fd = -1;
        dwVers = GetVersion();

        if (dwVers & 0x80000000L) /* Win32s (3.1) or Win32c (Win95) */
        {
            int lock, driveno, res, permissions;
            unsigned short drive_flags;
            MID media;

            vname[0] = toupper(filename[0]);
            driveno = vname[0] - 'A' + 1;   /* 1=A: 2=B: */
            sb->drvtype = CPMDRV_WIN95;
            sb->hdisk   = CreateFile( "\\\\.\\vwin32",
                                       0,
                                       0,
                                       NULL,
                                       0,
                                       FILE_FLAG_DELETE_ON_CLOSE,
                                       NULL );
            if (!sb->hdisk)
            {
                return "Failed to open VWIN32 driver.";
            }
            if (VolumeCheck(sb->hdisk, driveno, &drive_flags))
            {
                CloseHandle(sb->hdisk);
                return "Invalid drive";
            } 
            res = GetMediaID( sb->hdisk, driveno, &media );
            if ( res )
            {
                const char *lboo = NULL;

                if ( res == ERROR_INVALID_FUNCTION && 
                            (drive_flags & DRIVE_IS_REMOTE )) 
                     lboo = "Network drive";
                else if (res == ERROR_ACCESS_DENIED) lboo = "Access denied";
                /* nb: It's perfectly legitimate for GetMediaID() to fail; most CP/M */
                /*     CP/M disks won't have a media ID. */ 
           
                if (lboo != NULL)
                {
                   CloseHandle(sb->hdisk);
                   return lboo;
                }
            }
            if (!res && 
                (!memcmp( media.midFileSysType, "CDROM", 5 ) ||
                 !memcmp( media.midFileSysType, "CD001", 5 ) ||
                 !memcmp( media.midFileSysType, "CDAUDIO", 5 )))
            {
                CloseHandle(sb->hdisk);
                return "CD-ROM drive";
            }
            if (w32mode(mode) & GENERIC_WRITE)
            {
                lock = LEVEL0_LOCK; /* Exclusive access */
                permissions = 0;
            }
            else
            {
                lock = LEVEL1_LOCK; /* Allow other processes access */
                permissions = LEVEL1_LOCK_MAX_PERMISSION;
            }
            if (LockLogicalVolume( sb->hdisk, driveno, lock, permissions))
            {
                CloseHandle(sb->hdisk);
                return "Could not acquire a lock on the drive.";
            }
 
            sb->fd = driveno;   /* 1=A: 2=B: etc - we will need this later */
            
        }
        else
        {
            sprintf(vname, "\\\\.\\%s", filename);
            sb->drvtype = CPMDRV_WINNT;
            sb->hdisk   = CreateFile(vname,         /* Name */
                                     w32mode(mode), /* Access mode */
                                     FILE_SHARE_READ|FILE_SHARE_WRITE, /*Sharing*/
                                     NULL,          /* Security attributes */ 
                                     OPEN_EXISTING, /* See MSDN */
                                     0,             /* Flags & attributes */
                                     NULL);         /* Template file */

            if (sb->hdisk != INVALID_HANDLE_VALUE)
            {
                sb->fd = 1;   /* Arbitrary value >0 */
                if (LockVolume(sb->hdisk) == FALSE)    /* Lock drive */
                {
                    char *lboo = strwin32error();
                    CloseHandle(sb->hdisk);
                    sb->fd = -1;
                    return lboo;
                }
            }
            else return strwin32error();
        }
        sb->opened = 1;
        return NULL;
    }

    /* Not a floppy. Treat it as a normal file */

    mode |= O_BINARY;
    sb->fd = open(filename, mode);
    if (sb->fd == -1) return strerror(errno);
    sb->drvtype = CPMDRV_FILE;
    sb->opened  = 1;
    return NULL;
}
/*}}}*/
/* Device_setGeometry    -- Set disk geometry                       */ /*{{{*/
const char * Device_setGeometry(struct Device *this, int secLength, int sectrk, int tracks, off_t offset, const char *libdskGeometry)
{
  int n;

  this->secLength=secLength;
  this->sectrk=sectrk;
  this->tracks=tracks;
  // Bill Buckels - add this->offset
  this->offset=offset;


  // Bill Buckels - not sure what to do here
  if (this->drvtype == CPMDRV_WIN95)
  {
      DRIVEPARAMS drvp;
      memset(&drvp, 0, sizeof(drvp));
      if (GetDriveParams( this->hdisk, this->fd, &drvp )) return "GetDriveParams failed";

      drvp.bytespersector  = secLength;
      drvp.sectorspertrack = sectrk;
      drvp.totalsectors    = sectrk * tracks;

/* Guess the cylinder/head configuration from the track count. This will
 * get single-sided 80-track discs wrong, but it's that or double-sided
 * 40-track (or add cylinder/head counts to diskdefs) 
 */
      if (tracks < 44)
      {
        drvp.cylinders       = tracks;
        drvp.heads           = 1;
      }
      else
      {
        drvp.cylinders       = tracks / 2;
        drvp.heads           = 2;
      }

/* Set up "reasonable" values for the other members */

      drvp.sectorspercluster = 1024 / secLength;
      drvp.reservedsectors   = 1;
      drvp.numberofFATs      = 2;
      drvp.sectorcount       = sectrk;
      drvp.rootdirsize       = 64;
      drvp.mediaid           = 0xF0;
      drvp.hiddensectors     = 0;
      drvp.sectorsperfat     = 3;
      for (n = 0; n < sectrk; n++)
      {
          drvp.sectortable[n*2]   = n + PHYSICAL_SECTOR_1;    /* Physical sector numbers */ 
          drvp.sectortable[n*2+1] = secLength;
      }
      drvp.special = 6;
/* We have not set:

    drvp.mediatype   
    drvp.devicetype  
    drvp.deviceattrs  

    which should have been read correctly by GetDriveParams().
  */
      SetDriveParams( this->hdisk, this->fd, &drvp );
  }
  return NULL;
}
/*}}}*/
/* Device_close          -- Close an image file                     */ /*{{{*/
const char *Device_close(struct Device *sb)
{
    sb->opened = 0;
    switch(sb->drvtype)
    {
        case CPMDRV_WIN95:
            UnlockLogicalVolume(sb->hdisk, sb->fd );
            if (!CloseHandle( sb->hdisk )) return strwin32error();
            return NULL;

        case CPMDRV_WINNT:
            DismountVolume(sb->hdisk);
            UnlockVolume(sb->hdisk);
            if (!CloseHandle(sb->hdisk)) return strwin32error();
            return NULL; 
    }
    if (close(sb->fd)) return strerror(errno);
    return NULL; 
}
/*}}}*/
/* Device_readSector     -- read a physical sector                  */ /*{{{*/
const char *Device_readSector(const struct Device *drive, int track, int sector, char *buf)
{
  int res;
  off_t offset;

  assert(sector>=0);
  assert(sector<drive->sectrk);
  assert(track>=0);
  assert(track<drive->tracks);

  offset = ((sector+track*drive->sectrk)*drive->secLength);

  if (drive->drvtype == CPMDRV_WINNT)
  {
        LPVOID iobuffer;
        DWORD  bytesread;
    
        // Bill Buckels - add drive->offset
        if (SetFilePointer(drive->hdisk, offset+drive->offset, NULL, FILE_BEGIN) == INVALID_FILE_SIZE)
        {
            return strwin32error();
        }
        iobuffer = VirtualAlloc(NULL, drive->secLength, MEM_COMMIT, PAGE_READWRITE);
        if (!iobuffer) 
        {
            return strwin32error();
        }
        res = ReadFile(drive->hdisk, iobuffer, drive->secLength, &bytesread, NULL);
        if (!res)
        {
            char *lboo = strwin32error();
            VirtualFree(iobuffer, drive->secLength, MEM_RELEASE);
            return lboo;
        } 

        memcpy(buf, iobuffer, drive->secLength);
        VirtualFree(iobuffer, drive->secLength, MEM_RELEASE);

        if (bytesread < (unsigned)drive->secLength)
        {
            memset(buf + bytesread, 0, drive->secLength - bytesread);
        }
        return NULL;
  }

  // Bill Buckels - not sure what to do here
  if (drive->drvtype == CPMDRV_WIN95)
  {
        DIOC_REGISTERS reg;
        BOOL bResult;
        DWORD cb;

#ifdef USE_INT13
        int cyl, head;

        if (drive->tracks < 44) { cyl = track;    head = 0; }
        else                    { cyl = track/2;  head = track & 1; }

        reg.reg_EAX      = 0x0201;  /* Read 1 sector */
        reg.reg_EBX      = (DWORD)buf;
        reg.reg_ECX      = (cyl << 8)  | (sector + PHYSICAL_SECTOR_1);
        reg.reg_EDX      = (head << 8) | (drive->fd - 1);
        reg.reg_Flags    = 1;       /* preset the carry flag */
        bResult          = DeviceIoControl( drive->hdisk, VWIN32_DIOC_DOS_INT13,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 );
#else
        DISKIO di;

        reg.reg_EAX      = drive->fd - 1;  /* zero-based volume number */
        reg.reg_EBX      = (DWORD)&di;
        reg.reg_ECX      = 0xffff;  /* use DISKIO structure */
        reg.reg_Flags    = 1;       /* preset the carry flag */
        di.diStartSector = sector+track*drive->sectrk;
        di.diSectors     = 1;
        di.diBuffer      = (DWORD)buf;
        bResult          = DeviceIoControl( drive->hdisk, VWIN32_DIOC_DOS_INT25,
             &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 );

#endif
        if ( !bResult || (reg.reg_Flags & 1) )
        {
            if (GetLastError()) return strwin32error();
            return "Unknown read error.";
        }
        return 0;
  }

  // Bill Buckels - add drive->offset
  if (lseek(drive->fd,offset+drive->offset,SEEK_SET)==-1)
  {
    return strerror(errno);
  }
  if ((res=read(drive->fd, buf, drive->secLength)) != drive->secLength)
  {
    if (res==-1)
    {
      return strerror(errno);
    }
    else memset(buf+res,0,drive->secLength-res); /* hit end of disk image */
  }
  return NULL;
}
/*}}}*/
/* Device_writeSector    -- write physical sector                   */ /*{{{*/
const char *Device_writeSector(const struct Device *drive, int track, int sector, const char *buf)
{
  off_t offset;
  int res;

  assert(sector>=0);
  assert(sector<drive->sectrk);
  assert(track>=0);
  assert(track<drive->tracks);

  offset = ((sector+track*drive->sectrk)*drive->secLength);

  if (drive->drvtype == CPMDRV_WINNT)
  {
        LPVOID iobuffer;
        DWORD  byteswritten;

        // Bill Buckels - add drive->offset
        if (SetFilePointer(drive->hdisk, offset+drive->offset, NULL, FILE_BEGIN) == INVALID_FILE_SIZE)
        {
            return strwin32error();
        }
        iobuffer = VirtualAlloc(NULL, drive->secLength, MEM_COMMIT, PAGE_READWRITE);
        if (!iobuffer)
        {
            return strwin32error();
        }
        memcpy(iobuffer, buf, drive->secLength);
        res = WriteFile(drive->hdisk, iobuffer, drive->secLength, &byteswritten, NULL);
        if (!res || (byteswritten < (unsigned)drive->secLength))
        {
            char *lboo = strwin32error();
            VirtualFree(iobuffer, drive->secLength, MEM_RELEASE);
            return lboo;
        }

        VirtualFree(iobuffer, drive->secLength, MEM_RELEASE);
        return NULL;
  }

  // Bill Buckels - not sure what to do here
  if (drive->drvtype == CPMDRV_WIN95)
  {
        DIOC_REGISTERS reg;
        BOOL bResult;
        DWORD cb;

#ifdef USE_INT13
        int cyl, head;

        if (drive->tracks < 44) { cyl = track;    head = 0; }
        else                    { cyl = track/2;  head = track & 1; }

        reg.reg_EAX      = 0x0301;  /* Write 1 sector */
        reg.reg_EBX      = (DWORD)buf;
        reg.reg_ECX      = (cyl << 8)  | (sector + PHYSICAL_SECTOR_1);
        reg.reg_EDX      = (head << 8) | (drive->fd - 1);
        reg.reg_Flags    = 1;       /* preset the carry flag */
        bResult          = DeviceIoControl( drive->hdisk, VWIN32_DIOC_DOS_INT13,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 );
#else
        DISKIO di;

        reg.reg_EAX      = drive->fd - 1;  /* zero-based volume number */
        reg.reg_EBX      = (DWORD)&di;
        reg.reg_ECX      = 0xffff;  /* use DISKIO structure */
        reg.reg_Flags    = 1;       /* preset the carry flag */
        di.diStartSector = sector+track*drive->sectrk;
        di.diSectors     = 1;
        di.diBuffer      = (DWORD)buf;
        bResult          = DeviceIoControl( drive->hdisk, VWIN32_DIOC_DOS_INT26,
              &reg, sizeof( reg ), &reg, sizeof( reg ), &cb, 0 ); 
#endif

        if ( !bResult || (reg.reg_Flags & 1) )
        {
            if (GetLastError()) return strwin32error();
            return "Unknown write error.";
        }
        return NULL;
  }

  // Bill Buckels - add drive->offset
  if (lseek(drive->fd,offset+drive->offset, SEEK_SET)==-1)
  {
    return strerror(errno);
  }
  if (write(drive->fd, buf, drive->secLength) == drive->secLength) return NULL;
  return strerror(errno);
}
/*}}}*/
