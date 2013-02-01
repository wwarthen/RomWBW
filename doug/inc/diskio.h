/*
 * diskio.h
 *
 */

__sfr __at (DISKIO_IDE + 0x00) pIDELO;
__sfr __at (DISKIO_IDE + 0x01) pIDEERR;
__sfr __at (DISKIO_IDE + 0x02) pIDESECTC;
__sfr __at (DISKIO_IDE + 0x03) pIDESECTN;
__sfr __at (DISKIO_IDE + 0x04) pIDECYLLO;
__sfr __at (DISKIO_IDE + 0x05) pIDECYLHI;
__sfr __at (DISKIO_IDE + 0x06) pIDEHEAD;
__sfr __at (DISKIO_IDE + 0x07) pIDESTTS;
__sfr __at (DISKIO_IDE + 0x08) pIDEHI;
__sfr __at (DISKIO_IDE + 0x0E) pIDECTRL;

__sfr __at (DISKIO_FLP + 0x06) pFMSR;
__sfr __at (DISKIO_FLP + 0x07) pFDATA;
__sfr __at (DISKIO_FLP + 0x0A) pFLATCH;
__sfr __at (DISKIO_FLP + 0x0C) pFDMA;

/*
 *
 * eof - diskio.h
 *
 */


