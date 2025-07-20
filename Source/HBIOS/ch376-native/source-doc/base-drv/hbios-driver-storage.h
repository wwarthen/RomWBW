#ifndef __HBIOS_DRIVER_STORAGE
#define __HBIOS_DRIVER_STORAGE

#include "usb_state.h"

typedef struct _hbios_storage_device {
  uint8_t drive_index;
  uint8_t usb_device;
} hbios_storage_device_t;

extern hbios_storage_device_t hbios_usbstore_devs[MAX_NUMBER_OF_DEVICES];

uint8_t find_storage_dev(void);

#endif
