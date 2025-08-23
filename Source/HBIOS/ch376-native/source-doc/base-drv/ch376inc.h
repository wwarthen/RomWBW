/* C Define for CH376 */
/* Website: http://wch.cn */
/* Email: tech@wch.cn */
/* Author: W.ch 2008.10 */
/* V1.0 for CH376 */

/* Oringinal file at
 * https://github.com/changleo828/BOSSEN_USB_FOR_WT/blob/master/code/CH376INC.H
 */
/* google translated */
/* other changes by Dean Netherton, 2022 */

#ifndef _CH376INC_H__
#define _CH376INC_H__

#ifdef _cplusplus
extern " C " {
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Common types and constant definitions */

#ifndef TRUE
#define TRUE  1
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

#ifndef UINT8
typedef unsigned char UINT8;
#endif
#ifndef UINT16
typedef unsigned short UINT16;
#endif
#ifndef UINT32
typedef unsigned long UINT32;
#endif
#ifndef PUINT8
typedef unsigned char *PUINT8;
#endif
#ifndef PUINT16
typedef unsigned short *PUINT16;
#endif
#ifndef PUINT32
typedef unsigned long *PUINT32;
#endif
#ifndef UINT8V
typedef unsigned char volatile UINT8V;
#endif
#ifndef PUINT8V
typedef unsigned char volatile *PUINT8V;
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Hardware features */

/* USB single data packet, the maximum length of the data block, the length of
 * the default buffer */

#define CH376_DAT_BLOCK_LEN 0x40

/* ************************************************
 * **************************************************** ***************** */
/* command code */
/* Some commands are compatible with CH375 chip, but the input data or output
 * data may be partially different) */
/* A command sequence of operations consists of:
 * A command code (for the serial port mode, two synchronization codes are
 * required before the command code), Several input data (can be 0), Generate an
 * interrupt notification or several output data (can be 0), choose one of the
 * two, if there is an interrupt notification, there must be no output data, and
 * if there is output data, no interrupt will be generated Only the
 * CMD01_WR_REQ_DATA command is an exception, the sequence includes: one command
 * code, one output data, several input data Command code naming rules:
 * CMDxy_NAME Where x and y are numbers, x indicates the minimum number of input
 * data (bytes), y indicates the minimum output data (bytes), if y is H, it
 * indicates that an interrupt notification is generated, Some commands can read
 * and write data blocks of 0 to multiple bytes, and the number of bytes of the
 * data block itself is not included in the above x or y */
/* This file will also provide a command code format compatible with the CH375
 * chip command code by default (that is, after removing x and y). If you don't
 * need it, you can defineNO_CH375_COMPATIBLE_prohibit */

/* ************************************************
 * **************************************************** ***************** */
/* Main commands (manual 1), commonly used */

/* Get the chip and firmware version
 * Output: version number (bit 7 is 0, bit 6 is 1, bit 5~bit 0 is the version
 * number) The value of the version number returned by CH376 is 041H, that is,
 * the version number is 01H */
#define CMD01_GET_IC_VER 0x01

/* Serial port mode: set the serial port communication baud rate (the default
 baud rate after power-on or reset is 9600bps, selected by D4/D5/D6 pins)
 * input: baud rate division factor, baud rate division constant
 * output: operation status (CMD_RET_SUCCESS or CMD_RET_ABORT, other values
 ​​indicate that the operation is not
 * completed) */
#define CMD21_SET_BAUDRATE 0x02

/* Enter sleep state */
#define CMD00_ENTER_SLEEP 0x03

/* perform a hardware reset */
#define CMD00_RESET_ALL 0x05

/* Test the communication interface and working status
 * input: any data
 * output: bitwise negation of the input data */
#define CMD11_CHECK_EXIST 0x06

/* Device mode: set the way to check the USB bus suspend state
 * Input: data 10H, check method
 * 00H=do not check for USB suspend, 04H=check for USB suspend at 50mS
 * intervals, 05H=check for USB suspend at 10mS intervals
 */
#define CMD20_CHK_SUSPEND 0x0B

#define CMD20_SET_SDO_INT 0x0B /* SPI interface mode: set the interrupt mode of the SDO pin of SPI */
/* input: data 16H, interrupt mode */
/* 10H=SDO pin is disabled for interrupt output, tri-state output is disabled
 * when SCS chip selection is invalid, 90H=SDO pin is also used as interrupt
 * request output when SCS chip selection is invalid */

#define CMD14_GET_FILE_SIZE 0x0C /* Host file mode: get current file length */
/* input: data 68H */
/* Output: current file length (total length 32 bits, low byte first) */

#define CMD50_SET_FILE_SIZE 0x0D /* host file mode: set current file length */
/* Input: data 68H, current file length (total length 32 bits, low byte first)
 */

/* Set USB working mode
 * input: mode code
 * 00H=Device mode not enabled
 * 01H=Device mode enabled and using external firmware mode (serial port not
 * supported) 
 * 02H=Device mode enabled and using built-in firmware mode 
 * 03H=SD card host mode/inactive host mode, used to manage and access files in SD card
 * 04H=Host mode not enabled
 * 05H=Host mode enabled
 * 06H=Host mode enabled and SOF packet generated automatically
 * 07H=Host mode enabled and USB bus reset
 * output: operation status (CMD_RET_SUCCESS or CMD_RET_ABORT, other values
 * ​​indicate that the operation is not completed) */
#define CMD11_SET_USB_MODE 0x15

#define CMD01_GET_STATUS 0x22 /* Get interrupt status and cancel interrupt request */
/* output: interrupt status */

#define CMD00_UNLOCK_USB                                                                                                           \
  0x23 /* Device mode: release the current USB buffer                                                                              \
        */

#define CMD01_RD_USB_DATA0                                                                                                         \
  0x27 /* Read data block from current USB interrupt endpoint buffer or host                                                       \
          endpoint receive buffer */
/* output: length, data stream */

#define CMD01_RD_USB_DATA                                                                                                          \
  0x28 /* Device mode: read the data block from the endpoint buffer of the                                                         \
          current USB interrupt, and release the buffer, equivalent to                                                             \
          CMD01_RD_USB_DATA0 + CMD00_UNLOCK_USB */
/* output: length, data stream */

#define CMD10_WR_USB_DATA7                                                                                                         \
  0x2B /* Device mode: write data block to the send buffer of USB endpoint 2                                                       \
        */
/* input: length, data stream */

#define CMD10_WR_HOST_DATA 0x2C /* Write a data block to the send buffer of the USB host endpoint */
/* input: length, data stream */

#define CMD01_WR_REQ_DATA 0x2D /* Write the requested data block to the internal specified buffer */
/* output: length */
/* input: data stream */

#define CMD20_WR_OFS_DATA                                                                                                          \
  0x2E /* Write a data block to the specified offset address in the internal                                                       \
          buffer */
/* input: offset, length, stream */

#define CMD10_SET_FILE_NAME 0x2F /* Host file mode: set the filename of the file to be operated on */
/* Input: 0-terminated string (no more than 14 characters including terminator
 * 0) */

/* ************************************************
 * **************************************************** ***************** */
/* Main command (Manual 1), commonly used, the following commands always
 * generate an interrupt notification at the end of the operation, and there is
 * always no output data */

#define CMD0H_DISK_CONNECT                                                                                                         \
  0x30 /* host file mode / SD card not supported: check if disk is connected                                                       \
        */
/* output interrupt */

#define CMD0H_DISK_MOUNT 0x31 /* host file mode: initialize disk and test if disk is ready */
/* output interrupt */

/* Host file mode : open files or directories(folders), or enumerate files and
 * directories(folders) output interrupt   */
#define CMD0H_FILE_OPEN 0x32

#define CMD0H_FILE_ENUM_GO                                                                                                         \
  0x33 /* Host file mode: continue enumerating files and directories (folders)                                                     \
        */
/* output interrupt */

#define CMD0H_FILE_CREATE                                                                                                          \
  0x34 /* Host file mode: create a new file, if the file already exists,                                                           \
          delete it first */
/* output interrupt */

#define CMD0H_FILE_ERASE                                                                                                           \
  0x35 /* Host file mode: delete the file, if it is already opened, delete it                                                      \
          directly, otherwise the file will be opened first and then deleted,                                                      \
          and the subdirectory must be opened first */
/* output interrupt */

#define CMD1H_FILE_CLOSE                                                                                                           \
  0x36 /* Host file mode: close the currently opened file or directory                                                             \
          (folder) */
/* input: whether to allow to update file length */
/* 00H=Disable update length, 01H=Allow update length */
/* output interrupt */

#define CMD1H_DIR_INFO_READ 0x37 /* Host file mode: read file directory information */
/* Input: Specify the index number of the directory information structure to be
 * read in the sector */
/* The range of the index number is 00H~0FH, and the index number 0FFH is the
 * currently opened file */
/* output interrupt */

#define CMD0H_DIR_INFO_SAVE                                                                                                        \
  0x38 /*Host file mode : save file directory information */ /* output                                                             \
                                                                interrupt */

#define CMD4H_BYTE_LOCATE 0x39 /* host file mode: move current file pointer in bytes */
/* Input: offset bytes (total length 32 bits, low byte first) */
/* output interrupt */

#define CMD2H_BYTE_READ 0x3A /* host file mode: read data block from current position in bytes */
/* Input: The number of bytes requested to be read (total length is 16 bits, low
 * byte first) */
/* output interrupt */

#define CMD0H_BYTE_RD_GO 0x3B /* host file mode: continue byte read */
/* output interrupt */

#define CMD2H_BYTE_WRITE 0x3C /* Host file mode: write data block to current location in bytes */
/* Input: The number of bytes requested to be written (total length is 16 bits,
 * low byte first) */
/* output interrupt */

#define CMD0H_BYTE_WR_GO 0x3D /* host file mode: continue byte write */
/* output interrupt */

#define CMD0H_DISK_CAPACITY 0x3E /* host file mode: query disk physical capacity */
/* output interrupt */

#define CMD0H_DISK_QUERY                                                                                                           \
  0x3F /* Host file mode: query disk space information                                                                             \
        */
/* output interrupt */

#define CMD0H_DIR_CREATE                                                                                                           \
  0x40 /* Host file mode: create a  new directory (folder) and open it, if the                                                     \
        * directory already exists, open it directly                                                                               \
        */
/* output interrupt */

#define CMD4H_SEC_LOCATE 0x4A /* Host file mode: move the current file pointer in sectors */
/* Input: number of offset sectors (total length 32 bits, low byte first) */
/* output interrupt */

#define CMD1H_SEC_READ                                                                                                             \
  0x4B /* host file mode / SD card not supported: read data blocks from                                                            \
          current location in sectors */
/* input: the number of sectors requested to be read */
/* output interrupt */

#define CMD1H_SEC_WRITE                                                                                                            \
  0x4C /* host file mode/SD card not supported: write data block at current                                                        \
          location in sectors */
/* input: the number of sectors requested to be written */
/* output interrupt */

#define CMD0H_DISK_BOC_CMD                                                                                                         \
  0x50 /* host mode/SD card not supported: command to execute BulkOnly                                                             \
        * transfer protocol for USB storage                                                                                        \
        */
/* output interrupt */

#define CMD5H_DISK_READ                                                                                                            \
  0x54 /* host mode/SD card not supported: read physical sectors from USB                                                          \
          storage */
/* Input: LBA physical sector address (total length 32 bits, low byte first),
 * sector number (01H~FFH) */
/* output interrupt */

#define CMD0H_DISK_RD_GO                                                                                                           \
  0x55 /* Host mode/SD card not supported: continue to perform physical sector                                                     \
          read operation of USB storage */
/* output interrupt */

#define CMD5H_DISK_WRITE                                                                                                           \
  0x56 /* Host mode/SD card not supported: write physical sector to USB                                                            \
          storage */
/* Input: LBA physical sector address (total length 32 bits, low byte first),
 * sector number (01H~FFH) */
/* output interrupt */

#define CMD0H_DISK_WR_GO                                                                                                           \
  0x57 /* Host mode/SD card not supported: continue to perform physical sector                                                     \
          write operation of USB storage */
/* output interrupt */

/* ************************************************
 * **************************************************** ***************** */
/* Auxiliary command (manual 2), not commonly used or for compatibility with
 * CH375 and CH372 */

#define CMD10_SET_USB_SPEED                                                                                                        \
  0x04 /* Set the USB bus speed, it will automatically return to 12Mbps full                                                       \
          speed every time CMD11_SET_USB_MODE sets the USB working mode */
/* input: bus speed code */
/* 00H=12Mbps full speed FullSpeed ​​(default value), 01H=1.5Mbps (modify
 * frequency only), 02H=1.5Mbps low speed LowSpeed ​​*/

#define CMD11_GET_DEV_RATE                                                                                                         \
  0x0A /* Host mode: Get the data rate type of the currently connected USB                                                         \
          device */
/* input: data 07H */
/* output: data rate type */
/* If bit 4 is 1, it is a 1.5Mbps low-speed USB device, otherwise it is a 12Mbps
 * full-speed USB device */

#define CMD11_GET_TOGGLE 0x0A /* Get the synchronization status of the OUT transaction */
/* input: data 1AH */
/* output: sync status */
/* If bit 4 is 1, the OUT transaction is synchronized, otherwise the OUT
 * transaction is not synchronized */

#define CMD11_READ_VAR8                                                                                                            \
  0x0A /* Read the specified 8-bit file system variable                                                                            \
        */
/* input: variable address */
/* output: data */

/* #define CMD11_GET_MAX_LUN = CMD11_READ_VAR8( VAR_UDISK_LUN ) */
/* Host mode: Get the maximum and current logical unit number of USB storage */

#define CMD20_SET_RETRY                                                                                                            \
  0x0B /* Host mode: set the number of retries for USB transaction operations                                                      \
        */
/* Input: data 25H, number of retries */
/* Bit 7 is 0, no retry when receiving NAK,
   bit 7 is 1, bit 6 is 0, infinite retry when receiving NAK,
   bit 7 is 1, bit 6 is 1, retry for up to 3 seconds when receiving NAK,
   bit 5~bit 0 is the number of retries after timeout */

#define CMD20_WRITE_VAR8                                                                                                           \
  0x0B /* Set the specified 8-bit file system variable                                                                             \
        */
/* input: variable address, data */

/* #define CMD20_SET_DISK_LUN = CMD20_WRITE_VAR8( VAR_UDISK_LUN ) */
/* Host mode: set the current logical unit number of the USB memory */

#define CMD14_READ_VAR32 0x0C /* Read the specified 32-bit file system variable */
/* input: variable address */
/* output: data (total length 32 bits, low byte first) */

#define CMD50_WRITE_VAR32 0x0D /* Set the specified 32-bit file system variable */
/* Input: variable address, data (total length 32 bits, low byte first) */

#define CMD01_DELAY_100US 0x0F /* Delay 100uS (serial port not supported) */
/* Output: output 0 during the delay, output non-0 after the delay */

#define CMD40_SET_USB_ID 0x12 /* Device Mode: Set USB Vendor VID and Product PID */
/* Input: Manufacturer ID low byte, Manufacturer ID high byte, Product ID low
 * byte, Product ID high byte */

#define CMD10_SET_USB_ADDR 0x13 /* Set USB address */
/* input: address value */

#define CMD01_TEST_CONNECT                                                                                                         \
  0x16 /* host mode/SD card not supported: check USB device connection status                                                      \
        */
/* output: status (USB_INT_CONNECT or USB_INT_DISCONNECT or USB_INT_USB_READY,
 * other values ​​indicate that the operation is not complete) */

#define CMD00_ABORT_NAK 0x17 /* Host mode: Abort current NAK retry */

#define CMD10_SET_ENDP2                                                                                                            \
  0x18 /* Device mode (serial port not supported): set the receiver for USB                                                        \
          endpoint 0 */
/* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000-ready ACK, 1110-busy NAK,
 * 1111-error STALL */

#define CMD10_SET_ENDP3                                                                                                            \
  0x19 /* Device mode (serial port not supported): set the transmitter of USB                                                      \
          endpoint 0 */
/* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000~1000-Ready ACK, 1110-Busy
 * NAK, 1111-Error STALL */

#define CMD10_SET_ENDP4                                                                                                            \
  0x1A /*Device mode(serial port not supported) : set the receiver of USB endpoint 1 */ /* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000-ready ACK, 1110-busy NAK,
 * 1111-error STALL */

#define CMD10_SET_ENDP5                                                                                                            \
  0x1B /* Device mode (serial port not supported): set the transmitter of USB                                                      \
          endpoint 1 */
/* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000~1000-Ready ACK, 1110-Busy
 * NAK, 1111-Error STALL */

#define CMD10_SET_ENDP6 0x1C /* Set the receiver  for USB endpoint 2/host endpoint */
/* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000-ready ACK, 1101-ready but
 * not returning ACK, 1110-busy NAK, 1111-error STALL */

#define CMD10_SET_ENDP7 0x1D /* Set the transmitter for USB endpoint 2/host endpoint */
/* input: how it works */
/* If bit 7 is 1, bit 6 is the synchronization trigger bit, otherwise the
 * synchronization trigger bit remains unchanged */
/* Bit 3~Bit 0 is the transaction response mode: 0000-ready ACK, 1101-ready but
 * no response, 1110-busy NAK, 1111-error STALL
 */

#define CMD00_DIRTY_BUFFER 0x25 /* Host file mode: clear internal disk and file buffers */

#define CMD10_WR_USB_DATA3                                                                                                         \
  0x29 /* Device mode (serial port not supported): write data block to the                                                         \
        * send buffer of USB endpoint 0                                                                                            \
        */
/* input: length, data stream */

#define CMD10_WR_USB_DATA5                                                                                                         \
  0x2A /* Device mode (serial port not supported): write data block to the                                                         \
        * send buffer of USB endpoint 1                                                                                            \
        */
/* input: length, data stream */

/* ************************************************
 * **************************************************** ***************** */
/* Auxiliary commands (manual 2), not commonly used or for compatibility with
 * CH375 and CH372, the following commands always generate an interrupt
 * notification at the end of the operation, and always have no output data */

#define CMD1H_CLR_STALL 0x41 /* host mode: control transfer - clear endpoint error */
/* input: endpoint number */
/* output interrupt */

#define CMD1H_SET_ADDRESS 0x45 /* host mode: control transfer - set usb address */
/* input: address value */
/* output interrupt */

#define CMD1H_GET_DESCR                                                                                                            \
  0x46 /* host mode: control transfer - get descriptor                                                                             \
        */
/* input: descriptor type */
/* output interrupt */

#define CMD1H_SET_CONFIG 0x49 /* host mode: control transfer - set usb configuration */
/* input: config value */
/* output interrupt */

#define CMD0H_AUTO_SETUP 0x4D /* host mode/SD card not supported: auto configure USB device */
/* output interrupt */

#define CMD2H_ISSUE_TKN_X                                                                                                          \
  0x4E /* Host mode: issue sync token, execute transaction, this command can                                                       \
          replace CMD10_SET_ENDP6/CMD10_SET_ENDP7 + CMD1H_ISSUE_TOKEN */
/* input: sync flag, transaction attributes */
/* Bit 7 of the synchronization flag is the synchronization trigger bit of the
 * host endpoint IN, bit 6 is the synchronization trigger bit of the host
 * endpoint OUT, bit 5~bit 0 must be 0 */
/* The lower 4 bits of the transaction attribute are the token, and the upper 4
 * bits are the endpoint number */
/* output interrupt */

#define CMD1H_ISSUE_TOKEN                                                                                                          \
  0x4F /* Host mode: issue token, execute transaction, it is recommended to                                                        \
        * use CMD2H_ISSUE_TKN_X command                                                                                            \
        */
/* input: transaction properties */
/* The lower 4 bits are the token, the upper 4 bits are the endpoint number */
/* output interrupt */

#define CMD0H_DISK_INIT 0x51 /* host mode/SD card not supported: initialize USB storage */
/* output interrupt */

#define CMD0H_DISK_RESET                                                                                                           \
  0x52 /* host mode/SD card not supported: control transfer - reset usb                                                            \
          storage */
/* output interrupt */

#define CMD0H_DISK_SIZE 0x53 /* Host mode/SD card not supported: Get the capacity of USB storage */
/* output interrupt */

#define CMD0H_DISK_INQUIRY                                                                                                         \
  0x58 /* host mode/SD card not supported: query USB storage characteristics                                                       \
        */
/* output interrupt */

#define CMD0H_DISK_READY 0x59 /* host mode/SD card not supported: check usb storage ready */
/* output interrupt */

#define CMD0H_DISK_R_SENSE 0x5A /* host mode  /SD card not supported: check usb storage error */
/* output interrupt */

#define CMD0H_RD_DISK_SEC                                                                                                          \
  0x5B /* Host file mode: read one sector of data from disk into internal                                                          \
          buffer */
/* output interrupt */

#define CMD0H_WR_DISK_SEC                                                                                                          \
  0x5C /* Host file mode: write data of one sector of internal buffer to disk                                                      \
        */
/* output interrupt */

#define CMD0H_DISK_MAX_LUN                                                                                                         \
  0x5D /* Host mode: control transfer - get the maximum logical unit number of                                                     \
          USB storage */
/* output interrupt */

/* ************************************************
 * **************************************************** ***************** */
/* The following definitions are only for compatibility with the command name
 * format in the INCLUDE file of CH375 */

#ifndef NO_CH375_COMPATIBLE_
#define CH_CMD_GET_IC_VER    CMD01_GET_IC_VER
#define CH_CMD_SET_BAUDRATE  CMD21_SET_BAUDRATE
#define CH_CMD_ENTER_SLEEP   CMD00_ENTER_SLEEP
#define CH_CMD_RESET_ALL     CMD00_RESET_ALL
#define CH_CMD_CHECK_EXIST   CMD11_CHECK_EXIST
#define CH_CMD_CHK_SUSPEND   CMD20_CHK_SUSPEND
#define CH_CMD_SET_SDO_INT   CMD20_SET_SDO_INT
#define CH_CMD_GET_FILE_SIZE CMD14_GET_FILE_SIZE
#define CH_CMD_SET_FILE_SIZE CMD50_SET_FILE_SIZE
#define CH_CMD_SET_USB_MODE  CMD11_SET_USB_MODE
#define CH_CMD_GET_STATUS    CMD01_GET_STATUS
#define CH_CMD_UNLOCK_USB    CMD00_UNLOCK_USB
#define CH_CMD_RD_USB_DATA0  CMD01_RD_USB_DATA0
#define CH_CMD_RD_USB_DATA   CMD01_RD_USB_DATA
#define CH_CMD_WR_USB_DATA7  CMD10_WR_USB_DATA7
#define CH_CMD_WR_HOST_DATA  CMD10_WR_HOST_DATA
#define CH_CMD_WR_REQ_DATA   CMD01_WR_REQ_DATA
#define CH_CMD_WR_OFS_DATA   CMD20_WR_OFS_DATA
#define CH_CMD_SET_FILE_NAME CMD10_SET_FILE_NAME
#define CH_CMD_DISK_CONNECT  CMD0H_DISK_CONNECT
#define CH_CMD_DISK_MOUNT    CMD0H_DISK_MOUNT
#define CH_CMD_FILE_OPEN     CMD0H_FILE_OPEN
#define CH_CMD_FILE_ENUM_GO  CMD0H_FILE_ENUM_GO
#define CH_CMD_FILE_CREATE   CMD0H_FILE_CREATE
#define CH_CMD_FILE_ERASE    CMD0H_FILE_ERASE
#define CH_CMD_FILE_CLOSE    CMD1H_FILE_CLOSE
#define CH_CMD_DIR_INFO_READ CMD1H_DIR_INFO_READ
#define CH_CMD_DIR_INFO_SAVE CMD0H_DIR_INFO_SAVE
#define CH_CMD_BYTE_LOCATE   CMD4H_BYTE_LOCATE
#define CH_CMD_BYTE_READ     CMD2H_BYTE_READ
#define CH_CMD_BYTE_RD_GO    CMD0H_BYTE_RD_GO
#define CH_CMD_BYTE_WRITE    CMD2H_BYTE_WRITE
#define CH_CMD_BYTE_WR_GO    CMD0H_BYTE_WR_GO
#define CH_CMD_DISK_CAPACITY CMD0H_DISK_CAPACITY
#define CH_CMD_DISK_QUERY    CMD0H_DISK_QUERY
#define CH_CMD_DIR_CREATE    CMD0H_DIR_CREATE
#define CH_CMD_SEC_LOCATE    CMD4H_SEC_LOCATE
#define CH_CMD_SEC_READ      CMD1H_SEC_READ
#define CH_CMD_SEC_WRITE     CMD1H_SEC_WRITE
#define CH_CMD_DISK_BOC_CMD  CMD0H_DISK_BOC_CMD
#define CH_CMD_DISK_READ     CMD5H_DISK_READ
#define CH_CMD_DISK_RD_GO    CMD0H_DISK_RD_GO
#define CH_CMD_DISK_WRITE    CMD5H_DISK_WRITE
#define CH_CMD_DISK_WR_GO    CMD0H_DISK_WR_GO
#define CH_CMD_SET_USB_SPEED CMD10_SET_USB_SPEED
#define CH_CMD_GET_DEV_RATE  CMD11_GET_DEV_RATE
#define CH_CMD_GET_TOGGLE    CMD11_GET_TOGGLE
#define CH_CMD_READ_VAR8     CMD11_READ_VAR8
#define CH_CMD_SET_RETRY     CMD20_SET_RETRY
#define CH_CMD_WRITE_VAR8    CMD20_WRITE_VAR8
#define CH_CMD_READ_VAR32    CMD14_READ_VAR32
#define CH_CMD_WRITE_VAR32   CMD50_WRITE_VAR32
#define CH_CMD_DELAY_100US   CMD01_DELAY_100US
#define CH_CMD_SET_USB_ID    CMD40_SET_USB_ID
#define CH_CMD_SET_USB_ADDR  CMD10_SET_USB_ADDR
#define CH_CMD_TEST_CONNECT  CMD01_TEST_CONNECT
#define CH_CMD_ABORT_NAK     CMD00_ABORT_NAK
#define CH_CMD_SET_ENDP2     CMD10_SET_ENDP2
#define CH_CMD_SET_ENDP3     CMD10_SET_ENDP3
#define CH_CMD_SET_ENDP4     CMD10_SET_ENDP4
#define CH_CMD_SET_ENDP5     CMD10_SET_ENDP5
#define CH_CMD_SET_ENDP6     CMD10_SET_ENDP6
#define CH_CMD_SET_ENDP7     CMD10_SET_ENDP7
#define CH_CMD_DIRTY_BUFFER  CMD00_DIRTY_BUFFER
#define CH_CMD_WR_USB_DATA3  CMD10_WR_USB_DATA3
#define CH_CMD_WR_USB_DATA5  CMD10_WR_USB_DATA5
#define CH_CMD_CLR_STALL     CMD1H_CLR_STALL
#define CH_CMD_SET_ADDRESS   CMD1H_SET_ADDRESS
#define CH_CMD_GET_DESCR     CMD1H_GET_DESCR
#define CH_CMD_SET_CONFIG    CMD1H_SET_CONFIG
#define CH_CMD_AUTO_SETUP    CMD0H_AUTO_SETUP
#define CH_CMD_ISSUE_TKN_X   CMD2H_ISSUE_TKN_X
#define CH_CMD_ISSUE_TOKEN   CMD1H_ISSUE_TOKEN
#define CH_CMD_DISK_INIT     CMD0H_DISK_INIT
#define CH_CMD_DISK_RESET    CMD0H_DISK_RESET
#define CH_CMD_DISK_SIZE     CMD0H_DISK_SIZE
#define CH_CMD_DISK_INQUIRY  CMD0H_DISK_INQUIRY
#define CH_CMD_DISK_READY    CMD0H_DISK_READY
#define CH_CMD_DISK_R_SENSE  CMD0H_DISK_R_SENSE
#define CH_CMD_RD_DISK_SEC   CMD0H_RD_DISK_SEC
#define CH_CMD_WR_DISK_SEC   CMD0H_WR_DISK_SEC
#define CH_CMD_DISK_MAX_LUN  CMD0H_DISK_MAX_LUN
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Parallel port mode, bit definition of status port (read command port) */
#ifndef PARA_STATE_INTB
#define PARA_STATE_INTB 0x80 /* Bit 7 of parallel port status port: interrupt flag, active low */
#define PARA_STATE_BUSY 0x10 /* Bit 4 of parallel port status port: busy flag, active high */
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Serial mode, boot synchronization code before the operation command */
#ifndef SER_CMD_TIMEOUT
#define SER_CMD_TIMEOUT                                                                                                            \
  32                        /* Serial command timeout time, the unit is mS, the interval between                                   \
                               synchronization codes and between synchronization codes and command                                 \
                               codes should be as short as possible, and the processing method after                               \
                               timeout is to discard */
#define SER_SYNC_CODE1 0x57 /* The first serial port synchronization code to start the operation */
#define SER_SYNC_CODE2                                                                                                             \
  0xAB /* The second serial port synchronization code to start the operation                                                       \
        */
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Operation status */

#ifndef CH_CMD_RET_SUCCESS
#define CH_CMD_RET_SUCCESS 0x51 /* Command operation succeeded */
#define CH_CMD_RET_ABORT   0x5F /* Command operation failed */
#endif

/* ************************************************
 * **************************************************** ***************** */
/* USB interrupt status */

#ifndef USB_INT_EP0_SETUP

/* The following status codes are special event interrupts, if the USB bus
 * suspend check is enabled through CMD20_CHK_SUSPEND, then the interrupt status
 * of USB bus suspend and sleep wakeup must be handled */
#define USB_INT_USB_SUSPEND 0x05 /* USB bus suspend event */
#define USB_INT_WAKE_UP     0x06 /* Wake  from sleep event */

/* The following status code 0XH is used for USB device mode */
/* Only need to process in built-in firmware mode: USB_INT_EP1_OUT,
 * USB_INT_EP1_IN, USB_INT_EP2_OUT, USB_INT_EP2_IN */
/* bit 7 - bit 4 is 0000 */
/* Bit 3-Bit 2 indicates the current transaction, 00=OUT, 10=IN, 11=SETUP */
/* Bit 1-Bit 0 indicates the current endpoint, 00=Endpoint 0, 01=Endpoint 1,
 * 10=Endpoint 2, 11=USB bus reset */
#define USB_INT_EP0_SETUP 0x0C /* SETUP for  USB endpoint 0 */
#define USB_INT_EP0_OUT   0x00 /* OUT of USB endpoint 0 */
#define USB_INT_EP0_IN    0x08 /* IN for USB endpoint 0 */
#define USB_INT_EP1_OUT   0x01 /* OUT of USB endpoint 1 */
#define USB_INT_EP1_IN    0x09 /* IN for USB endpoint 1 */
#define USB_INT_EP2_OUT   0x02 /* OUT of USB endpoint 2 */
#define USB_INT_EP2_IN    0x0A /* IN for  USB endpoint 2 */
/* USB_INT_BUS_RESET 0x0000XX11B */
/* USB bus reset */
#define USB_INT_BUS_RESET1 0x03 /* USB bus reset */
#define USB_INT_BUS_RESET2 0x07 /* USB bus reset */
#define USB_INT_BUS_RESET3 0x0B /* USB bus reset */
#define USB_INT_BUS_RESET4 0x0F /* USB bus reset */

#endif

/* The following status codes 2XH-3XH are used for communication failure codes
 * in USB host mode */
/* bit 7 - bit 6 is 00 */
/* bit 5 is 1 */
/* Bit 4 indicates whether the currently received packet is synchronized */
/* Bit 3-Bit 0 indicates the response from the USB device when communication
 * failed: 0010=ACK, 1010=NAK, 1110=STALL, 0011=DATA0, 1011=DATA1, XX00=timeout
 */
/* USB_INT_RET_ACK 0x001X0010B */
/* ERROR: return ACK for IN transaction */
/* USB_INT_RET_NAK 0x001X1010B */
/* Error: return NAK */
/* USB_INT_RET_STALL 0x001X1110B */
/* Error: return STALL */
/* USB_INT_RET_DATA0 0x001X0011B */
/* Error: DATA0 returned for OUT/SETUP transactions */
/* USB_INT_RET_DATA1 0x001X1011B */
/* ERROR: DATA1 returned for OUT/SETUP transactions */
/* USB_INT_RET_TOUT 0x001XXX00B */
/* Error: return timeout */
/* USB_INT_RET_TOGX 0x0010X011B */
/* Error: return data out of sync for IN transaction */
/* USB_INT_RET_PID 0x001XXXXXB */
/* ERROR: undefined */

/* The following status code 1XH is used for the operation status code of USB
 * host mode */
#ifndef CH_USB_INT_SUCCESS

/* USB transaction or transfer operation succeeded */
#define CH_USB_INT_SUCCESS 0x14

/* A USB device connection event is detected, it may be a new connection or
 * reconnection after disconnection */
#define CH_USB_INT_CONNECT 0x15

/* USB device disconnection event detected */
#define CH_USB_INT_DISCONNECT 0x16

/* The data transmitted by USB is wrong or the buffer overflows due to too much
 * data */
#define CH_USB_INT_BUF_OVER 0x17

/* USB device has been initialized (USB address has been assigned) */
#define CH_USB_INT_USB_READY 0x18

/* USB storage request data read */
#define CH_USB_INT_DISK_READ 0x1D

/* USB storage request data write */
#define CH_USB_INT_DISK_WRITE 0x1E

/* USB storage operation failed */
#define CH_USB_INT_DISK_ERR 0x1F
#endif

/* The following status codes are used for file system error codes in host file
 * mode */
#ifndef ERR_DISK_DISCON

/* The disk has not been connected, maybe the disk has been disconnected */
#define ERR_DISK_DISCON 0x82

/*The sector of the disk is too large, only 512 bytes per sector are supported */
#define ERR_LARGE_SECTOR 0x84

/* The disk partition type is not supported, only FAT12/FAT16/BigDOS/FAT32 is supported, it needs to be re-partitioned by the disk
 * management tool */
#define ERR_TYPE_ERROR 0x92

/* The disk has not been formatted, or the parameters are wrong and need to be reformatted by WINDOWS with  default parameters */
#define ERR_BPB_ERROR 0xA1

/* The disk file is too full, the remaining space is too little or there is no more, and disk defragmentation is required */
#define ERR_DISK_FULL 0xB1

/* There are too many files in the directory(folder), there is no free directory entry, the number of files in the FAT12 / FAT16
 * root directory should be less than 512, and disk defragmentation is required */
#define ERR_FDT_OVER 0xB2

/*The file has been closed, it should be reopened if needed */
#define ERR_FILE_CLOSE 0xB4

/* The directory (folder) of the specified path is opened */
#define ERR_OPEN_DIR 0x41

/* The file in the specified path is not found, maybe the file name is wrong */
#define ERR_MISS_FILE 0x42

/* Search for a matching file name, or ask to open a directory (folder) but the actual result opens the file */

/* The following file system error codes are used for file system subroutines */
#define ERR_FOUND_NAME 0x43

/* A subdirectory(folder) of the specified path is not found, maybe the directory name is wrong */
#define ERR_MISS_DIR 0xB3

/* long file buffer overflow */
#define ERR_LONG_BUF_OVER 0x48

/* The short file name does not have a corresponding long file name or the long file name is wrong */
#define ERR_LONG_NAME_ERR 0x49

/* A short file with the same name already exists, it is recommended to regenerate another short file name */
#define ERR_NAME_EXIST 0x4A

#endif

/* ************************************************
 * **************************************************** ***************** */
/* The following status codes are used for disk and file status in host file
 * mode, VAR_DISK_STATUS */
#ifndef DEF_DISK_UNKNOWN

/*Not initialized, unknown state */
#define DEF_DISK_UNKNOWN 0x00

/* The disk is not connected or has been disconnected */
#define DEF_DISK_DISCONN 0x01

/* The  disk is connected, but it has not been initialized or the disk cannot be recognized */
#define DEF_DISK_CONNECT 0x02

/* The disk has been initialized successfully, but the file system has not been analyzed or the file system does not support */
#define DEF_DISK_MOUNTED 0x03

/* The file system of the disk has been analyzed and can support */
#define DEF_DISK_READY 0x10

/* The  root directory has been opened and must be closed after use. Note that the FAT12/FAT16 root directory is a fixed length */
#define DEF_DISK_OPEN_ROOT 0x12

/* A subdirectory (folder) has been opened */
#define DEF_DISK_OPEN_DIR 0x13

/* The file has been opened */
#define DEF_DISK_OPEN_FILE 0x14
#endif

/* ************************************************
 * **************************************************** ***************** */
/* Common definitions of file system */

#ifndef DEF_SECTOR_SIZE
/* The default physical sector size of U disk or SD card */
#define DEF_SECTOR_SIZE 512
#endif

#ifndef DEF_WILDCARD_CHAR
#define DEF_WILDCARD_CHAR 0x2A /* Wildcard '*' for pathname */
#define DEF_SEPAR_CHAR1   0x5C /* The path name separator '\' */
#define DEF_SEPAR_CHAR2   0x2F /* The delimiter  of the path name '/' */
#define DEF_FILE_YEAR     2004 /* Default file date: 2004 */
#define DEF_FILE_MONTH    1    /* Default file date: January */
#define DEF_FILE_DATE     1    /* Default file date: 1st */
#endif

#ifndef ATTR_DIRECTORY

/* File directory information in FAT data area */
typedef struct FAT_DIR_INFO {
  UINT8 DIR_Name[11];            /* 00H, file name, a total of 11 bytes, fill in blanks */
  UINT8 DIR_Attr;                /* 0BH, file attribute, refer to the following description */
  UINT8 DIR_NTRes;               /* 0CH */
  UINT8 DIR_CrtTimeTenth;        /* 0DH, the time of file creation, counted in 0.1
                                    second units */
  UINT16 DIR_CrtTime;            /* 0EH, file creation time */
  UINT16 DIR_CrtDate;            /* 10H, the date the file was created */
  UINT16 DIR_LstAccDate;         /* 12H, the date of the last access operation */
  UINT16 DIR_FstClusHI;          /* 14H */
  UINT16 DIR_WrtTime;            /* 16H, file modification time, refer to the previous
                                    macro MAKE_FILE_TIME */
  UINT16 DIR_WrtDate;            /* 18H, file modification date, refer to the previous
                                    macro MAKE_FILE_DATE */
  UINT16 DIR_FstClusLO;          /* 1AH */
  UINT32 DIR_FileSize;           /* 1CH, file length */
} FAT_DIR_INFO, *P_FAT_DIR_INFO; /* 20H */

/* file attributes */
#define ATTR_READ_ONLY      0x01                                                          /* The file is read-only */
#define ATTR_HIDDEN         0x02                                                          /* file is a hidden attribute */
#define ATTR_SYSTEM         0x04                                                          /* The file is a system attribute */
#define ATTR_VOLUME_ID      0x08                                                          /* Volume label */
#define ATTR_DIRECTORY      0x10                                                          /* subdirectories (folders) */
#define ATTR_ARCHIVE        0x20                                                          /* file is archive attribute */
#define ATTR_LONG_NAME      (ATTR_READ_ONLY | ATTR_HIDDEN | ATTR_SYSTEM | ATTR_VOLUME_ID) /* long filename attribute */
#define ATTR_LONG_NAME_MASK (ATTR_LONG_NAME | ATTR_DIRECTORY | ATTR_ARCHIVE)
/* file attribute UINT8 */
/* bit0 bit1 bit2 bit3 bit4 bit5 bit6 bit7 */
/* Only hidden volume is undefined */
/* Read the Tibetan standard record file */
/* file time UINT16 */
/* Time = (Hour<<11) + (Minute<<5) + (Second>>1) */
#define MAKE_FILE_TIME                                                                                                             \
  (h, m, s)((h << 11) + (m << 5) + (s >> 1)) /* Generate file time data of specified                                               \
                                                hours, minutes and seconds */
/* file date UINT16 */
/* Date = ((Year-1980)<<9) + (Month<<5) + Day */
#define MAKE_FILE_DATE                                                                                                             \
  (y, m, d)(((y - 1980) << 9) + (m << 5) + d) /* Generate the file date data of the                                                \
                                                 specified year, month and day */

#define LONE_NAME_MAX_CHAR (255 * 2) /* The maximum number of characters/bytes of the long file name */
#define LONG_NAME_PER_DIR                                                                                                          \
  (13 * 2) /* The number of characters/bytes of the long file name in the                                                          \
              directory information structure of each file */

#endif

/* ************************************************
 * **************************************************** ***************** */
/* SCSI command and data input and output structures */

#ifndef SPC_CMD_INQUIRY

/* SCSI command code */
#define SPC_CMD_INQUIRY       0x12
#define SPC_CMD_READ_CAPACITY 0x25
#define SPC_CMD_READ10        0x28
#define SPC_CMD_WRITE10       0x2A
#define SPC_CMD_TEST_READY    0x00
#define SPC_CMD_REQUEST_SENSE 0x03
#define SPC_CMD_MODESENSE6    0x1A
#define SPC_CMD_MODESENSE10   0x5A
#define SPC_CMD_START_STOP    0x1B

/* BulkOnly protocol command block */
typedef struct BULK_ONLY_CBW {
  UINT32 CBW_Sig;
  UINT32 CBW_Tag;
  UINT8  CBW_DataLen0; /* 08H, input: data transmission length, the valid value
                          for input data is 0 to 48, and the valid value for
                          output data is 0 to 33 */
  UINT8  CBW_DataLen1;
  UINT16 CBW_DataLen2;
  UINT8  CBW_Flag; /* 0CH, input: transmission direction and other flags, if bit
                      7 is 1, input data, if bit 0, output data or no data */
  UINT8 CBW_LUN;
  UINT8 CBW_CB_Len;                /* 0EH, input: the length of the command block, valid values
                                      ​​are 1 to 16 */
  UINT8 CBW_CB_Buf[16];            /* 0FH, input: command block, the buffer is up to 16
                                      bytes */
} BULK_ONLY_CBW, *P_BULK_ONLY_CBW; /* BulkOnly protocol command block, input CBW structure */

/* INQUIRY command return data */
typedef struct INQUIRY_DATA {
  UINT8 DeviceType;       /* 00H, device type */
  UINT8 RemovableMedia;   /* 01H, if bit 7 is 1, it means removable storage */
  UINT8 Versions;         /* 02H, protocol version */
  UINT8 DataFormatAndEtc; /* 03H, specify the return data format */
  UINT8 AdditionalLength; /* 04H, the length of subsequent data */
  UINT8 Reserved1;
  UINT8 Reserved2;
  UINT8 MiscFlag;                /* 07H, some control flags */
  UINT8 VendorIdStr[8];          /* 08H, Vendor information */
  UINT8 ProductIdStr[16];        /* 10H, product information */
  UINT8 ProductRevStr[4];        /* 20H, product version */
} INQUIRY_DATA, *P_INQUIRY_DATA; /* 24H */

/* REQUEST SENSE command return data */
typedef struct SENSE_DATA {
  UINT8 ErrorCode; /* 00H, error code and valid bits */
  UINT8 SegmentNumber;
  UINT8 SenseKeyAndEtc; /* 02H, primary key code */
  UINT8 Information0;
  UINT8 Information1;
  UINT8 Information2;
  UINT8 Information3;
  UINT8 AdditSenseLen; /* 07H, the length of subsequent data */
  UINT8 CmdSpecInfo[4];
  UINT8 AdditSenseCode; /* 0CH, additional key code */
  UINT8 AddSenCodeQual; /* 0DH, detailed additional key code */
  UINT8 FieldReplaUnit;
  UINT8 SenseKeySpec[3];
} SENSE_DATA, *P_SENSE_DATA; /* 12H */

#endif

/* ************************************************
 * **************************************************** ***************** */
/* Data input and output structures in host file mode */

#ifndef MAX_FILE_NAME_LEN

#define MAX_FILE_NAME_LEN                                                                                                          \
  (13 + 1) /* The maximum length of the file name, the maximum length is 1                                                         \
              root directory character + 8 main file names + 1 decimal point +                                                     \
              3 type names + terminator = 14 */

/* Command input data and output data */
typedef union CH376_CMD_DATA {
  struct {
    UINT8 mBuffer[MAX_FILE_NAME_LEN];
  } Default;

  INQUIRY_DATA DiskMountInq; /* Return: return data of INQUIRY command */
  /* CMD0H_DISK_MOUNT: Initialize the disk and test if the disk is ready, when
   * executed for the first time */

  FAT_DIR_INFO OpenDirInfo; /* Return: Enumerated file directory information */
  /* CMD0H_FILE_OPEN: Enumerate files and directories (folders) */

  FAT_DIR_INFO EnumDirInfo; /* Return: Enumerated file directory information */
  /* CMD0H_FILE_ENUM_GO: Continue to enumerate files and directories (folders)
   */

  struct {
    UINT8 mUpdateFileSz; /* Input parameter: whether to allow the file length to
                            be updated, or 0 to prohibit the update of the
                            length */
  } FileCLose;           /* CMD1H_FILE_CLOSE: close the currently opened file */

  struct {
    UINT8 mDirInfoIndex; /* Input parameters: specify the index number of the
                            directory information structure to be read in the
                            sector, 0FFH is the currently opened file */
  } DirInfoRead;         /* CMD1H_DIR_INFO_READ: read the directory information of the
                            file */

  union {
    UINT32 mByteOffset; /* Input parameter: number of offset bytes, offset in
                           bytes (total length 32 bits, low byte first) */
    UINT32
    mSectorLba; /* Return: the absolute linear sector number corresponding
                   to the current file pointer, 0FFFFFFFFH has reached the
                   end of the file (total length 32 bits, low byte first) */
  } ByteLocate; /* CMD4H_BYTE_LOCATE: move the current file pointer in bytes */

  struct {
    UINT16
    mByteCount; /* Input parameter: the number of bytes requested to be read
                   (total length is 16 bits, low byte first) */
  } ByteRead;   /* CMD2H_BYTE_READ: read data block from current position in bytes
                 */

  struct {
    UINT16 mByteCount; /* Input parameter: the number of bytes requested to be
                          written (total length is 16 bits, low byte first) */
  } ByteWrite;         /* CMD2H_BYTE_WRITE: Write a block of data to the current
                          location in bytes */

  union {
    UINT32 mSectorOffset; /* Input parameter: number of offset sectors, offset
                             in sector (total length 32 bits, low byte first) */
    UINT32
    mSectorLba;   /* Return: the absolute linear sector number corresponding
                     to the current file pointer, 0FFFFFFFFH has reached the
                     end of the file (total length 32 bits, low byte first) */
  } SectorLocate; /* CMD4H_SEC_LOCATE: move the current file pointer in sectors
                   */

  struct {
    UINT8 mSectorCount; /* Input parameters: the number of sectors requested to
                           be read */
                        /* return: the number of sectors allowed to be read */
    UINT8  mReserved1;
    UINT8  mReserved2;
    UINT8  mReserved3;
    UINT32 mStartSector; /* Return: The starting absolute linear sector number
                            of the sector block allowed to be read (total length
                            32 bits, low byte first) */
  } SectorRead;          /* CMD1H_SEC_READ: Read the data block from the current position
                            in sectors */

  struct {
    UINT8 mSectorCount; /* Input parameters: the number of sectors requested to
                           be written */
    /* return: the number of sectors allowed to be written */
    UINT8  mReserved1;
    UINT8  mReserved2;
    UINT8  mReserved3;
    UINT32 mStartSector; /* Return: the starting absolute linear sector number
                            of the sector block allowed to be written (total
                            length 32 bits, low byte first) */
  } SectorWrite;         /* CMD1H_SEC_WRITE: Write a data block at the current location
                            in sectors */

  struct {
    UINT32
    mDiskSizeSec; /* Return: the total number of sectors of the entire
                     physical disk (total length 32 bits, low byte first) */
  } DiskCapacity; /* CMD0H_DISK_CAPACITY: Query the physical capacity of the
                     disk */

  struct {
    UINT32 mTotalSector; /* Return: the total number of sectors of the current
                            logical disk (total length is 32 bits, low byte
                            first) */
    UINT32 mFreeSector;  /* Return: the number of remaining sectors of the
                            current logical disk (total length is 32 bits, low
                            byte first) */
    UINT8 mDiskFat;      /* Return: FAT type of the current logical disk, 1-FAT12,
                            2-FAT16, 3-FAT32 */
  } DiskQuery;           /* CMD_DiskQuery, query disk information */

  BULK_ONLY_CBW DiskBocCbw; /* Input parameters: CBW command structure */
  /* CMD0H_DISK_BOC_CMD: command to execute BulkOnly transfer protocol to USB
   * memory */

  struct {
    UINT8 mMaxLogicUnit; /* return: the maximum logic unit number of the USB
                            memory */
  } DiskMaxLun;          /* CMD0H_DISK_MAX_LUN: Control transfer - get the maximum
                            logical unit number of USB memory */

  INQUIRY_DATA DiskInitInq; /* Return: return data of INQUIRY command */
                            /* CMD0H_DISK_INIT: Initialize USB storage */

  INQUIRY_DATA DiskInqData; /* Return: return data of INQUIRY command */
  /* CMD0H_DISK_INQUIRY: Query USB storage characteristics */

  SENSE_DATA ReqSenseData; /* Return: REQUEST SENSE command return data */
  /* CMD0H_DISK_R_SENSE: Check for USB storage errors */

  struct {
    UINT32 mDiskSizeSec; /* Return: the total number of sectors of the entire
                            physical disk (total length is 32 bits, high byte
                            first) */
  } DiskSize;            /* CMD0H_DISK_SIZE: Get the capacity of the USB memory */

  struct {
    UINT32 mStartSector; /* Input parameters: LBA sector address (total length
                            32 bits, low byte first) */
    UINT8 mSectorCount;  /* Input parameters: the number of sectors requested to
                            be read */
  } DiskRead;            /* CMD5H_DISK_READ: Read data blocks from USB memory (in sectors)
                          */

  struct {
    UINT32 mStartSector; /* Input parameters: LBA sector address (total length
                            32 bits, low byte first) */
    UINT8 mSectorCount;  /* Input parameters: the number of sectors requested to
                            be written */
  } DiskWrite;           /* CMD5H_DISK_WRITE: Write data block to USB memory (in sectors)
                          */
} CH376_CMD_DATA, *P_CH376_CMD_DATA;

#endif

/* ************************************************
 * **************************************************** ***************** */
/* Address of filesystem variable in host file mode */

#ifndef VAR_FILE_SIZE

/* 8-bit/single-byte variable */

/* Basic information of the current system
 * Bit 6 is used to indicate the subclass SubClass-Code of the USB storage
 * device. If bit 6 is 0, it means that the subclass is 6, and if bit 6 is 1, it
 * means that the subclass is other than 6 Bit 5 is used to indicate the USB
 * configuration status in USB device mode and the USB device connection status
 * in USB host mode In USB device mode, if bit 5 is 1, the USB configuration is
 * complete, and if bit 5 is 0, it has not yet been configured In USB host mode,
 * if bit 5 is 1, there is a USB device on the USB port, and if bit 5 is 0,
 * there is no USB device on the USB port Bit 4 is used to indicate the buffer
 * lock state in USB device mode. If bit 4 is 1, it means that the USB buffer is
 * in a locked state. If bit 6 is 1, it means it has been released Other bits,
 * reserved, do not modify */
#define CH_VAR_SYS_BASE_INFO 0x20

/* The number of retries for the USB transaction operation
 * If bit 7 is 0, it will not retry when receiving NAK, if bit 7 is 1, if bit 6
 * is 0, it will retry infinitely when receiving NAK (you can use CMD_ABORT_NAK
 * command to give up retry), if bit 7 is 1, bit 6 is 1 Retry for up to 3
 * seconds when NAK is received Bit 5~Bit 0 is the number of retries after
 * timeout */
#define CH_VAR_RETRY_TIMES 0x25

/* Bit flag in host file mode
 * Bit 1 and bit 0, FAT file system flag of the logical disk, 00-FAT12,
 * 01-FAT16, 10-FAT32, 11-Illegal Bit 2, whether the FAT table data in the
 * current buffer has been modified, 0-unmodified, 1-modified Bit 3, the file
 * length needs to be modified flag, the current file is appended with data,
 * 0-no modification is required if it is not appended, 1-modification is
 * required if it has been appended Other bits, reserved, do not modify */
#define CH_VAR_FILE_BIT_FLAG 0x26

/* Disk and file status in host file mode */
#define CH_VAR_DISK_STATUS 0x2B

/* Bit flag of SD card in host file mode
 * Bit 0, SD card version, 0-only supports SD first version, 1-supports SD
 * second version bit 1, auto-identification, 0-SD card, 1-MMC card Bit 2,
 * automatic identification, 0-standard capacity SD card, 1-high capacity SD
 * card (HC-SD) bit 4, ACMD41 command timeout bit 5, CMD1 command timeout bit 6,
 * CMD58 command timeout Other bits, reserved, do not modify */
#define CH_VAR_SD_BIT_FLAG 0x30

/* Sync flag for BULK-IN/BULK-OUT endpoint of USB storage device
 * bit 7, sync flag for Bulk-In endpoint
 * bit 6, sync flag for Bulk-In endpoint
 * Bit 5~Bit 0, must be 0 */
#define CH_VAR_UDISK_TOGGLE 0x31

/* The logical unit number of the USB storage device
 * Bit 7~Bit 4, the current logical unit number of the USB storage device, after
 * CH376 initializes the USB storage device, the default is to access the 0#
 * logical unit Bit 3~Bit 0, the maximum logical unit number of the USB storage
 * device, plus 1 equals the number of logical units */
#define CH_VAR_UDISK_LUN 0x34

/* Number of sectors per cluster of logical disk */
#define CH_VAR_SEC_PER_CLUS 0x38

/* The index number of the current file directory information in the sector */
#define CH_VAR_FILE_DIR_INDEX 0x3B

/* The sector offset of the current file pointer in the cluster, if it is 0xFF,
 * it points to the end of the file and the end of the cluster */
#define CH_VAR_CLUS_SEC_OFS 0x3C

/* 32-bit/4-byte variable
 * For FAT16 disk, it is the number of sectors occupied by the root directory,
 * and for FAT32 disk, it is the starting cluster number of the root directory
 * (total length 32 bits, low byte first) */
#define CH_VAR_DISK_ROOT 0x44

/* The total number of clusters of the logical disk(total length is 32 bits, low
 * byte first) */
#define CH_VAR_DSK_TOTAL_CLUS 0x48

/* The starting absolute sector number LBA of the logical disk(total length is
 * 32 bits, low byte first) */
#define CH_VAR_DSK_START_LBA 0x4C

/* The starting LBA of the data area of ​​the logical disk (total length is
 * 32 bits, low byte first) */
#define CH_VAR_DSK_DAT_START 0x50

/* The LBA corresponding to the data in the current disk data buffer (total
 * length is 32 bits, low byte first) */
#define CH_VAR_LBA_BUFFER 0x54

/* The current read and write disk start LBA address (total length 32 bits, low
 * byte first) */
#define CH_VAR_LBA_CURRENT 0x58

/* LBA address of the sector where the current file directory information is
 * located (total length 32 bits, low byte first)
 */
#define CH_VAR_FAT_DIR_LBA 0x5C

/* The starting cluster number of the current file or directory (folder) (total
 * length 32 bits, low byte first) */
#define CH_VAR_START_CLUSTER 0x60

/* The current cluster number of the current file (total length is 32 bits, low
 * byte first) */
#define CH_VAR_CURRENT_CLUST 0x64

/* The length of the current file (total length is 32 bits, low byte first) */
#define CH_VAR_FILE_SIZE 0x68

/* The current file pointer, the byte offset of the current read and write
 * position(total length 32 bits, low byte first) */
#define CH_VAR_CURRENT_OFFSET 0x6C

#endif

/* ******************************************************************************************************************/
/* Common USB definitions */

/* USB packet identification PID, the host mode may be used */
#ifndef DEF_USB_PID_SETUP
#define DEF_USB_PID_NULL  0x00 /* PID reserved, undefined */
#define DEF_USB_PID_SOF   0x05
#define DEF_USB_PID_SETUP 0x0D
#define DEF_USB_PID_IN    0x09
#define DEF_USB_PID_OUT   0x01
#define DEF_USB_PID_ACK   0x02
#define DEF_USB_PID_NAK   0x0A
#define DEF_USB_PID_STALL 0x0E
#define DEF_USB_PID_DATA0 0x03
#define DEF_USB_PID_DATA1 0x0B
#define DEF_USB_PID_PRE   0x0C
#endif

/* USB request type, may be used in external firmware mode */
#ifndef DEF_USB_REQ_TYPE
#define DEF_USB_REQ_READ    0x80 /* Control read operation */
#define DEF_USB_REQ_WRITE   0x00 /* Control write operation */
#define DEF_USB_REQ_TYPE    0x60 /* Control request type */
#define DEF_USB_REQ_STAND   0x00 /* Standard Request */
#define DEF_USB_REQ_CLASS   0x20 /* Device class request */
#define DEF_USB_REQ_VENDOR  0x40 /* Vendor  Request */
#define DEF_USB_REQ_RESERVE 0x60 /* Reservation  Request */
#endif

/* USB standard device request, Bit 6 of RequestType 5=00 (Standard), external
 * firmware mode may be used */
#ifndef DEF_USB_GET_DESCR
#define DEF_USB_CLR_FEATURE 0x01
#define DEF_USB_SET_FEATURE 0x03
#define DEF_USB_GET_STATUS  0x00
#define DEF_USB_SET_ADDRESS 0x05
#define DEF_USB_GET_DESCR   0x06
#define DEF_USB_SET_DESCR   0x07
#define DEF_USB_GET_CONFIG  0x08
#define DEF_USB_SET_CONFIG  0x09
#define DEF_USB_GET_INTERF  0x0A
#define DEF_USB_SET_INTERF  0x0B
#define DEF_USB_SYNC_FRAME  0x0C
#endif

// desscriptor types for CMD1H_GET_DESCR
#ifndef CH375_USB_DEVICE_DESCRIPTOR
#define CH375_USB_DEVICE_DESCRIPTOR        0x01
#define CH375_USB_CONFIGURATION_DESCRIPTOR 0x02
#define CH375_USB_INTERFACE_DESCRIPTOR     0x04
#define CH375_USB_ENDPOINT_DESCRIPTOR      0x05
#endif

/* ************************************************
 * **************************************************** ***************** */

#ifdef _cplusplus
}
#endif

#endif
