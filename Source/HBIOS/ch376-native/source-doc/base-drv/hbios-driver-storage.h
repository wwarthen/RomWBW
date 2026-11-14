#ifndef __HBIOS_DRIVER_STORAGE
#define __HBIOS_DRIVER_STORAGE

#include "usb_state.h"

typedef struct _hbios_storage_device {
  uint8_t hbios_std_cfg[16];	// HBIOS standard disk config data (see std.asm CFG_...)
								// 16 bytes filled in by _dio_add_entry (usb.asm)
  uint8_t drive_index;          // private data offset 16 (USB_CFG_DRVIDX IN usb.asm)
  uint8_t usb_device;           // private data offset 17 (USB_CFG_DEV IN usb.asm)
} hbios_storage_device_t;

extern hbios_storage_device_t hbios_usbstore_devs[MAX_NUMBER_OF_DEVICES];

uint8_t find_storage_dev(void);

#endif
